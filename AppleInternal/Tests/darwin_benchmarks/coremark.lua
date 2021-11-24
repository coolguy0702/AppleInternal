#!/usr/local/bin/recon

local benchrun = require 'benchrun'
local perfdata = require 'perfdata'

require 'strict'

local assetdir = os.getenv("DT_ASSETS") or './'
local BENCHMARK_BIN = ('%s/%s'):format(assetdir, 'coremark')

local SEEDS = {'0x0', '0x0', '0x66'}
local ITERATIONS = 400000
local EXECS = 7
local MALLOC_SIZE = 2000

local benchmark = benchrun.new{'coremark',
  name = 'darwin_benchmarks.coremark',
  version = 1,
  arg = arg,
}

local args = {
	BENCHMARK_BIN, SEEDS[1], SEEDS[2], SEEDS[3] , ITERATIONS, EXECS, '1',
		MALLOC_SIZE;
	echo=true
}

local unit = perfdata.unit.custom('iterations/sec')

for out in benchmark:run(args) do
  local iterations = out:match('Iterations/Sec%s+:%s+(%d+.?%d+)')
  benchmark:assert(iterations,
			'failed to parse iterations-per-second from coremark output')

  benchmark.writer:add_value('score', unit, iterations,
      { [perfdata.larger_better] = true; perfdata.tags.summary })
end
benchmark.writer:set_primary_metric('score')

benchmark:finish()
