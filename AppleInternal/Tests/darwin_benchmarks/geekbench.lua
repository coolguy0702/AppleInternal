#!/usr/local/bin/recon

local benchrun = require 'benchrun'
local cjson = require 'cjson.safe'
local perfdata = require 'perfdata'
local sysctl = require 'sysctl'
require 'strict'

local GB4_VERSION = 43002
local GB5_VERSION = 50000

local GEEKBENCH_BIN = {
  [GB4_VERSION] = 'geekbench',
  [GB5_VERSION] = 'geekbench5'
}

local assetdir = os.getenv('DT_ASSETS') or arg[0]:gsub('[^/]*$', '')
local tmpdir = os.getenv('TMPDIR') or '/tmp/'

local GB_EMAIL = 'geekbench@apple.com'
local GB_KEY = {
  [GB4_VERSION] = 'W5RFK-H5BDA-UELLY-7IZUL-CSAHC-DW7SK-YABCO-XELKE-32AH4',
  [GB5_VERSION] = 'PVLIJ-QDB3D-C24I2-5SDAX-KK3KG-NVFYT-XF55O-7EAAL-FXQFE'
}

-- Map workload names to their internal IDs, limited to the workloads during a
-- normal run.
--
-- From src/geekbench/workload_id.h and last updated for Geekbench 4.3 and 5.0.
local WORKLOADS = {
  [GB4_VERSION] = {
    aes = 101,
    lzma = 201,
    jpeg = 202,
    canny = 204,
    lua = 205,
    dijkstra = 206,
    sqlite = 207,
    html5_parse = 208,
    html5_dom = 209,
    histogram_equalization = 210,
    pdf_rendering = 211,
    llvm = 212,
    camera = 213,
    sgemm = 301,
    sfft = 302,
    nbody = 303,
    raytrace = 304,
    rigid_body = 305,
    hdr = 306,
    gaussian_blur = 307,
    speech_recognition = 308,
    face_detection = 309,
    memory_copy = 401,
    memory_latency = 402,
    memory_bandwidth = 403
  },
  [GB5_VERSION] = {
    aes_xts = 101,
    text_compression = 201,
    image_compression = 202,
    navigation = 203,
    html5 = 204,
    sqlite = 205,
    pdf_rendering = 206,
    text_rendering = 207,
    clang = 208,
    camera = 209,
    nbody = 301,
    rigid_body = 302,
    gaussian_blur = 303,
    face_detection = 305,
    horizon_detection = 306,
    image_inpainting = 307,
    hdr = 308,
    ray_tracing = 309,
    structure_from_motion = 310,
    speech_recognition = 312,
    machine_learning = 313
  }
}

local function workload_list(version)
  local workloads = {}
  for k, _ in pairs(WORKLOADS[version]) do
    table.insert(workloads, k)
  end
  table.sort(workloads)
  return table.concat(workloads, ',')
end

