#! /bin/lua

whetlab_client = require('whetlab_api_client')
client = whetlab_client('43c5fda8-7ee6-4f72-a090-b679d2f30a2e', {})
result = client:result(2502)
res = result:get()
for k,v in pairs(res) do
	print(k,v)
end

-- Get a listing of experiments
print('------------')
print('Experiments:')
print('------------')
experiments = client:experiments():get()['results']
for num,exp in pairs(experiments) do
	for k, v in pairs(exp) do
		print(k, v)
	end	
end

-- Grab one example experiment
print('--------------------')
print('A Single Experiment:')
print('--------------------')
id = experiments[1]['id']
exp = client:experiment(id):get()
for k, v in pairs(exp) do
	print(k, v)
end

