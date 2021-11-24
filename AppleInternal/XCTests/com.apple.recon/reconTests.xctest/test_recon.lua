local ste = xctest.suite

require 'strict'

local function xassert(test, check, fmt, ...)
  if check then
    return check
  end

  local info = debug.getinfo(2, 'l')
  test:record_failure(fmt:format(...), xctest.sourcefile, info.currentline)
end

-- test the darwin library

local darwin = require 'darwin'

ste:case('darwin.dlsym', function (t)
  local addr = darwin.dlsym('luaopen_darwin')
  t:assert(addr, 'valid address of luaopen_darwin')
end)

ste:case('darwin.getloadavg', function (t)
  local one, five, fifteen = darwin.getloadavg()
  t:assert(type(one) == 'number', '1-minute load average is a number')
  t:assert(type(five) == 'number', '5-minute load average is a number')
  t:assert(type(fifteen) == 'number', '15-minute load average is a number')
end)

ste:case('darwin.get{,e}uid', function (t)
  t:assert(darwin.geteuid() >= 0, 'geteuid is a non-negative number')
  t:assert(darwin.getuid() >= 0, 'getuid is a non-negative number')
end)

ste:case('darwin.get{,p}pid', function (t)
  t:assert(darwin.getpid() > 0, 'getpid is a positive number')
  t:assert(darwin.getppid() > 0, 'getppid is a positive number')
end)

ste:case('darwin.isatty', function (t)
  t:assert(type(darwin.isatty(io.stdin) == 'boolean'),
      'isatty returns a boolean')
end)

ste:case('darwin.sleep', function (t)
  local start = darwin.clock_gettime_nsec(darwin.CLOCK_MONOTONIC)
  darwin.sleep(1)
  local finish = darwin.clock_gettime_nsec(darwin.CLOCK_MONOTONIC)
  t:assert((finish - start) > (1 * 1000 * 1000 * 1000),
      'slept for at least 1 second')
end)

ste:case('darwin.{un,}setenv', function (t)
  local test_env = 'RECON_TEST_ENV'
  local test_val = 'testing'
  local bad_val = 'bad'
  local new_val = 'new'

  local val = os.getenv(test_env)
  t:assert(val == nil, 'test environment variable is unset to start with')

  t:assert(darwin.setenv(test_env, test_val))
  val = os.getenv(test_env)
  t:assert(val == test_val, 'environment variable was set')

  t:assert(darwin.setenv(test_env, bad_val))
  val = os.getenv(test_env)
  t:assert(val == test_val, 'environment variable was not overwritten')

  t:assert(darwin.setenv(test_env, new_val, true))
  val = os.getenv(test_env)
  t:assert(val == new_val,
      'environment variable was overwritten when requested')

  t:assert(darwin.unsetenv(test_env))
  val = os.getenv(test_env)
  t:assert(val == nil, 'test environment variable can be unset')
end)

ste:case('darwin.environ', function (t)
  local test_env = 'RECON_TEST_ENV'
  local test_val = 'testing'

  t:assert(darwin.setenv(test_env, test_val))

  local env = darwin.environ()
  t:assert(env, 'got environment')
  t:assert(env[test_env] == test_val, 'got newly-added environment variable')
end)

ste:case('darwin.statfs', function (t)
  local sbuf, err = darwin.statfs('/')
  t:assert(sbuf, ('failed to get status buffer for /: %s'):format(err))
  t:assert(sbuf.f_bsize > 0, 'valid block size')
end)

ste:case('darwin.basename', function (t)
  local path = '/my/long/path/name'
  t:assert(darwin.basename(path) == 'name', 'got correct basename')
end)

ste:case('darwin.dirname', function (t)
  local dir = '/my/long/path'
  local dname, err = darwin.dirname(dir .. '/name')
  t:assert(dname, 'dirname failed: ' .. (err or '???'))
  t:assert(dname == dir, 'incorrect dirname: ' .. dname)
end)

