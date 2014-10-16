
-- Validation things
local supported_properties = {'isOutput', 'name', 'min', 'max', 'size', 'scale', 'units', 'type'}
local required_properties = {'min', 'max'}
local default_values = {size = 1, scale = 'linear', units = 'Reals', type = 'float'}

local INF_PAGE_SIZE = 1000000

-- A simple helper function to return the number of elements in a table
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- A simple helper function to compare two tables
function table_equal(x,y)
    if type(x) ~= 'table' or type(y) ~= 'table' then
        return x == y
    end

    for k,v in pairs(x) do
        if not table_equal(v,y[k]) then return false end
    end

    for k,v in pairs(y) do
        if not table_equal(x[k],v) then return false end
    end
    return true
end



-- Helper function for sleep
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while math.abs(clock() - t0) <= n do end
end

-- Helper function for different types of errors

function value_error(msg)
    error('Whetlab:ValueError: ' .. msg)
end

function enf_error(msg)
    error('Whetlab:ExperimentNotFoundError: ' .. msg)
end

function read_dot_file()
    vars = {}
    -- Get local .whetlab file
    local fid = io.open('.whetlab','r')

    -- If can't get .whetlab file, get ~/.whetlab
    if not fid then fid = io.open('~/.whetlab','r') end

    if not fid then
        return vars
    end

    function trim(s)
      return s:gsub("^%s+", ""):gsub("%s+$", "")
    end

    for line in fid.lines() do
        if line:len() ~= 0 and line:sub(1,1) ~= '#' and line:sub(1,1) ~= '%' then
            -- Split into key and value
            pos_equal = line:find('=')
            key = trim(line:sub(1,pos_equal-1))
            val = trim(line:sub(pos_equal+1))
            vars[key] = val
        end
    end

    fid:close()
    return vars
end

function delete_experiment(name, access_token)
    ---- delete_experiment(name, access_token)
    --
    -- Delete the experiment with the given name.  
    --
    -- Important, this cancels the experiment and removes all saved results!
    --
    -- * *name* (str): Experiment name
    -- * *access_token* (str): User access token
    --
    -- Example usage::
    --
    --   -- Delete the experiment and all corresponding results.
    --   access_token = '' -- Assume this is taken from ~/.whetlab
    --   whetlab.delete_experiment('My Experiment',access_token)

    -- First make sure the experiment with name exists
    scientist = Experiment(name, '', {}, {}, true, access_token)
    scientist.delete()
end


-- Definition of Experiment class --

local Experiment = {}
Experiment.__index = Experiment
setmetatable(Experiment, { __call = function (cls, ...) return cls.new(...) end, ) })


