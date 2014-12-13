torch = require 'torch'
mnist = require 'mnist'

mnist_trainset = mnist.traindataset()

function reformat(i,j)
    local dataset={};
    function dataset:size() return j-i+1 end 
    l = 1
    for k=i,j do 
      ex = mnist_trainset[k]
      -- Reformat MNIST examples
      x = torch.reshape(ex.x:double(),28*28)*(1/255.)
      y = ex.y+1
      dataset[l] = {x, y}
      l = l + 1
    end
    return dataset
end

trainset = reformat(1,500)
validset = reformat(501,600)

require 'nn'
require 'optim'

function run_neural_net(n_hidden_units, learning_rate, activation, n_iterations)

    -- make a multi-layer perceptron
    local mlp = nn.Sequential();  
    local inputs = 28*28; local outputs = 10; local HUs = n_hidden_units; 
    mlp:add(nn.Linear(inputs, HUs))
    if activation == 'sigmoid' then
        mlp:add(nn.Sigmoid())
    elseif activation == 'tanh' then
        mlp:add(nn.Tanh())
    else
        print('Invalid activation function')
        return nil
    end
    mlp:add(nn.Linear(HUs, outputs))
    mlp:add(nn.LogSoftMax())

    -- train neural network
    local criterion = nn.ClassNLLCriterion()  
    local trainer = nn.StochasticGradient(mlp, criterion)
    trainer.learningRate = learning_rate
    trainer.maxIteration = n_iterations
    trainer:train(trainset)

    -- compute validation set accuracy
    local confusion = optim.ConfusionMatrix(outputs)
    local acc = 0.
    for i=1,validset:size() do
      local input = validset[i][1]
      local c = validset[i][2]
      local o = mlp:forward(input)
      confusion:add(o,c)
    end
    confusion:updateValids()
    return confusion.totalValid
end


local parameters = {}
parameters.n_hidden_units = {type = 'int', min = 10, max = 100}
parameters.learning_rate = {type = 'float', min = 1e-4, max = 1e-1}
parameters.activation = {type = 'enum', options = {'sigmoid','tanh'}}
parameters.n_iterations = {type = 'int', min = 1, max = 25}

local outcome = {}
outcome.name = 'Classification accuracy'

whetlab = require 'whetlab'
local scientist = whetlab('Neural network classifier on a subset of MNIST','Tutorial example', parameters, outcome, True)

local job = scientist:suggest()
for k,v in pairs(job) do print(k,v) end

local valid_accuracy = run_neural_net(job.n_hidden_units, job.learning_rate, job.activation, job.n_iterations)
print('Validation set accuracy: ' .. valid_accuracy)
scientist:update(job,valid_accuracy)

for i = 1,19 do
  job = scientist:suggest()
  for k,v in pairs(job) do print(k,v) end
  valid_accuracy = run_neural_net(job.n_hidden_units, job.learning_rate, job.activation, job.n_iterations)
  print('Validation set accuracy: ' .. valid_accuracy)
  scientist:update(job, valid_accuracy);
end

best_job = scientist:best()
for k,v in pairs(best_job) do print(k,v) end