ste:case('darwin.host_statistics', function (t)
  local loadinfo = darwin.host_statistics(darwin.HOST_LOAD_INFO)
  t:assert(loadinfo.avenrun[1] > 0, '1-minute CPU load is non-zero')
  t:assert(loadinfo.avenrun[2] > 0, '5-minute CPU load is non-zero')
  t:assert(loadinfo.avenrun[3] > 0, '15-minute CPU load is non-zero')

  local cpuinfo = darwin.host_statistics(darwin.HOST_CPU_LOAD_INFO)
  t:assert(cpuinfo.cpu_ticks_idle > 0, 'CPU idle ticks is non-zero')
  t:assert(cpuinfo.cpu_ticks_user + cpuinfo.cpu_ticks_system > 0,
      'CPU non-idle ticks is non-zero')

  darwin.usleep(100e3)
  local cpuinfo_after = darwin.host_statistics(darwin.HOST_CPU_LOAD_INFO)
  local ticks = cpuinfo.cpu_ticks_idle + cpuinfo.cpu_ticks_user +
      cpuinfo.cpu_ticks_system
  local ticks_after = cpuinfo_after.cpu_ticks_idle +
      cpuinfo_after.cpu_ticks_user + cpuinfo_after.cpu_ticks_system
  t:assert(ticks_after > ticks, 'ticks are increasing')
end)

ste:case('darwin.realpath', function (t)
  local path = '/System/../System/../System/'
  local rpath, err = darwin.realpath(path)
  t:assert(rpath, 'realpath failed: ' .. (err or '???'))
  t:assert(rpath == '/System', 'incorrect realpath: ' .. rpath)
end)

-- darwin time functions

local function assert_increasing(t, name, timefn)
  local first = timefn()
  darwin.usleep(1000)
  local second = timefn()
  t:assert(second > first, name .. ' increases monotonically')
end

ste:case('darwin.clock_gettime_nsec', function (t)
  for k, v in pairs(darwin) do
    if k:match('CLOCK_') and k ~= 'CLOCK_REALTIME' then
      assert_increasing(t, k,
          function () return darwin.clock_gettime_nsec(v) end)
    end
  end
end)

for _, kind in pairs({ 'absolute', 'approximate', 'continuous' }) do
  local name = 'mach_' .. kind .. '_time'
  ste:case('darwin.' .. name,
      function (t) assert_increasing(t, name, darwin[name]) end)
end

ste:case('darwin.mach_timebase_info', function (t)
  local numer, denom = darwin.mach_timebase_info()
  print(('got timebase as %d / %d'):format(numer, denom))
  t:assert(numer ~= nil, 'numerator is valid')
  t:assert(denom ~= nil, 'denominator is valid')
end)

-- test the nvram library

local nvram = require 'nvram'

