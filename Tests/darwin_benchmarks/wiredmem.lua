#!/usr/local/bin/recon

local argparse = require 'argparse'
local darwin = require 'darwin'
local lfs = require 'lfs'
local perfdata = require 'perfdata'
local proc = require 'proc'
local zprint = require 'zprint'

require 'strict' -- forbid non-local variables

local WIRED_SIZE_METRIC = 'wired_size'
-- How often to check the load average when quiescing the device.
local LOAD_CHECK_SECS = 5
local TMPDIR = os.getenv('TMPDIR') or '/tmp'
local PDNAME_PREFIX = 'darwin_benchmarks.wiredmem'

local function xassert(cond, fmt, ...)
  if cond then
    return cond
  end
  io.stderr:write('error: ', fmt:format(...), '\n')
  os.exit(1)
end

-- Get a file name in `dir` starting with `basename` in a standard format.
local function numeric_filename(dir, basename, num, ext)
  return ('%s/%s.%03d%s'):format(dir, basename, num, ext or '')
end

-- Find an unused filename in the directory `dir` starting with `basename` and
-- ending in `ext`.
local function find_next_filename(dir, basename, ext)
  for i = 1, 999 do
    local filename = numeric_filename(dir, basename, i, ext)
    if not lfs.attributes(filename, 'mode') then
      return filename
    end
  end
end

-- Parse zprint output `zpout` and write measurements to the perfdata `writer`.
local function zprint_to_perfdata(zpout, writer)
  for zone in zprint.zones(zpout) do
    local vars = { name = zone.name, type = 'zone' }
    -- The allocated size of the zone -- how much memory this zone is costing
    -- the system.
    writer:add_value('size', perfdata.unit.bytes, zone.size, vars)

    -- The size used for allocated objects in the zone.
    writer:add_value('used_size', perfdata.unit.bytes, zone.used_size, vars)
  end

  for tag in zprint.tags(zpout) do
    local vars = { name = tag.name, type = 'tag' }
    -- Sum of the sizes for each object allocated using the tag.
    writer:add_value('size', perfdata.unit.bytes, tag.size, vars)
  end
  for map in zprint.maps(zpout) do
    local vars = { name = map.name, type = 'map' }
    -- The current size of this map (or counter)
    writer:add_value('size', perfdata.unit.bytes, map.size, vars)
  end

  -- The total amount of wired memory as measured by zprint is the primary
  -- metric of this test.
  writer:add_value(WIRED_SIZE_METRIC, perfdata.unit.bytes, zprint.total(zpout))
  writer:set_primary_metric(WIRED_SIZE_METRIC)
end

-- Count the number of occurences of the pattern `ptn` in string `str`.
local function count_matches(str, ptn)
  -- Lua lacks a way to count occurrences of a substring. string.gsub returns
  -- the number of substitutions made as its second argument.  Use select to
  -- prevent the resulting string from being created (and counting as garbage).
  return select(2, str:gsub(ptn, ''))
end

-- Write the number of processes from ps output `psout` to the perfdata
-- `writer`.
local function ps_to_perfdata(psout, writer)
  local nprocs = count_matches(psout, '\n') - 1 -- header
  writer:add_value('processes', perfdata.unit.custom('count'), nprocs)
end

-- Write the number of threads from `taskinfo --threads` output `tsout` to the
-- perfdata `writer`.
local function taskinfo_to_perfdata(tsout, writer)
  local nthreads = count_matches(tsout, 'thread ID:')
  writer:add_value('threads', perfdata.unit.custom('count'), nthreads)
end

local parser = argparse(arg[0], 'Report wired memory as perfdata')

-- Common options for dealing with how to output perfdata.
local function add_output_options(parser)
  local out_opt = parser:option{
    name = '-o --output-dir',
    description = 'the directory to write perfdata to',
    default = '.',
  }
  local tmp_opt = parser:flag{
    name = '--tmp',
    description = 'write output to the temporary directory',
  }
  parser:mutex(out_opt, tmp_opt)
end

-- These tasks describe how to collect data and convert it into perfdata.
local DATA_COMMANDS = {
  { name = 'zprint', command = { 'zprint' }, convert = zprint_to_perfdata, },
  { name = 'ps', command = { 'ps', '-cA' }, convert = ps_to_perfdata, },
  {
    name = 'taskinfo', command = { 'taskinfo', '--threads' },
    convert = taskinfo_to_perfdata,
    ignore_failures = true, -- taskinfo(1) not present on all platforms
  },
}

