local Result = require('api.whetlab_api.api.Result')
local Results = require('api.whetlab_api.api.Results')
local Setting = require('api.whetlab_api.api.Setting')
local Settings = require('api.whetlab_api.api.Settings')
local Suggest = require('api.whetlab_api.api.Suggest')
local Experiment = require('api.whetlab_api.api.Experiment')
local Experiments = require('api.whetlab_api.api.Experiments')
local http_client = require('api.whetlab_api.http_client.http_client')

local client = {}; client.__index = client

local function construct(objname, auth, options)
  local self = setmetatable({}, client)
  self.httpclient = http_client(auth, options)
  return self
end
setmetatable(client, {__call = construct})

-- Manipulate a result set indexed by its id
--
-- id - Identifier of a result
function client:result(id)
    response = Result(id, self.httpclient)
    return response
end

-- Returns the variables set for a user
--
function client:variables()
    return Variables(self.httpclient)
end

-- Manipulate the experiment indexed by id.
--
-- id - Identifier of corresponding experiment
function client:experiment(id)
    return Experiment(id, self.httpclient)
end

-- Returns the settings config for an experiment
--
function client:settings()
    return Settings(self.httpclient)
end

-- Return user list
--
function client:users()
    return Users(self.httpclient)
end

-- Manipulate the results set for an experiment given filters
--
function client:results()
    return Results(self.httpclient)
end

-- Returns the tasks set for a user
--
function client:tasks()
    return Tasks(self.httpclient)
end

-- Ask the server to propose a new set of parameters to run the next experiment
--
-- taskid - Identifier of corresponding task
function client:suggest(exptid)
    return Suggest(exptid, self.httpclient)
end

-- Returns the experiments set for a user
--
function client:experiments()
    return Experiments(self.httpclient)
end

-- Manipulate an experimental settings object
--
function client:setting()
    return Setting(self.httpclient)
end

return client
