local Experiment = {}; Experiment.__index = Experiment

local function construct(objname, id, client)
  local self = setmetatable({ id=id, client=client}, Experiment)
  self.id = id
  self.client = client
  return self
end
setmetatable(Experiment, {__call = construct})

-- Return the experiment corresponding to id.
-- '/alpha/experiments/:id/' GET
--
function Experiment:get(options)
        body = {}
        if options ~= nil then
            if options['query'] ~= nil then
                body = options['query']        
            end
        else
            options = {}
        end

        response = self.client:get('/alpha/experiments/' .. self.id .. '/', body, options)
        return response
end

-- Delete the experiment corresponding to id.
-- '/alpha/experiments/:id/' DELETE
--
function Experiment:delete(options)
        body = {}
        if options ~= nil then
            if options['query'] ~= nil then
                body = options['query']        
            end
        else
            options = {}
        end        

        response = self.client:delete('/alpha/experiments/' .. self.id .. '/', body, options)
        return response
end

return Experiment