-- Run the command and return its output.  Ensure the tool exits cleanly.
local function run_command(command)
  local out, err, status, exit_code = proc.run(command.command)
  if not out then
    return nil, ('failed to run %s: %s'):format(command.name, err)
  end
  if exit_code ~= 0 then
    return nil, ('%s exited with %d, stderr: %s'):format(command.name,
        exit_code, err)
  end
  return out
end

-- Get the boot task's output path, given a command.
local function command_boot_outpath(command)
  return '/tmp/' .. command.name .. '-boot.txt'
end

-- SETUP
--
-- Prepare the system to sample wired memory metrics as a boot task on
-- subsequent boots.

-- Where launchd expects the scratch boot task.
local SCRATCH_BOOT_TASK_PATH =
    '/private/var/db/com.apple.xpc.launchd/scratch-boot-task'

local setup = parser:command('setup',
    'ensure that the next boot runs a boot task to measure wired memory')
setup:flag{
  name = '-r --reboot',
  description = 'reboot the device after setup',
}
setup:action(function (opt)
  -- Construct the script to run as a boot task.
  --
  -- Continuosly appending strings creates a lot of garbage -- concatenate all
  -- lines together at once using a table.
  local boot_script_t = { '#!/bin/sh' }
  for _, cmd in ipairs(DATA_COMMANDS) do
    -- XXX No spaces in the arguments allowed.
    local cmd_str = table.concat(cmd.command, ' ')
    table.insert(boot_script_t,
        ('%s > %s'):format(cmd_str, command_boot_outpath(cmd)))
  end
  local boot_script = table.concat(boot_script_t, '\n')

  local boottask_file = assert(io.open(SCRATCH_BOOT_TASK_PATH, 'w'),
      'failed to open scratch boot task file')
  boottask_file:write(boot_script)
  boottask_file:close()

  assert(proc.run{ 'chmod', '+x', SCRATCH_BOOT_TASK_PATH },
      'failed to make scratch boot task executable')

  print('installed boot task')
  if opt.reboot then
    print('rebooting')
    proc.run{ 'reboot' }
  end
end)

-- RECORD
--
-- Record the system's wired memory as perfdata, optionally after the system
-- has quiesced.

local record = parser:command('record', 'record wired memory as perfdata')
add_output_options(record)

-- `--wait` allows all tasks that trigger off the boot notification to have had
-- a chance to run.  Otherwise, the quiesce check might see no load because the
-- system hasn't had a chance to run handlers for the boot notification.
--
-- FIXME This should be changed to block until the booted notification appears,
-- instead of a time-based heuristic.
record:option{
  name = '--wait',
  description = 'only start to quiesce the system after this many seconds',
  default = 0,
  convert = tonumber,
}
record:option{
  name = '--load-threshold',
  description = 'quiesce by ensuring the 1-minute load average is below this',
  default = 0,
  convert = tonumber,
}
record:option{
  name = '--timeout',
  description = 'timeout if unable to quiesce for this many seconds',
  default = 0,
  convert = tonumber,
}
record:flag{
  name = '--boot-task',
  description = 'collect data from the boot task',
}