ste:case('nvram.variables', function (t)
  local vars = nvram.variables()
  t:assert(type(vars) == 'table', 'variables are an array')
  t:assert(#vars > 0, 'there are some variables')

  local has_bootargs = false
  for _, v in ipairs(vars) do
    if v == 'boot-args' then has_bootargs = true end
  end
  t:assert(has_bootargs, 'boot-args variable is present')
end)

ste:case('nvram.get', function (t)
  local bootargs = nvram['boot-args']
  t:assert(type(bootargs) == 'string', 'boot-args can be read')
end)

-- test the stackshot library

local stackshot = require 'stackshot'

ste:case('stackshot', function (t)
  local ss = t:assert(stackshot(), 'can take a stackshot')

  local ssflags = t:assert(stackshot{ flags = stackshot.NO_IO_STATS },
      'can take a stackshot with flags')

  local sssize = t:assert(stackshot{ size_hint = 1000 * 1000 * 2 },
      'can take a stackshot with size hint')

  local sspid = t:assert(stackshot{ pid = 1 }, 'can take a stackshot with pid')
end)

-- test the kcdata library

local kcdata = require 'kcdata'

ste:case('kcdata', function (t)
  local ss = t:assert(stackshot(), 'can take a stackshot')
  local sstbl = t:assert(kcdata.decode(ss), 'can decode stackshot')
  t:assert(type(sstbl) == 'table', 'kcdata decode returns a table')
end)

-- test the uuid library

local uuid = require 'uuid'

ste:case('uuid', function (t)
  local id = uuid()
  t:assert(id, 'uuid can be generated')

  local idstr = uuid.unparse(id)
  t:assert(idstr, 'uuid can be unparsed')
  t:assert(type(idstr) == 'string', 'unparsed uuid is a string')

  local roundtripid = uuid.parse(idstr)
  t:assert(id == roundtripid,
      'uuid can be round-tripped through parse and unparse')

  local idstr_lower = uuid.unparse(id, 'lower')
  t:assert(not idstr_lower:match('[A-Z]'),
      'has no upper-case letters when unparsing to lower-case')
  local idstr_upper = uuid.unparse(id, 'upper')
  t:assert(not idstr_upper:match('[a-z]'),
      'has no lower-case letters when unparsing to upper-case')
end)

-- test the sysctl library

local sysctl = require 'sysctl'

local function check_names(t, desc, names, expected_name, unexpected_name)
  t:assert(type(names) == 'table', desc .. ' of sysctls returned')
  t:assert(#names > 0, 'there are some sysctl ' .. desc)

  local found_expected = false
  local found_unexpected = false
  for _, n in ipairs(names) do
    if n == expected_name then found_expected = true end
    if n == unexpected_name then found_unexpected = true end
  end

  t:assert(found_expected, 'found ' .. expected_name .. ' in sysctl ' .. desc)

  if unexpected_name then
    t:assert(not found_unexpected,
        'did not find ' .. unexpected_name .. ' in sysctl ' .. desc)
  end
end

ste:case('sysctl.names', function (t)
  check_names(t, 'names', sysctl.names(), 'kern.bootargs')
  check_names(t, 'hw names', sysctl.names('hw'), 'hw.ncpu')

  t:assert(sysctl.names('NONEXISTENT') == nil,
      'non-existent sysctl names are nil')
end)

ste:case('sysctl', function (t)
  local ncpu = sysctl('hw.ncpu')
  t:assert(type(ncpu) == 'number', 'hw.ncpu is a number')
  t:assert(ncpu > 0, 'hw.ncpu is non-zero')

  local bootargs = sysctl('kern.bootargs')
  t:assert(type(bootargs) == 'string', 'kern.bootargs is a string')

  local nonexistent = sysctl('NONEXISTENT')
  t:assert(nonexistent == nil, 'non-existent sysctl is nil')

  -- TODO find a sysctl that can be set by any user
end)

-- test the plist library

local plist = require 'plist'

ste:case('plist', function (t)
  local tbl = {
    test = 42, arr = { 1, 2, 3, 4, 5 }, bool = true,
    nest = { another = { test = 21 } },
  }

  local xmlpl = t:assert(plist.encode(tbl, 'xml'), 'xml plist can be encoded')
  local binpl = t:assert(plist.encode(tbl, 'binary'),
      'binary plist can be encoded')

  local xmltbl = t:assert(plist.decode(xmlpl), 'xml plist can be decoded')
  local bintbl = t:assert(plist.decode(binpl), 'binary plist can be decoded')

  for k, v in pairs(xmltbl) do
    if type(v) == 'table' then
      if #v > 0 then
        t:assert(#v == #bintbl[k],
            'xml key ' .. k .. ' has same length as binary plist')
        for i, inv in ipairs(v) do
          t:assert(inv == bintbl[k][i],
            'xml key ' .. k .. '[' .. i .. '] matches binary plist')
        end
      else
        for ink, inv in pairs(v) do
          if type(inv) ~= 'table' then
            t:assert(inv == bintbl[k][ink],
                'xml key ' .. k .. '.' .. ink .. ' matches binary plist')
          end
        end
      end
    else
      t:assert(v == bintbl[k], 'xml key ' .. k .. ' matches binary plist')
    end
  end
end)

-- test the proc library

local proc = require 'proc'

ste:case('proc.run', function (t)
  local out, err, status, code, rusage = proc.run{ 'ls', '-al', rusage = true }
  t:assert(out, 'can run ls')
  t:assert(type(status) == 'string', 'status is a string')
  t:assert(code == 0, 'ls exited successfully')
  t:assert(type(out) == 'string', 'ls output is a string')
  t:assert(type(rusage) == 'table', 'rusage is a table')
  t:assert(type(rusage.nivcsw) == 'number', 'nivcsw exists in rusage')
  t:assert(type(rusage.instructions) == 'number',
      'instructions exists in rusage')

  out, err = proc.run{ 'env', environ = { rec = 'val'; 'seq=also' } }
  t:assert(out:match('rec=val'), 'record variable found in environment')
  t:assert(out:match('seq=also'), 'sequence variable found in environment')
end)

ste:case('proc', function (t)
  local launchd = t:assert(proc.Process.new(darwin.getpid()))
  local curproc = t:assert(proc.Process.new('xctest'))
  t:assert(type(curproc:get_rusage()) == 'table', 'get_rusage returns a table')
end)

-- test the CoreSymbolication library

local CoreSymbolication = require 'CoreSymbolication'

ste:case('CoreSymbolication.own_symbol', function (t)
  local symbolicator, err =
      CoreSymbolication.Symbolicator.new(darwin.getpid())
  xassert(t, symbolicator,
      'failed to create symbolicator for current process', err)

  local addr = darwin.dlsym('luaopen_CoreSymbolication')
  local symbol = symbolicator:symbolicate(addr)
  for _, field in ipairs{
      'name', 'owner_name', 'owner_path', 'owner_uuid', } do
    t:assert(symbol[field], field .. ' of symbol is present')
  end
end)

-- test the ktrace library

local ktrace = require 'ktrace'

ste:case('ktrace.Session.new', function (t)
  local ktsession, err = ktrace.Session.new()
  t:assert(ktsession, 'created a ktrace session')
end)

-- test the kperf library

local kperf = require 'kperf'

ste:case('kperf.Session.new', function (t)
  local ktsession, err = ktrace.Session.new()
  t:assert(ktsession, 'created a ktrace session')

  local kpsession, err = kperf.Session.new(ktsession)
  t:assert(kpsession, 'created a kperf session')
end)

-- test the CommonCrypto library

local CommonCrypto = require 'CommonCrypto'

ste:case('CommonCrypto.HMAC.new', function (t)
  local hmac, err = CommonCrypto.HMAC.new('sha256', 'key')
  t:assert(hmac, 'created SHA256 HMAC')
end)

-- test the term library

local term = require 'term'

ste:case('term.colors', function (t)
  local vt = term.Terminal.new(io.stdout)
  t:assert(vt, 'created Terminal')
  local bluetext = vt:blue('this should be blue').bg
  t:assert(type(tostring(bluetext)) == 'string', 'can create strings')
end)

-- test the perfdata library

local perfdata = require 'perfdata'

ste:case('perfdata.tags', function (t)
  local wr, path = perfdata.Writer.new_tmp('recon', 'tags_test', 1)
  t:assert(wr, 'created Writer')
  wr:add_value('test', perfdata.units.ns, 100,
      { perfdata.tags.summary, perfdata.tags.context, })
  wr:close()

  local file = io.open(path)
  t:assert(file, 'opened perfdata file')

  local pdj = file:read('all')
  file:close()

  t:assert(pdj:match('summary'), 'found summary tag in perfdata')
  t:assert(pdj:match('context'), 'found context tag in perfdata')
end)