function Experiment.new(name, description, parameters, outcome, resume, access_token)
    --[[--
    Experiment(name, description, parameters, outcome, resume, access_token)
    
    Instantiate a Whetlab client.
    This client allows you to manipulate experiments in Whetlab
    and interact with the Whetlab server.
    
    A name and description for the experiment must be specified.
    A Whetlab access token must also be provided.
    The parameters to tune in the experiment are specified by
    ``parameters``. It should be a ``table``, where the keys are
    the parameters (``str``) and values are ``table``s that
    provide information about these parameters. Each of these
    ``table`` should contain the appropriate keys to properly describe
    the parameter:
    
    * **type**: type of the parameter, among ``float``, ``int`` and ``enum``(default: ``float``)
    * **min**: minimum value of the parameter (only for types ``float`` and ``int``)
    * **max**: maximum value of the parameter (only for types ``float`` and ``int``)
    * **options**: cell of strings, of the possible values that can take an ``enum`` parameter (only for type ``enum``)
    * **size**: size of parameter (default: ``1``)
    
    Outcome should also be a ``table``, describing the outcome. It
    should have the field:
    
    * *name*: name (``str``) for the outcome being optimized
    
    Finally, experiments can be resumed from a previous state.
    To do so, ``name`` must match a previously created experiment
    and argument ``resume`` must be set to ``True`` (default is ``False``).
    
    * *name* (str): Name of the experiment.
    * *description* (str): Description of the experiment.
    * *parameters* (table): Parameters to be tuned during the experiment.
    * *outcome* (table): Description of the outcome to maximize.
    * *resume* (boolean): Whether to resume a previously executed experiment. If ``True`` and experiment's name matches an existing experiment, ``parameters`` and ``outcome`` are ignored (default: ``None``).
    * *access_token* (str): Access token for your Whetlab account. If ``''``, then is read from whetlab configuration file (default: ``''``).
    
    A Whetlab experiment instance will have the following variables:
    
    * *parameters* (table): Parameters to be tuned during the experiment.
    * *outcome* (table): Description of the outcome to maximize.
    
    Example usage::
    
      -- Create a new experiment
      name = 'A descriptive name'
      description = 'The description of the experiment'
      parameters = {Lambda = {type = 'float', min = 1e-4, max = 0.75, size = 1},
                    Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}}
      outcome = {}
      outcome.name = 'Accuracy'
    
      scientist = whetlab(name, description, parameters, outcome, true)

    --]]--
    
    local self = setmetatable({},Experiment)

    -- ... From result IDs to client parameter values
    self.ids_to_param_values   = {}

    -- ... From result IDs to outcome values
    self.ids_to_outcome_values = {}

    -- ... From parameters to their 'ids'
    self.params_to_setting_ids = {}

    -- All of the parameter values seen thus far
    self.param_values          = {}

    -- All of the outcome values seen thus far
    self.outcome_values        = {}

    -- The set of result IDs corresponding to suggested jobs that are pending
    self.experiment            = ''
    self.experiment_description= ''
    self.experiment_id = -1
    self.outcome_name = ''
    self.parameters = parameters

    self.resume = resume or true
    self.experiment_id = -1

    local vars = read_dot_file()

    access_token = access_token or vars.access_token
    if not access_token then
        value_error('You must specify your access token in the variable access_token either in the client or in your ~/.whetlab file')
    end

    -- Make a few obvious asserts
    if name == '' then
        value_error('Name of experiment must be a non-empty string.')
    end

    if type(description) ~= 'string' then
        value_error('Description of experiment must be a string.')
    end

    -- Create REST server client
    local hostname = vars.api_url or 'https://www.whetlab.com/'

    self.client = SimpleREST(access_token, hostname, retries)

    self.experiment_description = description
    self.experiment = name
    self.outcome_name = outcome.name

    if resume then
        -- Try to resume if the experiment exists. If it doesn't exist, we'll create it.
        self.experiment_id = experiment_id
        status, err = pcall(self:sync_with_server)
        if status then
            print('Resuming experiment ' .. self.experiment)
        else
            if not err:find('Whetlab:ExperimentNotFoundError:') then
                error(err)
            end
        end
    end

    if type(parameters) ~= "table" then
        value_error('Parameters of experiment must be a table.')
    end

    if type(outcome) ~= "table" then
        value_error('Outcome of experiment must be a table.')
    end

    if outcome['name'] == nil then
        value_error('Argument outcome should have a field called: name.')
    end
    self.outcome_name = outcome.name

    -- Create new experiment
    -- Add specification of parameters
    settings = {}
    for name, param in pairs(parameters) do
        -- Add default parameters if not present
        if param['type'] == nil then param['type'] = default_values['type'] end
        if param['type'] == "int" then param['type'] = "integer" end
        if param['isOutput'] == nil then param['isOutput'] = false end

        if param['type'] == 'enum' then
            if param['options'] == nil or tableLength(param['options']) < 2 then
                value_error('Parameter ' .. name .. ' is an enum type which requires the field options with more than one element.')
            end        
        else
            for key,v in pairs(param) do
                if supported_properties[key] == nil then
                    value_error('Parameter ' .. name .. ': property ' .. key .. ' is not supported.')
                end
            end

            -- Check if required properties are present
            for key,v in pairs(required_properties) do
                if param[key] == nil then
                    value_error('Parameter ' .. name .. ': property ' .. key .. ' must be defined.'])
                end
            end

            -- Add default parameters if not present
            if param['units'] == nil then param['units'] = default_values['units'] end
            if param['scale'] == nil then param.scale = default_values.scale end
            if param['isOutput'] == nil then param['isOutput'] = false end

            -- Check compatibility of properties
            if param.min >= param.max then
                value_error('Parameter ' .. name .. ': min should be smaller than max.')
            end
        end
        settings[name] = param
    end
    self.parameters = settings

    -- Add the outcome variable
    param = {'units'='Reals', 'scale'='linear', 'type'='float', 'isOutput'=true, 'min'=-100, 'max'=100, 'size'=1}
    for k,v in pairs(outcome) do param[k] = v end
    outcome = param
    outcome.name = self.outcome_name
    settings[outcome.name] = outcome

    status, err = pcall(function () return self.client:create(name, description, settings) end)
    if not status then
        -- Resume, unless got a ConnectionError
        if resume and err ~= '???Whetlab:ExperimentExists?????') then
            -- This experiment was just already created - race condition.
            self:sync_with_server()
            return
        else
            error(err)
        end
    else
        experiment_id = err
    end

    self.experiment_id = experiment_id

    -- Check if there are pending experiments
    p = self:pending()
    if tableLength(p) > 0 then
        print('INFO: this experiment currently has %d jobs (results) that are pending.' .. tableLength(p))
    end
