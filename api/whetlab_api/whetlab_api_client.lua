local client = {}; client.__index = client

local function construct(auth, options)
  local self = setmetatable({ httpclient = http_client(auth, options)}, client)
  return self
end
setmetatable(client, {__call = construct})

-- Manipulate a result set indexed by its id
--
-- id - Identifier of a result
function client:result(id)
    response = api.Result(id, self.httpclient);
    return response
end

-- Returns the variables set for a user
--
function client:variables()
    return api.Variables(self.httpclient);
end

-- Manipulate the experiment indexed by id.
--
-- id - Identifier of corresponding experiment
function client:experiment(id)
    return api.Experiment(id, self.httpclient);
end

-- Returns the settings config for an experiment
--
function client:settings()
    return api.Settings(self.httpclient);
end

-- Return user list
--
function client:users()
    return api.Users(self.httpclient);
end

-- Manipulate the results set for an experiment given filters
--
function client:results()
    return api.Results(self.httpclient);
end

-- Returns the tasks set for a user
--
function client:tasks()
    return api.Tasks(self.httpclient);
end

-- Ask the server to propose a new set of parameters to run the next experiment
--
-- taskid - Identifier of corresponding task
function client:suggest(taskid)
    return api.Suggest(taskid, self.httpclient);
end

-- Returns the experiments set for a user
--
function client:experiments()
    return api.Experiments(self.httpclient);
end

-- Manipulate an experimental settings object
--
function client:setting()
    return api.Setting(self.httpclient);
end

return client
