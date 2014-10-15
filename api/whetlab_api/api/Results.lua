local Results = {}; Results.__index = Results

local function construct(objname, client)
  local self = setmetatable({client=client}, Results)
  self.client = client
  return self
end
setmetatable(Results, {__call = construct})

-- Return a result set corresponding to an experiment
-- '/alpha/results' GET
--
function Results:get(options)
    body = {}
    if options ~= nil then
        if options['query'] ~= nil then
            body = options['query']        
        end
    else
        options = {}
    end

    response = self.client:get('/alpha/results', body, options)
    return response
end

-- Add a user created result
-- '/alpha/results/' POST
--
-- variables - The result list of dictionary objects with updated fields.
-- task - Task id
-- userProposed - userProposed
-- description - description
-- runDate - <no value>
function Results:add(variables, experiment, userProposed, description, runDate, options)
    body = {}
    if options ~= nil then
        if options['query'] ~= nil then
            body = options['query']        
        end
    else
        options = {}
    end
    
    body['variables'] = variables
    body['experiment'] = experiment
    body['userProposed'] = userProposed
    body['description'] = description
    body['runDate'] = runDate

    response = self.client:post('/alpha/results/', body, options);
    return response
end

return Results