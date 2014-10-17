local https = require('ssl.https') -- luasec
local json = require("json") -- luajson
local ltn12 = require("ltn12")

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
    response = {}
    save = ltn12.sink.table(response) -- need a l1tn12 sink to get back the page content    

    if method == 'get' then        
        url = url .. '?' .. paramString
        ok, code, headers = https.request{url = url, method = 'GET', headers = heads, source = nil, sink = save}
    else
        ok, code, headers = https.request{url = url, method = method, headers = heads, source = source, sink = save}
    end

    if response[1] ~= nil then
        response = table.concat(response)
    else
        response = nil
    end

    -- Success
    if tonumber(code) > 199 and tonumber(code) < 300 then
        if response ~= nil then
            result = json.decode(response)
        else
            result = nil
        end
    else
        error('ClientError code:' .. code .. ' message: ' .. response)
    end

    --- show that we got a valid response
    -- print('Response:--------')
    -- print(code)
    -- print(ok)

    -- if strfind(s.message, 'java.net')
    --   error('Lua:HttpConection:ConnectionError',...
    --      'Could not connect to server.');
    -- else
    --  rethrow(s);
    -- end
    -- end
    -- Display a reasonable amount of information if the
    -- Http request fails for whatever reason
    -- if extras.isGood <= 0
    --     msg = sprintf(['Http connection to --s failed ' ...
    --                    'with status --s/--s. '], extras.url, ...
    --                   num2str(extras.status.value), ...
    --                   extras.status.msg);
    --     -- Tack on the message from the server
    --     if ~isempty(outputs)
    --         msg = strcat(msg, sprintf(['Message from server: ' ...
    --         '--s'], outputs));
    --     end
    --     error('MATLAB:HttpConection:ConnectionError', msg);
    -- end
    -- response = extras; -- Return the status code and
    --                    -- headers as well
    -- -- outputs can be empty on a delete
    -- if ~isempty(outputs)
    --     response.body = loadjson(outputs);
    -- end

    return result
end -- function
return http_client
