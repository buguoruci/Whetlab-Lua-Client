whetlab = require('whetlab')

-- A custom unit testing object for the whetlab Lua client.
local TestWhetlab = {}
TestWhetlab.__index = TestWhetlab
setmetatable(TestWhetlab, { __call = function (cls, ...) return cls.new(...) end})

function TestWhetlab.new()

	local self = setmetatable({},TestWhetlab)

	self.default_expt_name = 'Lua test experiment'
	self.default_access_token = ''  -- Read from dotfile

	----
	-- Below is where you define unit test functions.
	-- IMPORTANT : 
	--     * their name must start with "test"
	--     * must assign explicitly to self after 
	----

	---- We need to be able to delete experiments for most tests to work
	function testCreateDeleteExperiment(self)
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

	    -- Create a new experiment 
	    local scientist = whetlab('New experiment', 'Foo', parameters, outcome)
	    
		delete_experiment('New experiment')
	end
	self.testCreateDeleteExperiment = testCreateDeleteExperiment

	function testSuggestUpdateExperiment(self)
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'Foo', parameters, outcome)

	    local job = scientist:suggest()
	    scientist:update(job, 12)

	    scientist:cancel(job)

	    job = scientist:suggest()
	    scientist:update(job, 6.7)
	end
	self.testSuggestUpdateExperiment = testSuggestUpdateExperiment

	function testPendingDifferentExperiment(self)
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'Foo', parameters, outcome)
	    
	    local job = scientist:suggest()
	    local job2 = scientist:suggest()

	    assert(not table_equal(job,job2))
	end
	self.testPendingDifferentExperiment = testPendingDifferentExperiment

	function testLargerSizes(self)
		local size1 = 2
		local size2 = 3
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=size1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = size2}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'Foo', parameters, outcome)

	    
	    local job = scientist:suggest()
	    assert(table_length(job.Lambda) == size1)
	    assert(table_length(job.Alpha)  == size2)

	    local job2 = scientist:suggest()
	    assert(table_length(job2.Lambda) == size1)
	    assert(table_length(job2.Alpha)  == size2)
   	    assert(not table_equal(job,job2))
	end
	self.testLargerSizes = testLargerSizes

	-- Make sure what we pass to the server doesn't get
	-- clobbered somehow.
	function testBestExperiment(self)
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Mojo'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'Waaaa', parameters, outcome)

	    local job_best
	    local result_best
		for i = 1,5 do
	    	local job = scientist:suggest()
	    	local result = math.random()
	    	scientist:update(job,result)
	    	if result_best == nil or result_best < result then
	    		result_best = result
	    		job_best = job
			end
	    end

	    job_best.result_id_ = nil
	    
	    assert(table_equal(job_best,scientist:best()))
	end
	self.testBestExperiment = testBestExperiment

	-- Test that we can get the id of an experiment sent to the server.
	function testGetId(self)
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Mojo'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'W00t', parameters, outcome)
	    
	    local jobs = {}
	    for i = 1,5 do
	    	local job = scientist:suggest()
	    	jobs[i] = job
	    	local result = math.random()
	    	scientist:update(job,result)
	    end

	    for i = 1,5 do
	    	assert(scientist:get_id(jobs[i]) > 0)
	    end
	end
	self.testGetId = testGetId

	---- Empty experiment names shouldn't work. 
	function testEmptyCreateExperiment(self)    
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

		local status, err = pcall(function () whetlab('', 'Foo', parameters, outcome) end )
		assert(not status)
	end
	self.testEmptyCreateExperiment = testEmptyCreateExperiment

	---- Experiment with invalid type for parameter shouldn't work
	function testInvalidParameterType(self)    
	    local parameters = {}
	    parameters.Lambda = {type = 'foot', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

		local status, err = pcall(function () whetlab(self.default_expt_name, 'Foo', parameters, outcome) end )
		assert(not status and err:find('Type foot not a valid choice') ~= nil)
	end
	self.testInvalidParameterType = testInvalidParameterType

	---- Parameter must respect its min/max range
	function testMinGreaterThanMax(self)    
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 0.75, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Negative deviance'

		local status, err = pcall(function () whetlab(self.default_expt_name, 'Foo', parameters, outcome) end )
		assert(not status and err:find('min should be smaller than max') ~= nil)
	end
	self.testMinGreaterThanMax = testMinGreaterThanMax

	---- Empty outcome names shouldn't work. 
	function testEmptyOutcome(self)    
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = ''

		local status, err = pcall(function () whetlab(self.default_expt_name, 'Foo', parameters, outcome) end )
		assert(not status and err:find('required') ~= nil)
	end
	self.testEmptyOutcome = testEmptyOutcome

	---- Empty description should be ok. 
	function testEmptyDescription(self)    
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Bleh'

		-- Create a new experiment 
		whetlab(self.default_expt_name, '', parameters, outcome) 
	end
	self.testEmptyDescription = testEmptyDescription

	---- Can resume existing experiment
	function testResume(self)    
	    local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'float', min = 1e-4, max = 1, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Bleh'

		-- Create a new experiment 
		scientist = whetlab(self.default_expt_name, '', parameters, outcome)

	    local jobs = {}
	    -- Get suggestions and update with results
		for i = 1,5 do
	    	local job = scientist:suggest()
	    	jobs[i] = job
	    	local result = math.random()
	    	scientist:update(job,result)
	    end

	    -- Get suggestions that will be pending
		for i = 6,10 do
	    	job = scientist:suggest()
	    	jobs[i] = job
	    end

		jobs[11] = {Lambda=0.1, Alpha=0.4, nwdigets = 44}

		scientist:update(jobs[11],0.5)

		local n_pending = table_length(scientist:pending())
		local best_job = scientist:best_job()

		-- Resume
		local scientist2 = whetlab(self.default_expt_name, '', parameters, outcome)

		assert(n_pending == table_length(scientist2:pending()))
		assert(table_equal(best_job,scientist2:best_job()))
	end
	self.testResume = testResume

	---- Support for enums
	function testEnum(self)

		local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'enum', options = {'blu','bli','bla'}, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Mojo'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'Waaaa', parameters, outcome)

		for i = 1,5 do
	    	local job = scientist:suggest()
	    	local result = math.random()
	    	scientist:update(job,result)
	    end

	end    
	self.testEnum = testEnum    

	---- Detects when an enum doesn't take value in options
	function testEnumInOptions(self)

		local parameters = {}
	    parameters.Lambda = {type = 'float', min = 1e-4, max = 0.75, size=1}
	    parameters.Alpha = {type = 'enum', options = {'blu','bli','bla'}, size = 1}
	    parameters.nwidgets = {type = 'integer', min = 1, max = 100, size = 1}
	    local outcome = {}
	    outcome.name = 'Mojo'

	    -- Create a new experiment 
	    local scientist = whetlab(self.default_expt_name, 'Waaaa', parameters, outcome)

	    local status, err = pcall( function () scientist:update({Lambda=0.1, Alpha='blo', nwdigets = 44},0.5) end)
	    assert(not status and err:find('The job specified is invalid.') ~= nil)

	end        
	self.testEnumInOptions = testEnumInOptions

	return self
end

function TestWhetlab:run()

	local n_tests = 0
	local n_failed = 0
	for name, fct in pairs(self) do
		if name:find('test') and type(fct) == 'function' then
			n_tests = n_tests + 1
			self:setup()

			local status, err = pcall(function () fct(self) end)
			if status then
				print('Test ' .. name .. ' succeeded')
			else
				print('Test ' .. name .. ' failed with: ' .. err)
				n_failed = n_failed + 1

			self:teardown()
			end
		end
	end
	print('Failed ' .. n_failed .. ' tests on ' .. n_tests)
end

function TestWhetlab:setup() 
	-- Make sure the test experiment doesn't exist
	pcall( function () delete_experiment(testCase.default_expt_name) end)
end

function TestWhetlab:teardown()
	-- Make sure the test experiment doesn't exist
	pcall( function () delete_experiment(testCase.default_expt_name) end)
end


-- Running tests
tests = TestWhetlab()
tests:run()

