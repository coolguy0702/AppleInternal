#!/usr/local/bin/recon

local csv = require 'csv'
local benchrun = require 'benchrun'
local lfs = require 'lfs'
local perfdata = require 'perfdata'

require 'strict'

local assetdir = os.getenv("DT_ASSETS") or './'

local BENCHMARK_BIN = ('%s/%s'):format(assetdir, 'redis-benchmark')
local CLI_BIN = ('%s/%s'):format(assetdir, 'redis-cli')
local SERVER_BIN = ('%s/%s'):format(assetdir, 'redis-server')

local benchmark = benchrun.new{
  name = 'darwin_benchmarks.redis',
  version = 5,
  arg = arg,
  rusage = false, -- spawns child processes
}

local changed, err = lfs.chdir(assetdir)
benchmark:assert(changed, 'failed to change directory: %s', err)

local serverf
serverf, err = io.popen(SERVER_BIN, 'w')
benchmark:assert(serverf, 'failed to launch %s: %s', SERVER_BIN, err)

local args = { BENCHMARK_BIN, '--csv' }

local unit = perfdata.unit.custom('requests/sec')

for out in benchmark:run(args) do
  local data = csv.openstring(out)
  local total, n = 0, 0

  for field in data:lines() do
    benchmark.writer:add_value(field[1], unit, field[2], {
      [perfdata.larger_better] = true
    })

    total = total + math.log(field[2])
    n = n + 1
  end
  benchmark.writer:add_value('total', unit, math.exp(total / n), {
    [perfdata.larger_better] = true;
    perfdata.tags.summary,
  })
end

benchmark.writer:set_primary_metric('total')

benchmark:spawn{ CLI_BIN, 'shutdown' }

benchmark:finish()

serverf:close()
