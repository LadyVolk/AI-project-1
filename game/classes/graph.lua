local Class = require "extra_libs.hump.class"

local Node = Class{
  init = function(self, id)
    self.id = id
    self.connections = {}
  end,

  add_connection = function(self, node, condition)
    table.insert(self.connections, {node = node, condition = condition})
  end,

  get_connections = function(self)
    return self.connections
  end,

  get_valid_connections = function(self, arguments)
    local valid_connections = {}
    for i, connection in ipairs(self.connections) do
       if connection.condition(arguments) then
         table.insert(valid_connections, connection)
       end
    end
    return valid_connections
  end,

  get_best_fuzzy_connection = function(self, arguments)
    local best_connection
    local best_condition_value
    for i, connection in ipairs(self.connections) do
      local condition_value = connection.condition(arguments)
       if condition_value > 0 then
         if not best_connection then
           best_connection = connection
           best_condition_value = condition_value
         else
           if condition_value >= best_condition_value then
             best_condition_value = condition_value
             best_connection = connection
           end
         end
       end
    end
    return best_connection
  end,

}

local Graph = Class{

  init = function(self)
    self.nodes = {}
  end,

  add_node = function(self, id)
    local node = Node(id)
    table.insert(self.nodes, node)
    return node
  end,

  get_node = function(self, id)
    for i, node in ipairs(self.nodes) do
      if node.id == id then
        return node
      end
    end
    print("node not found: "..tostring(ids))
  end,

  add_connection = function(self, origin, final, condition)
    local origin_node = self:get_node(origin)
    local final_node = self:get_node(final)
    origin_node:add_connection(final_node, condition)
  end
}

return Graph
