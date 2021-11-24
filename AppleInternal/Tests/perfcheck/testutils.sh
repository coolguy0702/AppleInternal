#  testutils.sh
#
#  Copyright (c) 2016-2017 Apple Inc. All rights reserved.

# Utilities shared by test scripts

die()
{
    progname="`basename $0`"
    echo $progname fatal error: "$@"
    exit 1
}

# sanity check our assumptions
[ "$BASH_VERSION" ] || die "need bash for PIPESTATUS[]"
if [ "$TMPDIR" ]; then
    # Because test_easyperf frequently does
    #   args="foo bar $scratchf"; doSomething "$args"
    # $scratchf (derived from $TMPDIR) can't have spaces.
    [[ $TMPDIR == *\ * ]] && die "don't support spaces in TMPDIR ('$TMPDIR')"
    [ -d "$TMPDIR" ] || die "can't find TMPDIR $TMPDIR"
fi

# find most up-to-date easyperf and any adjacent easyperf.dylib
EASYPERFDIR="/usr/local/bin"
EASYPERF="${EASYPERFDIR}/easyperf"
PERFCHECK="${EASYPERFDIR}/perfcheck"

# first find most up to date easyperf
for dir in $BUILDSDIR/{Debug,Release} . build/{Debug,Release}
do
    candidate="$dir/easyperf"
    [ -x "$candidate" ] || continue
    # echo "trying $candidate"
    DYLD_LIBRARY_PATH=$dir:$dir/lib DYLD_FRAMEWORK_PATH=$dir:$dir/lib \
            "$candidate" -h > /dev/null
    if [ $? -eq 0 -o $? -eq 64 ] && [ "$candidate" -nt "$EASYPERF" ]; then
        # echo "preferring $candidate"
        EASYPERF="$candidate"
        EASYPERFDIR="$dir"
    fi
done

# and now find perfcheck
for dir in $BUILDSDIR/{Debug,Release} . build/{Debug,Release}
do
    candidate="$dir/perfcheck"
    [ -x "$candidate" ] || continue
    # echo "trying $candidate"
    DYLD_LIBRARY_PATH=$dir:$dir/lib DYLD_FRAMEWORK_PATH=$dir:$dir/lib \
            "$candidate" -h > /dev/null

    if [ $? -eq 0 -o $? -eq 64 ] && [ "$candidate" -nt "$PERFCHECK" ]; then
        # echo "preferring $candidate"
        PERFCHECK="$candidate"
    fi
done

[ -x "$EASYPERF" ] || die "looked all over, but can't find easyperf"
[ -x "$PERFCHECK" ] || die "looked all over, but can't find perfcheck"

if [ $(dirname "$PERFCHECK") != $(dirname "$EASYPERF") ]; then
    die "$PERFCHECK and $EASYPERF in different directories?"
fi

if [ -e "$EASYPERFDIR/libperfcheck.dylib" ]; then
    export DYLD_LIBRARY_PATH="$EASYPERFDIR"
    export DYLD_FRAMEWORK_PATH="$EASYPERFDIR"
elif [ -e "$EASYPERFDIR/lib/libperfcheck.dylib" ]; then
    export DYLD_LIBRARY_PATH="$EASYPERFDIR/lib"
    export DYLD_FRAMEWORK_PATH="$EASYPERFDIR/lib"
fi

printf "testing $EASYPERF & $PERFCHECK"
[ "$DYLD_LIBRARY_PATH" ] && printf " (with dyld=>$DYLD_LIBRARY_PATH)"
printf "...\n"


## constants

# standard FDs
STDIN_FILENO=0
STDOUT_FILENO=1
STDERR_FILENO=2

# exit codes
export EX_OK=0              # typically '-eq 0' conveys "success?"
export EXIT_FAILURE=1       # from stdlib.h

export kPCExitPerfRegression=42

export EX_USAGE=64          # sysexits.h
export EX_DATAERR=65        # malformed input file
export EX_NOINPUT=66        # missing file
export EX_SOFTWARE=70       # generally an error within easyperf
export EX_OSERR=71          # error originating with system call (std err msg)
export EX_NOPERM=77         # can't examine a process
export EX_CONFIG=78         # missing baseline data

## check if monotonic is enabled
export HAVE_MONOTONIC=$(sysctl -n kern.monotonic.task_thread_counting|grep 1)

EASYPERF_BASELINE=/AppleInternal/Tests/perfcheck/easyperf_perfcheck.epb
[ -r "$EASYPERF_BASELINE" ] || die "missing $EASYPERF_BASELINE"
# and now unset it if it's not valid for the current device :P
hwmodel=$(sysctl -n hw.model)
if ! plutil -p "$EASYPERF_BASELINE" | grep -q "$hwmodel"; then
    echo "test_easyperf: WARNING: no $hwmodel in $EASYPERF_BASELINE, will skip associated tests" >&2
    unset EASYPERF_BASELINE