record:action(function (opt)
  xassert(darwin.geteuid() == 0, 'zprint requires root privileges')

  if opt.tmp then
    opt.output_dir = TMPDIR
  end

  if opt.wait > 0 then
    print(('sleeping %ss before starting to quiesce'):format(opt.wait))
    darwin.sleep(opt.wait)
  end

  if opt.load_threshold > 0 then
    print(('waiting %d seconds for 1-minute load average to reach %d'):format(
        opt.timeout, opt.load_threshold))
    local timeout_secs = opt.timeout
    local quiesced = false
    -- Every LOAD_CHECK_SECS seconds, get the 1-minute load average to see if it
    -- dropped below the threshold.
    for i = 0, timeout_secs, LOAD_CHECK_SECS do
      local load = darwin.getloadavg()
      print(('after %ds: %g'):format(i, load))

      if load < opt.load_threshold then
        quiesced = true
        break
      end

      darwin.sleep(LOAD_CHECK_SECS)
    end
    print(('device has%s quiesced'):format(quiesced and '' or ' not'))
  end

  -- Get the load average just before running commands, to align it more
  -- closely.
  local load1min, load5min, load15min = darwin.getloadavg()

  if opt.boot_task then
    xassert(lfs.attributes(SCRATCH_BOOT_TASK_PATH, 'mode'),
        'boot task is missing, must run setup and reboot')
    print('removing scratch boot task')
    proc.run{ 'rm', SCRATCH_BOOT_TASK_PATH } -- best effort

    -- Make sure the files created by the boot task exist before creating a
    -- perfdata writer, to prevent empty perfdata files.
    for _, cmd in ipairs(DATA_COMMANDS) do
      local out_file = xassert(io.open(command_boot_outpath(cmd), 'r'),
          'missing boot task output for ' .. cmd.name)
      cmd.out = out_file:read('*a')
      out_file:close()
    end

    if opt.tmp then
      opt.output_dir = TMPDIR
    end

    local outpath = find_next_filename(opt.output_dir, 'wiredmem_boot_task',
        '.pdj')
    print('converting boot task output to perfdata at', outpath)
    local wr = xassert(perfdata.Writer.new(outpath,
        PDNAME_PREFIX .. '.boot_task', 0),
        'failed to create perfdata writer')
    wr:set_description(
        'This test measures wired memory just after all boot tasks.')

    for _, cmd in ipairs(DATA_COMMANDS) do
      cmd.convert(cmd.out, wr)
    end

    wr:close()
  else
    for _, cmd in ipairs(DATA_COMMANDS) do
      -- Don't convert the output right away -- these commands should be captured
      -- close together.
      local out, err = run_command(cmd)
      if not out then
        if not cmd.ignore_failures then
          error(err)
        end
      end
      cmd.out = out
    end
  end

  local outpath = find_next_filename(opt.output_dir, 'wiredmem', '.pdj')
  print('converted zprint to perfdata at', outpath)
  local wr = xassert(perfdata.Writer.new(outpath, PDNAME_PREFIX .. '.boot', 0),
      'failed to create perfdata writer at %s', outpath)
  wr:set_description(
      'This test lets the system quiesce and then measures wired memory.')

  for _, cmd in ipairs(DATA_COMMANDS) do
    if cmd.out then
      cmd.convert(cmd.out, wr)
    end
  end

  local loadavg_unit = perfdata.unit.custom('loadavg')
  wr:add_value('load_1min', loadavg_unit, load1min)
  wr:add_value('load_5min', loadavg_unit, load5min)
  wr:add_value('load_15min', loadavg_unit, load15min)

  wr:close()
end)

-- ELEMENTS
--
-- Print the size of elements in each zone.  This is static for each build, so
-- trace it separately from the dynamic measurements.

local elements = parser:command('elements',
    'produce perfdata containing the element size of each zone')
add_output_options(elements)
elements:action(function (opt)
  xassert(darwin.geteuid() == 0, 'running zprint requires root privileges')

  if opt.tmp then
    opt.output_dir = TMPDIR
  end

  local outpath = find_next_filename(opt.output_dir, 'wiredmem_elements',
      '.pdj')
  print('converting zone element sizes to perfdata at', outpath)
  local wr = xassert(perfdata.Writer.new(outpath,
      'darwin_benchmarks.wiredmem.zone_elts', 0),
      'failed to create perfdata writer at %s', outpath)
  wr:set_description('This test measures the element size of each zone.')

  local zpout = run_command{ name = 'zprint', command = { 'zprint' } }

  for zone in zprint.zones(zpout) do
    wr:add_value('elt_size', perfdata.units.bytes, zone.element_size,
        { name = zone.name })
  end

  wr:close()
end)

-- CONVERT
--
-- Utility subcommand to convert zprint output to perfdata.

local convert = parser:command('convert',
    'convert zprint text output to perfdata')
convert:option{
  name = '-n --name',
  description = 'the name of the perfdata file',
  count = 1,
}
convert:option{
  name = '--version',
  description = 'the version of the perfdata file',
  convert = tonumber,
  count = 1,
}
convert:option{
  name = '-i --input',
  description = 'path to zprint output to convert, or - if on stdin',
  count = '?',
}
convert:option{
  name = '-o --output',
  description = 'path to write the perfdata file',
  count = 1,
}
convert:action(function (opt)
  local zpout = nil

  if opt.input then
    local infile = nil
    if opt.input == '-' then
      print('reading zprint from stdin')
      infile = io.stdin
    elseif opt.input then
      print(('reading zprint from %s'):format(opt.input))
      local err
      infile, err = io.open(opt.input, 'r')
      if not infile then
        io.stderr:write('failed to open ', opt.input, ': ', err, '\n')
        os.exit(1)
      end
    end
    zpout = infile:read('*a')
    infile:close()
  else
    xassert(darwin.geteuid() == 0, 'running zprint requires root privileges')
    zpout = run_command{ name = 'zprint', command = { 'zprint' } }
  end

  local wr = assert(perfdata.Writer.new(opt.output, opt.name, opt.version),
      'failed to create perfdata writer')
  zprint_to_perfdata(zpout, wr)
  wr:close()
end)

parser:parse(arg)
