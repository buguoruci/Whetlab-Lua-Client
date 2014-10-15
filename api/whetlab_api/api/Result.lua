local Result = {}; Result.__index = Result

local function construct(id, client)
  local self = setResultetatable({ id=id, client=client}, Result)
  return self
end
setmetatable(Result, {__call = construct})

-- Return a specific result indexed by id
-- '/alpha/results/:id/' GET
--
function Result:get(options)
        -- if ~exist('options','var')
        --     options = struct;
        -- end
        if options['query'] ~= nil then
            body = options['query']
        else
            body = {}
        end
        
        response = self.client.get('/alpha/results/' .. self.id .. '/', body, options);
        return response
end

-- Delete the result instance indexed by id
-- '/alpha/results/:id/' DELETE
--
function Result:delete(options)
        -- if ~exist('options','var')
        --     options = struct;
        -- end
        if options['body'] ~= nil then
            body = options['body']
        else
            body = {}
        end
        
        response = self.client.delete('/alpha/results/' .. self.id .. '/', body, options);
        return response
end

-- Update a specific result indexed by id
-- '/alpha/results/:id/' PATCH
--
-- variables - The result list of dictionary objects with updated fields.
-- experiment - Experiment id
-- userProposed - userProposed
-- description - description
-- runDate - <no value>
-- id - <no value>
function Result:update(variables, experiment, userProposed, description, runDate, id, options)
        -- if ~exist('options','var')
        --     options = struct;
        -- end
        if options['body'] ~= nil then
            body = options['body']
        else
            body = {}
        end
        
        body['variables'] = variables
        body['experiment'] = experiment
        body['userProposed'] = userProposed
        body['description'] = description
        body['runDate'] = runDate
        body['id'] = id

        response = self.client.patch('/alpha/results/' .. self.id .. '/', body, options);
        return response
end

-- Replace a specific result indexed by id. To be used instead of update if HTTP patch is unavailable
-- '/alpha/results/:id/' PUT
--
-- variables - The result list of dictionary objects with updated fields.
-- task - Task id
-- userProposed - userProposed
-- description - description
-- runDate - <no value>
-- id - <no value>
function Result:replace(variables, experiment, userProposed, description, runDate, id, options)
        -- if ~exist('options','var')
        --     options = struct;
        -- end
        if options['body'] then
            body = options['body']
        else
            body = struct
        end
        
        body['variables'] = variables
        body['experiment'] = experiment
        body['userProposed'] = userProposed
        body['description'] = description
        body['runDate'] = runDate
        body['id'] = id

        response = self.client.put('/alpha/results/' .. self.id .. '/', body, options);
        return response
end