end -- Experiment()

function Experiment:sync_with_server()
    ---- sync_with_server(self)
    --
    -- Synchronize the client's internals with the REST server.
    --
    -- Example usage::
    --
    --   -- Create a new experiment 
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   scientist.sync_with_server()

    -- Reset internals
    self.ids_to_param_values = {}
    self.ids_to_outcome_values = {}
    self.params_to_setting_ids = {}

    local found = false

    if self.experiment_id < 0 then
        self.experiment_id = self.client:find_experiment(self.experiment)
        if self.experiment_id < 0 then
            enf_error('Experiment with name ' .. self.experimnet .. ' and description ' .. self.experiment_description  ' not found.')
        end
    else
        local details = self.client:get_experiment_details(self.experiment_id)
        self.experiment = details.name
        self.experiment_description = details.description
    end

    -- Get settings for this task, to get the parameter and outcome names
    local rest_parameters = self.client:get_parameters(self.experiment_id)
    self.parameters = {}
    for i,param in pairs(rest_parameters) do
        param = rest_parameters{i}
        if(param.experiment ~= self.experiment_id) then continue end
        local id = param.id
        local name = param.name
        local vartype=param.type
        local minval=param.min
        local maxval=param.max
        local varsize=param.size
        local units=param.units
        local scale=param.scale
        local isOutput=param.isOutput

        self.params_to_setting_ids[name] = id

        if isOutput then
            self.outcome_name = name
        else
            if vartype ~= 'enum' then
                self.parameters[name] = {name = name, type = vartype, min = minval, max = maxval,
                                         size = varsize, isOutput = false, units = units, scale = scale}
            elseif vartype == 'enum' then
                options = param.options
                self.parameters[name] = {name = name, type = vartype, min = minval, max = maxval,
                                         size = varsize, isOutput = false, units = units, scale = scale, options = options}
            else
                value_error('Type ' .. vartype .. ' not supported for variable ' .. name)
            end                    
        end
    end

    -- Get results generated so far for this task
    local rest_results = self.client:get_results(self.experiment_id)
    -- Construct things needed by client internally, to keep track of
    -- all the results

    for i, res in pairs(rest_results) do
        local res_id = res.id
        local variables = res.variables
        local tmp = {}

        -- Construct param_values hash and outcome_values
        for j, v in pairs(variables) do

            local id = v.('id')
            local name = v.('name')                
            if name == self.outcome_name then
                -- Anything that's passed back as a string is assumed to be a
                -- constraint violation.
                if type(v.value) == 'string' then
                    v.value = -math.huge
                end

                self.ids_to_outcome_values[res_id] = v.value
            else
                -- Initialize to empty table if hasn't been created yet
                if self.ids_to_param_values[res_id] == nil then self.ids_to_param_values[res_id] = {} end
                self.ids_to_param_values[res_id][v.name] = v.value
            end
        end
    end

end

function Experiment:pending()
    ---- pend = pending(self)
    -- Return the list of jobs which have been suggested, but for which no 
    -- result has been provided yet.
    --
    -- * *returns:* Struct array of parameter values.
    -- * *return type:* struct array
    -- 
    -- Example usage::
    --
    --   -- Create a new experiment
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   -- Get the list of pending experiments
    --   pend = scientist.pending()

    -- Sync with the REST server     
    self:sync_with_server()

    -- Find IDs of results with value nil and append parameters to returned list
    local i = 1
    local ret = {}
    for key,val in pairs(self.ids_to_outcome_values) do
        if val == nil:
            ret[i] = self.ids_to_param_values[key]
    return ret
end -- pending()

