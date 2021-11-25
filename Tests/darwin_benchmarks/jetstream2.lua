#!/usr/local/bin/recon

local benchrun = require 'benchrun'
local lfs = require 'lfs'
local perfdata = require 'perfdata'
local proc = require 'proc'

require 'strict'

local JETSTREAM_TARBALL = './jetstream2.tar.xz'

local assetdir = os.getenv('DT_ASSETS') or lfs.currentdir()


local benchmark = benchrun.new{
  name = 'darwin_benchmarks.jetstream2',
  -- SVN checkout version
  version = 237263,
  arg = arg,
}

benchmark:assert(lfs.chdir(assetdir),
    'failed to change directory to asset directory')
benchmark:spawn{ '/usr/bin/tar', 'xf', JETSTREAM_TARBALL; echo = true }
benchmark:assert(lfs.chdir(assetdir .. '/JS2'),
    'failed to change directory to JS2')

local args = { '/usr/local/bin/jsc', './cli.js'; echo = true }
local unit_score = perfdata.unit.custom('score')

for out in benchmark:run(args) do
  local _, pos, name = out:find('Running (%g+):')
  while pos ~= nil do
    local _, next, next_name = out:find('Running (%g+):', pos)

    local scorepos, _, score = out:find('Score: (%S+)', pos)
    benchmark:assert(scorepos, 'failed to find score in JetStream2 output')
    if scorepos and (not next or scorepos < next) then
      benchmark.writer:add_value(name, perfdata.unit.custom('score'),
          tonumber(score))
    end

    name = next_name
    pos = next
  end

  local score = benchmark:assert(out:match('Total Score:%s+(%S+)'),
      'failed to find total score in output')
  benchmark.writer:add_value('total', unit_score, tonumber(score), {
    [perfdata.larger_better] = true;
    perfdata.tags.summary,
  })
end

benchmark.writer:set_primary_metric('total')
benchmark:finish()
