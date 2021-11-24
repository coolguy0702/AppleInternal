#!/usr/local/bin/recon
-- This runs a libMicro configuration, outputting a global score
-- and a perfdata summarizing all the ran test cases
local jsonschema = require 'jsonschema'
local perfdata = require 'perfdata'
local cjson = require 'cjson'
local benchrun = require 'benchrun'

local score_unit = assert(perfdata.unit.custom('score'), 'failed to get score unit')

local unit = assert(perfdata.unit['microseconds'], 'failed to get microseconds unit')

local config

local DEFAULT_CONFIG_FILE = '/libMicro_UNIX.json'

local bench = assert(benchrun.new{
  name='libMicro',
  arg = arg,
  iterations=1,
  sleep=2,
  version=1,
  modify_argparser = function(parser)
    parser:option{
      name='--config-file',
      description='libMicro workload configuration file',
    }
    parser:option{
      name='--path',
      description='libMicro path',
      default='/AppleInternal/Tests/libMicro'
    }
    parser:option{
      name='--test',
      description='only run tests matching name',
      args=1
    }
    parser:action(function(args)
      -- Load the schema file
      local schemafile = assert(io.open(args.path .. '/libmicro-schema.json','r'), 'failed to open schema file')
      local schemadata = schemafile:read('*a')
      local schema = assert(cjson.decode(schemadata), 'failed to parse schema as JSON')
      local validator = jsonschema.generate_validator(schema)
      -- If no config file was specified, find the default file inside the libMicro folder
      if args.config_file == nil then
        args.config_file = args.path .. '/' .. DEFAULT_CONFIG_FILE
      end
      -- Load the configuration file, verify that it's valid and override the name and the version of the test with
      -- data found in the configuration file
      local configfile = assert(io.open(args.config_file, 'r'), 'failed to open workload configuration file')
      local configdata = configfile:read('*a')
      config = assert(cjson.decode(configdata), 'failed to parse workload configuration file')
      assert(validator(config), 'JSON workload file is invalid')

      if args.test then
        args.name = table.concat({config.name, args.test}, '_')
      else
        args.name = config.name
      end

      args.version = config.version

      configfile:close()
      schemafile:close()
    end
    )
  end
})

assert(config, "configuration directory wasn't loaded after argument parsing")

if bench.opt.test then
  print('Running only tests matching', bench.opt.test)
  for key, test in pairs(config.tests) do
    if test.name ~= bench.opt.test then
      config.tests[key] = nil
    end
  end
end

-- All tests need to run with these for their output to be parseable
config.defaults['extended-output'] = true
config.defaults['no-result-header'] = true

local global_score = 0
local global_weights = 0

for _, test in pairs(config.tests) do
  local testbinary = test.binary or test.name
  local testpath = table.concat({bench.opt.path, testbinary}, '/')
  local scores = 0

  for _, case in ipairs(test.cases) do
    local baseline = case.baseline
    if not(baseline) then
      error(('No baseline for %s'):format(test.name))
    end

    case.baseline = nil
    -- Global defaults first, then test defaults, then test case arguments
    local args = {}
    for k, v in pairs(config.defaults) do args[k] = v end
    if test.defaults then
      for k, v in pairs(test.defaults) do
        if not(case[k]) then
          case[k] = v
        end
        args[k] = v
      end
    end
    for k, v in pairs(case) do args[k] = v end

    local cmd = {testpath, name = test.name}

    for k, v in pairs(args) do
      table.insert(cmd, ('--%s=%s'):format(k, v))
    end
    for out in bench:run(cmd) do
      local vars = {}
      for k, v in pairs(case) do
        vars[k] = v
      end

      local out_numbers = out:gsub('^[A-Za_-z0-9]+%s+[0-9]+%s+[0-9]', '')
      local median, min, max, mean, stddev, samples, errors = out_numbers:match(('%s+([0-9.]+)'):rep(7))
      if median == nil then
        error(('could not parse output %s'):format(out))
      end
      if math.floor(errors) > 0 then
        error(('%s had %d errors'):format(test.name, errors))
      end

      local score = math.floor(baseline / median * 1000)

      vars[perfdata.larger_better] = true
      bench.writer:add_value(test.name, score_unit, score, vars)
      vars[perfdata.larger_better] = false

      scores = scores + math.log(score)
      print(score, median, min, max, mean, stddev, samples)

      vars[perfdata.stats.median] = median
      vars[perfdata.stats.mean] = mean
      vars[perfdata.stats.min] = min
      vars[perfdata.stats.max] = max
      vars[perfdata.stats.std_dev] = stddev

      bench.writer:add_stats(test.name .. '_duration', unit, samples, vars)
    end
  end
  -- Compute the geomean of all cases for that test
  local score = math.exp(scores / (#test.cases * bench.iterations))
  bench.writer:add_value(test.name  .. '_score', score_unit, score, {[perfdata.larger_better]=true})
  local weight = (test.weight or #test.cases) * bench.iterations
  global_weights = global_weights + weight
  global_score = global_score + math.log(score) * weight
end
-- Compute the weighted geomean of all tests
global_score = math.exp(global_score / global_weights)

print('Score ', global_score)
bench.writer:add_value(bench.opt.name, score_unit, global_score, {[perfdata.larger_better]=true; perfdata.tags.summary})
bench.writer:set_primary_metric(bench.opt.name)
bench:finish()