function Experiment:clear_pending()
    ---- clear_pending(self)
    -- Delete all of the jobs which have been suggested but for which no 
    -- result has been provided yet (i.e. pending jobs).
    --
    -- This is a utility function that makes it easy to clean up
    -- orphaned experiments.
    --
    -- Example usage::
    --
    --   -- Create a new experiment
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   -- Clear all of orphaned pending experiments
    --   scientist.clear_pending()
    
    local jobs = self:pending()
    for i, job in pairs(jobs) do
        self:cancel(job)
    end
    self:sync_with_server()
end        

function Experiment:suggest()
    ---- next = suggest(self)
    -- Suggest a new job.
    -- 
    -- This function sends a request to Whetlab to suggest a new
    -- experiment to run.  It may take some time to return while waiting
    -- for the suggestion to complete on the server.
    --
    -- This function returns struct containing parameter names and 
    -- corresponding values detailing a new experiment to be run.
    --
    -- * *returns:* Values to assign to the parameters in the suggested job.
    -- * *return type:* struct
    --
    -- Example usage::
    --
    --   -- Create a new experiment
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   -- Get a new experiment to run.
    --   job = scientist.suggest()
    
    self:sync_with_server()
    local result_id = self.client:get_suggestion(self.experiment_id)
    
    -- Poll the server for the actual variable values in the suggestion.  
    -- Once the Bayesian optimization proposes an
    -- experiment, the server will fill these in.
    local result = self.client:get_result(result_id)
    local variables = result.variables
    while variables == nil
        sleep(2)
        result = self.client:get_result(result_id)
        variables = result.variables
    end
    
    -- Put in a nicer format
    local next = {}
    for i, variable in pairs(variables) do
        if variable.name ~= self.outcome_name then
            next[variable.name] = variable.value
        end
    end        

    -- Keep track of id / param_values relationship
    self.ids_to_param_values[result_id] = next
    next.result_id_ = result_id
end -- suggest

function Experiment:get_id(param_values)
    ---- id = get_id(self, param_values)
    -- Return the result ID corresponding to the given _param_values_.
    -- If no result matches, return -1.
    --
    -- * *param_values* (struct): Values of parameters.
    -- * *returns:* ID of the corresponding result. If not match, -1 is returned.
    -- * *return type:* int or -1
    --
    -- Example usage::
    --
    --   -- Create a new experiment
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   -- Get a new experiment to run
    --   job = scientist.suggest()
    --   
    --   -- Get the corresponding experiment id.
    --   id = scientist.get_id(job)
    
    
    -- Convert to a cell array if params are specified as a struct.
    -- Cell arrays allow for spaces in the param names.
    -- if isstruct(param_values)
    --     param_values = whetlab.struct_2_cell_params(param_values)
    -- end

    -- First sync with the server
    self = self:sync_with_server()

    -- Remove key result_id_ if present
    if param_values.result_id_ ~= nil then
        param_values.result_id_ = nil
    end

    local id = -1
    for id, pv in pairs(self.ids_to_param_values) do
        if table_equal(param_values, pv) then
            return id
        end
    end
    return id
end -- get_id

function Experiment:delete()
    ---- delete(self)
    --
    -- Delete this experiment.  
    --
    -- Important, this cancels the experiment and removes all saved results!
    --
    -- Example usage::
    --
    --   -- Create a new experiment
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   -- Delete this experiment and all corresponding results.
    --   scientist.delete()
    
    self.client:delete_experiment(self.experiment_id)
end

