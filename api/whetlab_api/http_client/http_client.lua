local https = require('ssl.https') -- luasec
local http = require('socket.http') -- luasocket
local json = require("json") -- luajson
local ltn12 = require("ltn12")

local MAX_RETRIES = 6
local RETRY_TIMES = {5,30,60,150,300,600}

-- Main HttpClient which is used by Api classes
local http_client = {}; http_client.__index = http_client
-- 'auth' = auth, 'options' = options, 'headers' = {}, 'base' = ''
local function construct(objname, auth, options)
    local self = setmetatable({}, http_client)
    if type(auth) == "string" then
        self.auth = auth
    else
        error('Only string based authentication tokens are supported.')
    end

    self.options = {}
    self.headers = {}
    self.options['base'] = 'https://www.whetlab.com/api/'
    self.options['user_agent'] = 'whetlab_lua_client'

    for key,value in pairs(options) do
        self.options[key] = value
    end
    
    if self.options['base'] ~= nil then
        self['base'] = self.options['base']
    end

    if self.options['user_agent'] ~= nil then
        self.headers['user_agent'] = self.options['user_agent']
    end

    if self.options['headers'] ~= nil then
        for key,value in pairs(options) do
            self.headers[key] = value
        end
        self.options['headers'] = nil
    end

    self.headers['Authorization'] = 'Bearer ' .. self.auth
    -- self.auth = auth_handler(self.auth)
    return self
end -- http_client
setmetatable(http_client, {__call = construct})

function http_client:get(path, params, options)
    if options == nil then
        options = {}
    end
    if params ~= nil then
        options['query'] = params
    end
    body = {}
	response = self:request(path, body, 'get', options)
    return response
end

function http_client:post(path, body, options)
	response = self:request(path, body, 'post', options)
    return response
end

function http_client:patch(path, body, options)
	response = self:request(path, body, 'patch', options)
    return response
end

function http_client:delete(path, body, options)
	response = self:request(path, body, 'delete', options)
    return response
end

function http_client:put(path, body, options)
	response = self:request(path, body, 'put', options)
    return response
end

-- Utility function to escape strings
function http_client:url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

-- Intermediate function which does three main things
--
-- - Transforms the body of request into correct format
-- - Creates the requests with give parameters
-- - Returns response body after parsing it into correct format
function http_client:request(path, body, method, options)

    for key,value in pairs(options) do
        options[key] = value
    end
    -- options = self.auth.set(options)

    headers = self.headers;
    if options['headers'] ~= nil then
        for key,value in pairs(options['headers']) do
            headers[key] = value
        end
        options['headers'] = nil
    end
    
    if options['query'] ~= nil then
        params = {}
        for key,value in pairs(options['query']) do
            params[key] = value
        end
    end

    if options['user_agent'] ~= nil then
        params['user_agent'] = options['user_agent']
    end

    if options['response_type'] ~= nil then
        params['response_type'] = options['response_type']
    end

    if options['request_type'] ~= nil then
        request_type = options['request_type']
    else
        request_type = 'json'
    end
   
    paramString = ''
    heads = {}

    if request_type == 'json' then
        request_type = 'application/json'
        for key,value in pairs(options) do
            body[key] = value
        end

        if body ~= nil then
            if string.upper(method) == 'GET' then
                if params ~= nil then
                    -- Convert parameters to a url encoded string
                    for key,value in pairs(params) do
                        paramString = paramString .. self:url_encode(key) .. '=' .. self:url_encode(value) .. '&'
                    end
                end
                source = ltn12.source.string('')
            else
                paramString = json.encode(body)
                source = ltn12.source.string(paramString)
                jsonsize = # paramString
                heads["content-length"] = jsonsize
            end
            heads['Content-Type'] = 'application/json'
        end
    else
        error('Only json requests are currently supported.')
    end

    if self.options['api_version'] == nil then
        self.options['api_version'] = ''
    end

    url = self.base .. '/' .. self.options['api_version'] .. '/' .. path
    url = string.gsub(url, "(/+)", "/")
    url = string.gsub(url, '(http:/+)', 'http://') -- Hack to fix http
    url = string.gsub(url, '(https:/+)', 'https://') -- Hack to fix https

    for key,value in pairs(headers) do
        heads[key] = value
    end

    -- Add request type to header
    if request_type ~= nil then
        heads['Accept'] = request_type
    end
    
    --- build a http request
    for i = 1,MAX_RETRIES do
        response = {}
        save = ltn12.sink.table(response) -- need a l1tn12 sink to get back the page content    

        if string.upper(method) == 'GET' then
            url = url .. '?' .. paramString
        end

        if string.match(url, 'http://') then
            ok, code, headers = http.request{url = url, method = method, headers = heads, source = source, sink = save}
        else
            ok, code, headers = https.request{url = url, method = method, headers = heads, source = source, sink = save}
        end
        code = tonumber(code)

        -- Could not communicate with the server
        if ok == nil or code == nil then
            code = 600 -- Small hack to make us retry below
        end

        if response[1] ~= nil then
            -- Try to decode json
            local status, result = pcall(json.decode, table.concat(response))
            if status then
                response = result
            end
        else
            response = nil
        end

        -- Success
        if code > 199 and code < 300 then
            break

        -- Maintenance
        elseif code == 503 then
            if response ~= nil and response['retry_in'] ~= nil then
                retry_secs = math.random(2*tonumber(result['retry_in']))
            else
                retry_secs = math.random(2*RETRY_TIMES[i])
            end
            print('The server is currently undergoing temporary maintenance. Retrying in ' .. tostring(retry_secs) .. ' seconds.')
            i = i-1

        -- Communication was distorted somehow
        elseif code == 502 or code > 503 then
            retry_secs = math.random(2*RETRY_TIMES[i])
            print('There was a problem communicating with the server.  Retrying in ' .. tostring(retry_secs) .. ' seconds.')
        else
            message = {}
            if type(response) == "table" then
                for k,v in pairs(response) do table.insert(message, v) end
                message = table.concat(message)
            else
                message = response
            end
            error('ClientError code:' .. tostring(code) .. ' message: ' .. message)
            break
        end

        os.execute("sleep " .. tonumber(retry_secs))
    end

    return response
end -- function

return http_client
