local client = {}; client.__index = client

local function construct(auth, options)
  local self = setmetatable({ httpclient = http_client(auth, options)}, client)
  return self
end
setmetatable(client, {__call = construct})

-- function client:whetlab_api_client(auth, options)
--   x.httpclient = http_client(auth, options);
--   return x
-- end

-- Manipulate a result set indexed by its id
--
-- id - Identifier of a result
function client:result(x, id)
    response = api.Result(id, x.httpclient);
    return response
end

-- Returns the variables set for a user
--
function client:variables(x)
    return api.Variables(x.httpclient);
end

-- Manipulate the experiment indexed by id.
--
-- id - Identifier of corresponding experiment
function client:experiment(x, id)
    return api.Experiment(id, x.httpclient);
end

-- Returns the settings config for an experiment
--
function client:settings(x)
    return api.Settings(x.httpclient);
end

-- Return user list
--
function client:users(x)
    return api.Users(x.httpclient);
end

-- Manipulate the results set for an experiment given filters
--
function client:results(x)
    return api.Results(x.httpclient);
end

-- Returns the tasks set for a user
--
function client:tasks(x)
    return api.Tasks(x.httpclient);
end

-- Ask the server to propose a new set of parameters to run the next experiment
--
-- taskid - Identifier of corresponding task
function client:suggest(x, taskid)
    return api.Suggest(taskid, x.httpclient);
end

-- Returns the experiments set for a user
--
function client:experiments(x)
    return api.Experiments(x.httpclient);
end

-- Manipulate an experimental settings object
--
function client:setting(x)
    return api.Setting(x.httpclient);
end

return client