function Experiment:update(param_values, outcome_val)
    ---- update(self, param_values, outcome_val)
    -- Update the experiment with the outcome value associated with some parameter values.
    -- This informs Whetlab of the resulting outcome corresponding to
    -- the experiment specified by _param_values_.  _param_values_ can 
    -- correspond to an experiment suggested by Whetlab or an
    -- independently run (user proposed) experiment.
    --
    -- * *param* param_values: Values of parameters.
    -- * *type* param_values: struct
    -- * *param* outcome_val: Value of the outcome.
    -- * *type* outcome_val: type defined for outcome
    -- 
    -- Example usage::
    -- 
    --   -- Assume that a whetlab instance has been instantiated in scientist.
    --   job = scientist.suggest() -- Get a suggestion
    --
    --   -- Run an experiment with the suggested parameters and record the result.
    --   result = 1.7  
    --   scientist.update(job, result)
    --

    --- I'M HERE!!

    if (length(outcome_val) > 1) or ((isstruct(param_values) and length(param_values) > 1)) then
        error('Whetlab:ValueError', 'Update does not accept more than one result at a time')
    end


    if isfield(param_values,'result_id_') then
        result_id = param_values.('result_id_')
    else
        -- Check whether this param_values has a result ID
        result_id = self.get_id(param_values)
    end

    if result_id == -1 then
        -- - Add new results with param_values and outcome_val

        -- Create variables for new result
        param_names = self.params_to_setting_ids.keySet().toArray()
        for i = 1:numel(param_names) do
            name = param_names(i)
            setting_id = self.params_to_setting_ids.get(name)
            if isfield(param_values, name) then
                value = param_values.(name)
            elseif strcmp(name, self.outcome_name) then
                value = outcome_val
                -- Convert the outcome to a constraint violation if it's not finite
                -- This is needed to send the JSON in a manner that will be parsed
                -- correctly server-side.
                if isnan(outcome_val) then
                    value = 'NaN'
                elseif ~isfinite(outcome_val) then
                    value = '-infinity' 
                end
            else
                error('InvalidJobError',...
                    'The job specified is invalid')
            end
            variables(i) = struct('setting', setting_id,...
                'name',name, 'value',value)                
        end
        result.variables = variables
        result_id = self.client.add_result(variables, self.experiment_id)

        self.ids_to_param_values.put(result_id, savejson('',param_values))
    else
        result = self.client.get_result(result_id)

        for i = 1:numel(result.variables) do
            var = result.variables{i}
            if strcmp(var.('name'), self.outcome_name) then
                -- Convert the outcome to a constraint violation if it's not finite
                -- This is needed to send the JSON in a manner that will be parsed
                -- correctly server-side.                    
                result.variables{i}.('value') = outcome_val
                if isnan(outcome_val) then
                    result.variables{i}.('value') = 'NaN'
                elseif ~isfinite(outcome_val) then
                    result.variables{i}.('value') = '-infinity'
                end
                self.outcome_values.put(result_id, savejson('',var))
                break -- Assume only one outcome per experiment!
            end
        end

        self.param_values.put(result_id, savejson('',result))
        self.client.update_result(result_id, result)

    end
    self.ids_to_outcome_values.put(result_id, outcome_val)
end --update

function Experiment:cancel(param_values)
    ---- cancel(self,param_values)
    -- Cancel a job, by removing it from the jobs recorded so far in the experiment.
    --
    -- * *param_values* (struct): Values of the parameters for the job to cancel.
    --
    -- Example usage::
    -- 
    --   -- Assume that a whetlab instance has been instantiated in scientist.
    --   job = scientist.suggest() -- Get a suggestion
    --
    --   -- Run an experiment with the suggested parameters and record the result.
    --   result = 1.7  
    --   scientist.update(job, result)
    --
    --   -- Tell Whetlab to forget about that experiment (perhaps the result was an error).
    --   scientist.cancel(job)
    
    -- Check whether this param_values has a results ID
    id = self.get_id(param_values)
    if id > 0 then
        self.ids_to_param_values.remove(num2str(id))

        -- Delete from internals
        if self.ids_to_outcome_values.containsKey(id) then
            self.ids_to_outcome_values.remove(id)
        end
            
        -- Delete from server
        self.client.delete_result(id)
    else
        warning('Did not find experiment with the provided parameters')
    end
end -- cancel

function Experiment:best()
    ---- param_values = best(self)
    -- Return the job with best outcome found so far.        
    --
    -- * *returns:* Parameter values corresponding to the best outcome.
    -- * *return type:* struct
    --
    -- Example usage::
    --
    --   -- Create a new experiment
    --   scientist = whetlab(name,...
    --               description,...
    --               parameters,...
    --               outcome, true, access_token)
    --
    --   -- Get the best job seen so far.
    --   best = scientist.best()

    -- Sync with the REST server     
    self = self.sync_with_server()

    -- Find ID of result with best outcomeh
    ids = self.ids_to_outcome_values.keySet().toArray()
    outcomes = self.ids_to_outcome_values.values().toArray()
    outcomes = arrayfun(@(x)x, outcomes)

    [~, ind] = max(outcomes)
    result_id = ids(ind)

    -- Get param values that generated this outcome
    result = self.client.get_result(result_id)
    for i = 1:numel(result.('variables')) do
        v = result.('variables'){i}
        if ~strcmp(v.name, self.outcome_name) then
            param_values.(v.name) = v.value
        end
    end
    
end -- best
    
