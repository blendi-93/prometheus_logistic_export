prometheus = require("tarantool/prometheus")
gauge_content = prometheus.gauge("content", "content of logistic network", {"network", "item"})
gauge_bots_available = prometheus.gauge("bots_available", "bot available ccount", {"network", "bot"})
gauge_bots_total = prometheus.gauge("bots_total", "bot total count", {"network", "bot"})

global.prometheus_logistic = global.prometheus_logistic or {}
global.prometheus_logistic.networks = global.prometheus_logistic.networks or {}
global.prometheus_logistic.content = global.prometheus_logistic.content or {}
global.prometheus_logistic.bots = global.prometheus_logistic.bots or {}

function update_bots() 
  local bots = global.prometheus_logistic.bots or {}
  -- reset bot counts, so prometheus show 0 after bots got removed from log network
   for net_id, _ in pairs(bots) do
     bots[net_id] = {}
     bots[net_id] = {
       available = {
         construction = 0, logistic = 0
       },
       total = {
         construction = 0, logistic = 0
       }
    }
  end
  for _,force in pairs(game.forces) do
    local networks =  force.logistic_networks
    for surface,nets in pairs(networks) do
      for net_id,net in pairs(nets) do
        print(net_id)
        bots[net_id] = {
	  available = {
	    construction = net.available_construction_robots,
	    logistic = net.available_logistic_robots
	  },
	  total = {
	    construction = net.all_construction_robots,
	    logistic = net.all_logistic_robots
	  }
	}
      end
    end
  end
  global.prometheus_logistic.bots = bots
end

function update_contents() 
  local content = global.prometheus_logistic.content or {}
  -- reset item counts, so prometheus show 0 after items got removed from log network
  for net_id, v in pairs(content) do
    for item, _ in pairs(v) do
      content[net_id][item] = 0;
    end
  end
  -- now update exsisting networks or add new
  for _,force in pairs(game.forces) do
    local networks =  force.logistic_networks
    for surface,nets in pairs(networks) do
      for net_id,net in pairs(nets) do
        for item, count in pairs(net.get_contents()) do
          content[net_id] = content[net_id] or {}
          content[net_id][item] = count
        end
      end
    end
  end
  global.prometheus_logistic.content = content
end

function export_metrics()
	   local content = global.prometheus_logistic.content or {}
	   local bots = global.prometheus_logistic.bots or {}
	   for net_id, v in pairs(content) do
             for item, count in pairs(v) do
	       gauge_content:set(count, {net_id, item})
	     end
	   end
           --gauge_bots_available = prometheus.gauge("bots_available", "bot available ccount", {"network", "bot"})
	   --bots[net_id][avaible/total][type]
	   for net_id, bot in pairs(bots) do
	      for bot_type, count in pairs(bot["available"]) do
                gauge_bots_available:set(count,{net_id, bot_type})
	      end
	      for bot_type, count in pairs(bot["total"]) do
                gauge_bots_total:set(count,{net_id, bot_type})
	      end
	   end
	   game.write_file("prometheus_logistic_export/prometheus.prom", prometheus.collect())
end

script.on_event(defines.events.on_tick, function(event)
        if event.tick % 60 == 0  then
	  update_contents()
	  update_bots()
	  export_metrics()
	end

end)
