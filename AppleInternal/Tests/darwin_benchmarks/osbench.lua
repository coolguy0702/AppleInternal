#!/usr/local/bin/recon

local cjson = require 'cjson.safe'
local benchrun = require 'benchrun'
local perfdata = require 'perfdata'
local proc = require 'proc'

require 'strict'

local assetdir = os.getenv('DT_ASSETS') or '.'
local tmpdir = os.getenv('TMPDIR') or '/tmp'

local jsonfile = tmpdir .. '/osbench.json'
local osbench_tarball = assetdir .. '/osbench.tar.xz'

local benchmark = benchrun.new{
  name = 'darwin_benchmarks.osbench',
  version = 24,
  arg = arg,
  rusage = false, -- spawns child processes
}

benchmark:spawn{ '/usr/bin/tar', '-xf', osbench_tarball, '-C', tmpdir }

local score_unit = benchmark:assert(perfdata.unit.custom('score'),
    'failed to get score unit')

local args = {
  tmpdir .. '/osbench/run_osbench.sh', '--outFile', jsonfile;
  echo = true
}

for out in benchmark:run(args) do
  local total, n = 0, 0
  local file = assert(io.open(jsonfile, 'r'),
    'failed to open JSON output file')
  local json = file:read('*a')
  local data, err = cjson.decode(json)
  benchmark:assert(data, 'failed to parse JSON output: %s', err)
  file:close()

  for name, v in pairs(data) do
    if name ~= '__metadata' then
      benchmark.writer:add_value(name, perfdata.unit.ms, v['Milliseconds'],
        { iterations = v['Iterations'] })
        total = total + math.log(1000 / v['Milliseconds'])
        n = n + 1
      end
  end
  benchmark.writer:add_value('total', score_unit, math.exp(total / n), {
    [perfdata.larger_better] = true;
    perfdata.tags.summary,
  })
end

benchmark.writer:set_primary_metric('total')
benchmark:finish()