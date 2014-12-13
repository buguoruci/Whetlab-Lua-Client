-- In this example we will optimize the 'Braninhoo' optimization benchmark.
-- There is also a constraint on the function.
whetlab = require("whetlab")

-- Define parameters to optimize
parameters = {}
parameters['X'] = {type='float', min=0, max=15, size=1}
parameters['Y'] = {type='float', min=-5, max=10, size=1}

outcome = {name = 'Negative Braninhoo Value'}

accessToken = ''; -- Either replace this with your access token or put it in your ~/.whetlab file.
name = 'Constrained Braninhoo Lua Example'
description = 'Optimize the braninhoo optimization benchmark';

-- Create a new experiment
scientist = whetlab(name,
                    description,
                    parameters,
                    outcome)

for i = 1,100 do
    -- Get suggested new experiment
    job = scientist:suggest()

    -- Perform experiment: Braninhoo function
    if job.X > 10 then -- A constraint
        result = -math.huge
    else
        result = (job.Y - (5.1/(4*math.pi^2))*job.X^2 + (5/math.pi)*job.X - 6)^2 + 10*(1-(1./(8*math.pi)))*math.cos(job.X) + 10*1
    end
    
    -- Inform scientist about the outcome
    scientist:update(job,-result)
end