fi

# scratch objects
scriptname="${0##*/}"
tmpdir="${TMPDIR:-/tmp}"
scratchf1="$tmpdir/${scriptname}.tmp1.$$"
scratchf2="$tmpdir/${scriptname}.tmp2.$$"
pdv1file="$tmpdir/${scriptname}.$$.perfdata"
pdv2file="$tmpdir/${scriptname}.$$.pdj"
baselinef="$tmpdir/${scriptname}.baselinef.$$"
outf="$tmpdir/${scriptname}.outf.$$"
scratchdir="$tmpdir/${scriptname}.tdir.$$"

# clean up temp files at exit
cleanup()
{
    rm -f "$scratchf1" "$scratchf2" "$baselinef" "$outf" "$pdv1file" "$pdv2file"
    rm -rf "$scratchdir"
}

# trigger test code in libeasyperf
set -x
export PERFCHECK_TESTING=1
set +x

# shared constants
MBCOUNT=10
MBCplus=$((MBCOUNT * 120/100))
DDARGS="if=/dev/zero bs=1m of=$scratchf2"
BIGFILE=/usr/lib/libdtrace.dylib
SMFILE=/etc/hosts

# really trivial commands (cksum, xxd) don't have sufficient memory
# footprint to go beyond +/-10% due to random variation. :P
# these shouldn't write to stderr lest they inadvertantly dirty $outf below
if [ -x /usr/bin/yaa ]; then
    # yaa doesn't spuriously write to /tmp like bsdtar on macOS
    TRIVIAL_CPU_CMD="yaa archive -d /etc/pam.d -o /dev/null"
    NONTRIVIAL_CPU_CMD="yaa archive -d /sbin -o /dev/null"
else
    # yaa isn't on all platforms; bsdtar doesn't write to /tmp on iOS
    TRIVIAL_CPU_CMD="tar cPf /dev/null /etc/pam.d"
    NONTRIVIAL_CPU_CMD="tar czPf /dev/null /sbin"
fi
# NONTRIVIAL_CPU_CMD="xxd $BIGFILE /dev/null"

# TODO: scaling (29429013)
CH_METUNITS_AWK='
function checkUnit(expectedUnit) {
    if (index($0, expectedUnit)) {
        rightunits++
    } else {
        print "incorrect unit in line:", $0
    }
}

$0 !~ /^ / { next }
{ nmetrics++ }

# CPU
/cpu_time/          { checkUnit("ms") }
/cpu_instrs/        { checkUnit("kI") }

# MEMORY
/current_mem/       { checkUnit("kB") }
/mem_delta/         { checkUnit("kB") }
/lifetime_peak/     { checkUnit("kB") }
/recent_peak/       { checkUnit("kB") }
/peak_delta/        { checkUnit("kB") }

# I/O
/storage_dirtied/   { checkUnit("kB") }

END {
    if (nmetrics == rightunits) {
        exit(0)
    } else {
        exit(ENVIRON["EX_DATAERR"])
    }
}'

# launch helpers to log command lines
# (not useful if redirecting stderr :P)
runTool()
{
    set -x
    "$TOOL" "$@"
    excode=$?
    set +x
    return $excode
}

runErr2out()
{
    set -x
    "$TOOL" "$@" 3>&2 2>&1 1>&3     # stderr to stdout, stdout to stderr
    excode=$?
    set +x
    return $excode
}

