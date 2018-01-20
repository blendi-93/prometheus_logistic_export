prometheus = require("tarantool/prometheus")
gauge_content = prometheus.gauge("content", "content of logistic network", {"network", "item"})
gauge_bots = prometheus.gauge("bots", "bot count type and status", {"network", "type", "avaible"})

global.prometheus_logistic = global.prometheus_logistic or {}
global.prometheus_logistic.networks = global.prometheus_logistic.networks or {}
global.prometheus_logistic.content = global.prometheus_logistic.content or {}
global.prometheus_logistic.bots = global.prometheus_logistic.bots or {}

function update_networks(forces)
  local networks = {}
  for _,force in pairs(forces) do
    local n =  force.logistic_networks
    for surface,nets in pairs(n) do
      networks[surface] = {}
      for net_id,net in pairs(nets) do
        networks[surface][net_id] = net
      end
    end
  end
  global.prometheus_logistic.networks = networks
end

function update_bots() 
  local bots = global.prometheus_logistic.bots or {}
  -- reset bot counts, so prometheus show 0 after bots got removed from log network
   for net_id, v in pairs(bots) do
     for bot_type, bot in pairs(v) do
       for avaible, count in pairs(bot) do
         bots[net_id][bot_type][avaible] = 0;
       end
     end
   end
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
	   for net_id, v in pairs(content) do
             for item, count in pairs(v) do
	       gauge_content:set(count, {net_id, item})
	     end
	   end
	   game.write_file("prometheus.prom", prometheus.collect())
end

script.on_event(defines.events.on_tick, function(event)
        if event.tick % 60 == 0  then
	  update_networks()
	  update_contents()
	  export_metrics()
	end

end)
