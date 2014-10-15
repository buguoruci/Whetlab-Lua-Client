local Suggest = {}; Suggest.__index = Suggest

local function construct(objname, exptid, client)
  local self = setmetatable({exptid=exptid, client=client}, Suggest)
  return self
end
setmetatable(Suggest, {__call = construct})

-- Ask the server to propose a new set of parameters to run the next experiment
-- '/alpha/tasks/:taskid/suggest/' POST
function Suggest:go(options)
    body = {}
    if options ~= nil then
        if options['query'] ~= nil then
            body = options['query']        
        end
    else
        options = {}
    end

    response = self.client:post('/alpha/experiments/' .. self.exptid .. '/suggest/', body, options)
    return response
end

return Suggest
