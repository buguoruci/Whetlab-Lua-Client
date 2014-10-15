local Setting = {}; Setting.__index = Setting

local function construct(objname, client)
  local self = setmetatable({client=client}, Setting)
  return self
end
setmetatable(Setting, {__call = construct})

-- Set a setting corresponding to an experiment
-- '/alpha/settings/' POST
--
-- name - The name of the variable.
-- type - The type of variable. One of int,float,etc.
-- min - Minimum value for the variable
-- max - Maximum value for the variable
-- size - Vector size for the variable
-- units - What units is the variable in?
-- experiment - The experiment associated with this variable
-- scale - The scale of the units associated with this variable
-- isOutput - Is this variable an output of the experiment
function Setting:set(name, type, min, max, size, units, experiment, scale, isOutput, options)
    body = {}
    if options ~= nil then
        if options['query'] ~= nil then
            body = options['query']        
        end
    else
        options = {}
    end
    
    body['name'] = name
    body['type'] = type
    body['min'] = min
    body['max'] = max
    body['size'] = size
    body['units'] = units
    body['experiment'] = experiment
    body['scale'] = scale
    body['isOutput'] = isOutput

    response = self.client:post('/alpha/settings/', body, options)
    return response
end

return Setting