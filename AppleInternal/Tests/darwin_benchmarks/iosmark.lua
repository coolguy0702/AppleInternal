#!/usr/local/bin/recon

local benchrun = require 'benchrun'
local cjson = require 'cjson'
local perfdata = require 'perfdata'
local proc = require 'proc'
require 'strict'

local score_unit = perfdata.unit.custom('score')
local speedup_unit = perfdata.unit.custom('speedup')

local assetdir = os.getenv('DT_ASSETS') or '.'
local tmpdir = os.getenv('TMPDIR') or '/tmp'

local iosmark_tarball = assetdir .. '/iOSMark.tar.xz'

local IOSMARK_BIN = tmpdir .. '/iOSMark/runWkld.pl'
local JSON_FILE = 'iosmark.json'

local args = {
  IOSMARK_BIN, '-force_score', '-json', '-jname', JSON_FILE, '-outdir', tmpdir;
  echo = true
}

local benchmark = benchrun.new{'iosmark',
  name='darwin_benchmarks.iosmark',
  version = 3201,
  arg = arg,
  -- iOSMark spawns child processes, so automatic resource usage collection
  -- won't work properly.
  rusage = false,
}

local tar_args = {
  '/usr/bin/tar', '-xf', iosmark_tarball, '-C', tmpdir
}
local _, _, status, code = proc.run(tar_args)
benchmark:assert(status == 'exit', 'tar %sed: %d', status, code or 0)
benchmark:assert(code == 0, 'tar exited with code %d', code)

local jsonpath = tmpdir .. '/' .. JSON_FILE

for _ in benchmark:run(args) do
  local iosmarkfile, iosmarkjson, iosmarkdata, err

  iosmarkfile, err = io.open(jsonpath)
  benchmark:assert(iosmarkfile, 'failed to open output file: %s', err)
  iosmarkjson, err = iosmarkfile:read('all')
  benchmark:assert(iosmarkjson, 'failed to read output file: %s', err)
  iosmarkfile:close()

  iosmarkdata, err = cjson.decode(iosmarkjson)
  benchmark:assert(iosmarkdata, 'failed to parse JSON output: %s', err)

  local scores = benchmark:assert(iosmarkdata['scores'],
      'missing scores field in JSON')
  for score_name, score_value in pairs(scores) do
    benchmark.writer:add_value(score_name, score_unit, score_value, {
      [perfdata.larger_better] = true;
      perfdata.tags.summary,
    })
  end

  local workloads = benchmark:assert(iosmarkdata['workloads'],
      'missing workloads field in JSON')

  for _, workload in ipairs(workloads) do
    local speedup = workload['speedups'][1]
    benchmark.writer:add_value(workload['name'], speedup_unit, speedup, {
      category = workload['category'],
      sub_category = workload['sub_category'],
      [perfdata.larger_better] = true,
    })
  end
end

benchmark:finish()
