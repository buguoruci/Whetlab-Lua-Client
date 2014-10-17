local Settings = {}; Settings.__index = Settings

local function construct(objname, client)
  local self = setmetatable({client=client}, Settings)
  return self
end
setmetatable(Settings, {__call = construct})

-- Return the settings corresponding to the experiment.
-- '/alpha/settings/' GET
--
-- experiment - Experiment id to filter by.
function Settings:get(experiment, options)
    body = {}
    if options ~= nil then
        if options['query'] ~= nil then
            body = options['query']        
        end
    else
        options = {}
    end
    
    body['experiment'] = experiment

    response = self.client:get('/alpha/settings/', body, options);
    return response
end
return Settings