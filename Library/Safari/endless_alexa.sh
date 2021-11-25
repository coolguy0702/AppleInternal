#!/bin/bash
# Description: Run Alexa test in endless mode.
# 
# How it works: when Safari crashed or jetsammed, we check the result file for this run and count
# how many sites had loaded.  We then use that number to skip sites in the new run.

# Results directory.
safariContainer=`SafariBookmarks container`
if [ $? -ne 0 ]; then
  echo "Error checking for sandbox container."
  exit 1
fi

RESULTS_DIRECTORY="$safariContainer/tmp"
echo "Results Directory: $RESULTS_DIRECTORY"
[ ! -d "$RESULTS_DIRECTORY" ] && mkdir "$RESULTS_DIRECTORY"

ALEXA_SITES_FILE="/AppleInternal/Library/Safari/alexa_10k.txt"

# Symbolicate crash logs. Save the current values so we can restore later.
value=`defaults read com.apple.CrashReporter SymbolicateCrashes 2>/dev/null`
currentCrashReporterSymbolicateCrashes="NO"
if [ "$value" == '1' ]; then currentCrashReporterSymbolicateCrashes="YES"; fi
defaults write com.apple.CrashReporter SymbolicateCrashes -bool YES

# Set the autolock to Never so the device never sleeps. Save the current values so we can restore later.
currentProfilectlMaxInactivityValue=`/usr/local/bin/profilectl settings | awk 'BEGIN {effective=0} /^Effective/ {effective=1;print} /maxInactivity/,/\}/ {if(effective)print}' | perl -n -e '/value.*?(\d+)/ && print $1'`
/usr/local/bin/profilectl setnum maxInactivity 2147483647 1>/dev/null

# Restore settings when the user stops this script.
trap "onsigint" SIGINT
onsigint() {
    echo; echo "Restoring CrashReporter and profilectl settings..."
    defaults write com.apple.CrashReporter SymbolicateCrashes -bool $currentCrashReporterSymbolicateCrashes
    /usr/local/bin/profilectl setnum maxInactivity $currentProfilectlMaxInactivityValue 1>/dev/null
    exit
}

# Fixme: should we remove the existing result files for a fresh start?

# Loop forever.
skipSitesCount=0
run=0; while true; do
    run=$[run+1]
    echo "Alexa run: $run"
    echo "---------------------------------------"

    # Kill MobileSafari if it's still alive.
    killall MobileSafari 1> /dev/null 2> /dev/null
    sleep 2

    if [ $skipSitesCount -ne 0 ]; then
         echo "Previous test crashed, continue from site $skipSitesCount..."
    fi

    # Run alexa test in skip mode. Also, disable redirecting to external apps.
    LaunchApp -unlock com.apple.mobilesafari -RedirectToExternalAppsDisallowed 1 -T Alexa -P suiteName:/AppleInternal/Library/Safari/alexa_10k.txt -P pageTimeout:15 -P skipCount:$skipSitesCount -P logFile:$RESULTS_DIRECTORY/alexa_run.log

    # Wait till Safari crashes or jetsammed.
    while pidof MobileSafari > /dev/null; do
        sleep 30
    done

    # MobileSafari crashed or jetsammed, start another round.
    echo "MobileSafari crashed or jetsammed!"

    # Find which site crashed Safari, and back up the result file.
    if [ -e "$RESULTS_DIRECTORY/alexa_run.log" ]; then
        # Find how many sites had loaded in previous run.
        lineCount=(`wc -l $RESULTS_DIRECTORY/alexa_run.log`)
        newSkip=$[${lineCount[0]}+1]
        skipSitesCount=$[$skipSitesCount+$newSkip]

        crashedSite=$(sed -n ${skipSitesCount}p $ALEXA_SITES_FILE)
        echo "Crash site: $crashedSite"
        mv -f $RESULTS_DIRECTORY/alexa_run.log $RESULTS_DIRECTORY/alexa_run~$run.log
    fi
 
    # Copied from Joe's repeat-mobilesafari-stress-test.sh:

    # Check the syslog for the crash report. Copy it to results directory.
    # Example output that could be in syslog:
    #   - Apr  2 20:22:35 unknown ReportCrash[705] <Error>: Saved crashreport to /Library/Logs/CrashReporter/LowMemory-2011-04-02-202235.plist using uid: 0 gid: 0, synthetic_euid: 0 egid: 0
    #   - Apr  2 20:31:43 iPad ReportCrash[917] <Error>: Saved crashreport to /var/mobile/Library/Logs/CrashReporter/MobileSafari_2011-04-02-203128_iPad.plist using uid: 0 gid: 0, synthetic_euid: 501 egid: 0
    #   - Apr  2 20:31:43 iPad ReportCrash[917] <Error>: Saved crashreport to /var/mobile/Library/Logs/CrashReporter/MobileSafari_2011-04-02-203128_iPad.crash using uid: 0 gid: 0, synthetic_euid: 501 egid: 0
    #   - Apr  2 20:31:43 iPad ReportCrash[917] <Error>: Saved symbolicated crashreport to /var/mobile/Library/Logs/CrashReporter/MobileSafari_2011-04-02-203128_iPad.crash using uid: 0 gid: 0, fake_euid: 0 egid: 0
    crashFile=$(syslog | tail -100 | grep crashreport | tail -1 | sed -E -e 's|.+ to ||' | sed -E -e 's| .+||')
    if [ -n "$crashFile" ]; then
        echo "Crash log: $crashFile"
        cp "$crashFile" "$RESULTS_DIRECTORY/MobileSafari.crash.$i"
    fi

    echo
done
