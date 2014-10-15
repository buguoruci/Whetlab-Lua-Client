#! /bin/lua

local json = require("json") -- luajson

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

-- Grab the results corresponding to an experiment
print('--------------------')
print('Results:')
print('--------------------')
options = {query={experiment=id}}
result = client:results():get(options)['results']
print(result)
for num, res in pairs(result) do
    for k,v in pairs(res) do
        print(k, v)
    end
end

-- Create a new experiment
jsonstr = '{"settings":[{"scale": "linear", "name": "Cooling Time", "min": 0.0, "max": 10.0, "options": null, "experiment": 11, "units": "", "isOutput": false, "type": "float", "id": 25, "size": 1}, {"scale": "linear", "name": "Pinches of Salt", "min": 0.0, "max": 10.0, "options": null, "experiment": 11, "units": "", "isOutput": false, "type": "integer", "id": 24, "size": 1}, {"scale": "linear", "name": "Boiling Time", "min": 0.0, "max": 12.0, "options": null, "experiment": 11, "units": "", "isOutput": false, "type": "float", "id": 23, "size": 1}, {"scale": "linear", "name": "Tastiness", "min": null, "max": null, "options": null, "experiment": 11, "units": "", "isOutput": true, "type": "float", "id": 22, "size": 1}],"name":"Johns Eggsperiment.","description":"Optimizing the recipe for the perfect soft-boiled egg."}'
experiment = json.decode(jsonstr)
res = client:experiments():create(experiment['name'], experiment['description'], experiment['settings'])
for k,v in pairs(res) do
    print(k, v)
end


-- Add a result

