local Experiments = {}; Experiments.__index = Experiments

local function construct(objname, client)
  local self = setmetatable({client=client}, Experiments)
  self.client = client
  return self
end
setmetatable(Experiments, {__call = construct})

-- Return the experiments set corresponding to user
-- '/alpha/experiments/' GET
--
function Experiments:get(options)
        body = {}
        if options ~= nil then
            if options['query'] ~= nil then
                body = options['query']        
            end
        else
            options = {}
        end

        response = self.client:get('/alpha/experiments/', body, options)
        return response
end

-- Create a new experiment and get the corresponding id
-- '/alpha/experiments/' POST
--
-- name - The name of the experiment to be created.
-- description - A detailed description of the experiment
-- user - The user id of this user
function Experiments:create(name, description, settings, options)
        body = {}
        if options ~= nil then
            if options['query'] ~= nil then
                body = options['query']        
            end
        else
            options = {}
        end

        body['name'] = name
        body['description'] = description
        body['settings'] = settings

        response = self.client:post('/alpha/experiments/', body, options)
        return response
end

return Experiments