function run_geekbench(version)
  local benchmark_bin = assetdir .. '/' .. GEEKBENCH_BIN[version]

  local benchmark = benchrun.new{
    name = 'darwin_benchmarks.geekbench',
    version = version,
    arg = arg,
    modify_argparser = function(parser)
      parser:option{
        name = '--path',
        description = 'path to Geekbench binary',
        default = benchmark_bin
      }
      parser:flag{
        name = '--through-max-workers',
        description = 'run Geekbench for [1..n] cpu workers'
      }
      parser:option{
        name = '--cpu-workers',
        description = 'maximum number of cpu workers'
      }
      parser:option{
        name = '--workload',
        description = ([[
Only run the specified workload.  Needs to be run with -4 or -5.

Valid workloads for -4 are:
\t%s

Valid workloads for -5 are:
\t%s]]):format(workload_list(GB4_VERSION), workload_list(GB5_VERSION)),
      }
      parser:flag{
        name = '-4',
        description = 'run Geekbench 4',
      }
      parser:flag{
        name = '-5',
        description = 'run Geekbench 5 (default)'
      }
      parser:mutex(
        parser:flag{
          name = '--single-core',
          description = 'run only single-core CPU workloads'
        },
        parser:flag{
          name = '--multi-core',
          description = 'run only multi-core CPU workloads'
        }
      )
    end
  }

  local cpu_workers = benchmark.opt.cpu_workers
  if not cpu_workers then
    local ncpus, err = sysctl('hw.logicalcpu_max')
    benchmark:assert(ncpus, 'sysctl("hw.logicalcpu_max") failed: %s', err)
    benchmark:assert(ncpus > 0, 'invalid number of logical CPUs')
    cpu_workers = ncpus
  end

  local jsonpath = ('%s/geekbench_output_%s.json'):format(tmpdir, version)
  local tests = {}

  if not benchmark.opt.multi_core then
    table.insert(tests, { '--single-core'; name = 'single-core' })
  end
  if not benchmark.opt.single_core then
    table.insert(tests, {
      '--multi-core', '--cpu-workers', cpu_workers;
      name = 'multi-core',
    })
  end

  if benchmark.opt.through_max_workers then
    for i = 2, cpu_workers - 1 do
      table.insert(tests, {
        '--multi-core', '--cpu-workers', i;
        name = 'multi-core',
      })
    end
  end

  local workload = benchmark.opt.workload
  if workload then
    if benchmark.opt['4'] and benchmark.opt['5'] then
      benchmark:error('cannot specify -4, -5, and --workload together')
    end

    local workload_id = WORKLOADS[version][workload]
    benchmark:assert(workload_id, 'unknown workload: %s', workload)
    for _, test in pairs(tests) do
      table.insert(test, '--workload')
      table.insert(test, workload_id)
    end
  end

  -- Geekbench must be unlocked before it allows itself to run.
  benchmark:spawn{ benchmark.opt.path, '--unlock', GB_EMAIL, GB_KEY[version] }

  for _, test in ipairs(tests) do
    local args = {
      benchmark.opt.path, '--export-json', jsonpath;
      echo = true, name = test.name,
    }
    for _, v in ipairs(test) do
      table.insert(args, v)
    end

    for _ in benchmark:run(args) do
      local gbfile, err = io.open(jsonpath)
      benchmark:assert(gbfile, '%s: failed to open file: %s', jsonpath, err)
      local gbjson = gbfile:read('all')
      benchmark:assert(gbjson and #gbjson > 0, 'JSON output missing')
      local gbdata
      gbdata, err = cjson.decode(gbjson)
      benchmark:assert(gbdata, 'failed to parse JSON output: %s', err)
      gbfile:close()

      local workloads
      local nthreads
      if gbdata['sections'] then
        local section = benchmark:assert(gbdata['sections'][1],
            'missing section field in JSON')

        workloads = benchmark:assert(section['workloads'],
            'missing workloads field in JSON')

        -- Some Geekbench workloads have a ceiling on the number of threads they
        -- run on: use the maximum value for the total score.
        nthreads = 1
        for _, workload in ipairs(workloads) do
          if workload['threads'] > nthreads then
            nthreads = workload['threads']
          end
        end

        benchmark.writer:add_value('total', perfdata.unit.custom('score'),
          section['score'], {
            [perfdata.larger_better] = true,
            test = test.name,
            threads = nthreads;
            perfdata.tags.summary,
          })
      else
        local workload = benchmark:assert(gbdata['workload'],
            'missing workload field in JSON')
        workloads = { workload }
        nthreads = workload['threads']
      end

      benchmark:assert(workloads, 'workloads variable not set')
      benchmark:assert(nthreads, 'number of threads was not set')
      local variables = {
        [perfdata.larger_better] = true,
        test = test.name,
        threads = nthreads,
      }
      for _, workload in ipairs(workloads) do
        benchmark.writer:add_value(workload['name'],
            perfdata.unit.custom('score'), workload['score'], variables)
      end
    end
  end

  local primary = (benchmark.opt.single_core and 'single-core') or 'multi-core'
  benchmark.writer:set_primary_metric('total,test=' .. primary)

  benchmark:finish()
end

-- Run all requested versions of Geekbench.

local VERSION_ARGS = { ['-4'] = GB4_VERSION, ['-5'] = GB5_VERSION, }

local ran = false
for _, a in ipairs(arg) do
  if VERSION_ARGS[a] then
    run_geekbench(VERSION_ARGS[a])
    ran = true
  end
end
if ran then
  os.exit(0)
end

-- Run Geekbench 5 if no option is given explicitly.
run_geekbench(GB5_VERSION)