# for cases with expected success, or optionally also allow an error code
# runCheck*out [-allow #] <pattern> <runCmd> [<tool args>]
# e.g. runCheckOut -allow 42 "cpu_time" runErr2out $args
runCheckOut()
{
    [ $# -ge 2 ] || die "runCheck*out <pattern> <runCmd> <tool> [<args>]"

    allowExcode=0
    if [ "$1" = "-allow" ]; then
        [ "$2" ] || return $EX_USAGE
        allowExcode="$2" && shift && shift
    fi

    pattern="$1" && shift
    runcmd="$1" && shift

    $runcmd "$@" > "$outf"
    toolCode=$?
    grep "$pattern" "$outf"
    grepCode=$?
    if [ "$toolCode" -ne 0 -a "$toolCode" -ne "$allowExcode" ]; then
        cat "$outf"
        FAIL "'${TOOLNAME} $*' exited with unexpected $toolCode"
    elif [ "$grepCode" -ne 0 ]; then
        cat "$outf"
        FAIL "'${TOOLNAME} $*' didn't emit '$pattern'"
    else
        PASS
    fi
}

runCheckStdout()
{
    pattern="$1" && shift
    runCheckOut "$pattern" runTool "$@"
}

runCheckStderr()
{
    pattern="$1" && shift
    runCheckOut "$pattern" runErr2out "$@"
}

runCheckOutAllowingPerfRegression()
{
    pattern="$1" && shift
    runCheckOut "-allow" "$kPCExitPerfRegression" "$pattern" runErr2out "$@"
}

# check for error output, obvious to both humans and automation
# Usage: runCheckErr [-noprefix] <testdesc> <msg> <exitName> <args ...>
# e.g. runCheckErr [-noprefix] "-h <validArg>" "ignoring" EX_USAGE -h -p $$
runCheckErr()
{
    if [ "$1" = "-noprefix" ]; then
        shift
        unset prefix
    else
        prefix="^${TOOLNAME}: .*"
    fi
    tname="$1" && shift
    errmsg="$1" && shift
    exname="$1" && shift
    if [ "$exname" -gt -1 ] 2> /dev/null; then
        FAIL "exitName should not be a number"
        return 64
    fi
    local rightCode=$(eval echo \$$exname)
    [ "$rightCode" -gt -1 ] || die "bogus error name $exname"
    [ $# -ge 1 ] || die "runCheckErr: nothing to run"

    # err(3) functions prepend "easyperf:" to messages
    # echo testing $tname
    # TODO: make sure errors are the expected number of lines
    runErr2out "$@" > "$outf"
    toolCode=$?
    grep "${prefix}${errmsg}" "$outf"
    grepCode=$?
    if [ "$grepCode" -ne 0 ]; then
        if [ -s "$outf" ]; then
            cat "$outf"
        else
            echo "(no output)"
        fi
        FAIL "'${tname}' did not fail w/message: '${prefix}${errmsg}'"
    elif [ "$toolCode" -ne "$rightCode" ]; then
        echo output:
        cat "$outf"
        FAIL "'${tname}' did not exit ${exname} (${rightCode}); got $toolCode"
    else
        PASS
    fi
}

checkWarnMixedTTYs()
{
    # shunit2 captures stdout
    [ "$SHUNIT_TRUE" ] && return

    unset emitWarning

    if [ -t "$STDIN_FILENO" -o -t "$STDOUT_FILENO" -o -t "$STDERR_FILENO" ] &&
        ! [ -t "$STDIN_FILENO" -a -t "$STDOUT_FILENO" -a -t "$STDERR_FILENO" ]
    then
        emitWarning=1
        for fd in 0 1 2; do
            if [ -t "$fd" ]; then
                echo "fd $fd is a tty"
            else
                echo "fd $fd is not a tty"
                suppressed="$suppressed $fd"
            fi
        done
    fi

    if [ "$emitWarning" ]; then
        echo "$1 suppressed fds${suppressed}"
        # read k
    fi | tee /dev/tty /dev/fd/2

    return $emitWarning
}

# record baseline, hiding stdout & sending stderr to $outf
recordBaseline()
{
    set -x
    "$EASYPERF" --record "$baselinef" "$@" >/dev/null 2>"$outf"
    excode=$?
    set +x

    if [ "$excode" -ne "$EX_OK" ]; then
        cat "$outf"
        FAIL "couldn't create baseline: exit code $excode"
    fi

    # warn if the FAIL output might have been hidden
    checkWarnMixedTTYs "$*"

    return $excode
}

# stdout >/dev/null, stderr >$outf
# $outf messes up storage_dirtied if "$@" writes to stderr
runCompareBaseline()
{
    if [ "$TOOLNAME" = easyperf ]; then
        set -x
        "$EASYPERF" --compare "$baselinef" "$@" >/dev/null 2>"$outf"
        excode=$?
        set +x
    elif [ "$TOOLNAME" = perfcheck ];then
        set -x
        "$PERFCHECK" score --compare "$baselinef" >/dev/null "$@" 2>"$outf"
        excode=$?
        set +x
    else
        FAIL "unknown toolname $TOOLNAME"
        excode="$EX_CONFIG"
    fi

    # warn if the FAIL output might have been hidden
    checkWarnMixedTTYs "$*"

    return "$excode"
}

compareBaseline()
{
    runCompareBaseline "$@"
    excode=$?

    if [ "$excode" -ne "$EX_OK" ]; then
        cat "$outf"
        FAIL "couldn't compare to baseline: exit code $excode"
    fi

    return $excode
}

detectRegression()
{
    runCompareBaseline "$@"
    excode=$?

    if [ "$excode" -ne "$kPCExitPerfRegression" ]; then
        cat "$outf"
        FAIL "regression not detected (got $excode instead)"
    fi

    return $excode
}

grepMeasurement()
{
    metric="$1"
    pat="$2"
    pdv2file="$3"
    sed -n '/^[ ]*"metric": "'"$metric"'",/,/^[ ]*}$/p'     \
                                                "$pdv2file" | grep "$pat"
}
