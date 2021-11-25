#!/bin/bash

BASEDIR=$(dirname "$0")
RESULTSDIR="$TMPDIR/summary_darwinunit_tests"
FAILRESULTU="$RESULTSDIR/fail_unittest.txt"
PASSRESULTU="$RESULTSDIR/pass_unittest.txt"
FAILRESULTDU="$RESULTSDIR/fail_darwinunit.txt"
PASSRESULTDU="$RESULTSDIR/pass_darwinunit.txt"

echo "Running tests in ${BASEDIR}"

if [[ ! -e $RESULTSDIR ]]; then
    mkdir $RESULTSDIR
elif [[ ! -d $RESULTSDIR ]]; then
    echo "$RESULTSDIR already exists but is not a directory" 1>&2
    rm $RESULTSDIR
    mkdir $RESULTSDIR
fi

# export the environment variable so testing actions don't get reported to webserver

export PYTHONPATH="/usr/local/bin:${PYTHONPATH}"
PY=$(which python)

unset darwinunit

echo "Environment: darwinunit=$darwinunit"

if [ -z $1 ]; then
    $PY "${BASEDIR}/test_failing_assertions.py" > $FAILRESULTU
    $PY "${BASEDIR}/test_passing_assertions.py" > $PASSRESULTU
else
    $PY $1
fi

export $darwinunit=True

echo "Environment: darwinunit=$darwinunit"

if [ -z $1 ]; then
    $PY "${BASEDIR}/test_failing_assertions.py" > $FAILRESULTDU
    $PY "${BASEDIR}/test_passing_assertions.py" > $PASSRESULTDU
else
    $PY $1
fi

echo "Saving summary files in ${RESULTSDIR}"
echo "Comparing results"

diff $FAILRESULTU $FAILRESULTDU
if [ $? -eq 0 ]; then
    echo "Everything looks good for failing assertion test"
else
    echo "FAILED: conflict between results from unittest and darwinunit for failing assertions case"
fi

diff $PASSRESULTU $PASSRESULTDU
if [ $? -eq 0 ]; then
    echo "Everything looks good for passing assertion test"
else
    echo "FAILED: conflict between results from unittest and darwinunit for passing assertions case"
fi