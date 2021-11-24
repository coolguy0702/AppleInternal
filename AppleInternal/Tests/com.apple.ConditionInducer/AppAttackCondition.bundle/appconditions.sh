#/bin/bash
# Author: Liad Ben-Yehuda (liad_benyehuda@apple.com)
# Script to simulate app install conditions during a restore process
set -eof pipefail

# Verboseness setup
VERBOSE=1
COMMON_PATH="${PWD}" # This path needs to be writable
APP_CONDITIONS_LOG="appconditions.log"
APP_CONDITIONS_ERR_LOG="appconditions.log"
INSTALLED_APPS="installed_app_ids"
DEFAULT_TIMEOUT=60

ASCLIENT="$(which asclient)"
[ -z "$ASCLIENT" ] && echo "Fatal error: asclient missing!" && exit 1

# Holds the ids of the apps installed by this script
CONDITION_APP_IDS=""

function echo_n()
{
    if [ "$VERBOSE" -eq 1 ]; then
        printf "%b" "$@" | tee -a "$APP_CONDITIONS_LOG"
    else
        printf "%b" "$@" >>"$APP_CONDITIONS_LOG"
    fi
}

function echo_v() 
{
    if [ "$VERBOSE" -eq 1 ]; then
        printf "%b\n" "$@" | tee -a "$APP_CONDITIONS_LOG"
    else
        printf "%b\n" "$@" >> "$APP_CONDITIONS_LOG"
    fi
}

function echoerr()
{
    printf "%b\n" "$@" | tee -a "$APP_CONDITIONS_ERR_LOG" >&2
}

function log_only()
{
    printf "%b" "$@" >> "$APP_CONDITIONS_LOG"
}

# Failure handlers
function soft_failure
{
    local rc=$1; shift
    echoerr "Failure: $@ [status: $rc]."
    return $rc
}

function hard_failure
{
    local rc=$1; shift
    echoerr "Fatal: $@ [status: $rc]."
    # DOTO: Write a clean up function and invoke it here 
    exit $rc
}

# Will capture stderr and stdout to the log file while keeping them in their
# respective file descriptors. It's possible to split it in to separate files if needed
# You could add HIDE@ in-front of an arg you'd like to hide from the logs (like a password)
function exec_n_cap()
{
    local -a args=( "$@" )
    local force_output=0
    local log_func="echo_n"
    if [ "${args[0]}" = "--verbose" ]; then
        force_output=1
        args=( ${@:2} ) # remove the switch from the arg list
        log_func="log_only"
    fi

    "$log_func" "Executing: "
    for arg in "${!args[@]}"; do
        if [ -z "${args[$arg]##*HIDE@*}" ]; then
            args[$arg]=${args[$arg]//HIDE@/}; "$log_func" "<hidden> "
        else
            "$log_func" "${args[$arg]} "
        fi
    done; "$log_func" "\n"

    # eval and Execute
    local rc=0
    if [ "$VERBOSE" -eq 1 ] || [ "$force_output" -eq 1 ]; then 
        # VERY ugly but since bash under iOS doesn't support process substitution this is it.
        local rand="$RANDOM"
        local tmp_out="${COMMON_PATH}/$$.$rand.out" tmp_err="${COMMON_PATH}/$$.$rand.err"
        eval "${args[@]}" >"$tmp_out" 2>"$tmp_err" || rc=$?
        cat "$tmp_out" | tee -a "$APP_CONDITIONS_LOG"
        cat "$tmp_err" | tee -a "$APP_CONDITIONS_ERR_LOG" >&2
        rm -f "$tmp_out" "$tmp_err"
    else
        eval "${args[@]}" >>"$APP_CONDITIONS_LOG" 2>>"$APP_CONDITIONS_ERR_LOG"
        rc=$?
    fi
    [ $rc -ne 0 ] && soft_failure "$rc" "exec_n_cap came back with an error."
    return $rc
}

function item_ids_to_bundle_ids()
{
    local item_ids="$@"
    local app_table="$(exec_n_cap "--verbose" "$ASCLIENT apps list user")"
    local bundle_ids=()
    for id in ${item_ids[@]}; do
        local bundle_id
        if bundle_id="$(echo "$app_table" | grep "$id" | awk '{print $2}')"; then
            bundle_ids+=($bundle_id)
        fi
    done
    echo "${bundle_ids[@]}"
}

# This function will turn off the effect of a page scroll whenever an app
# is being installed. This will allow PPTs to run with a condition on.
function turn_off_icon_scrolling()
{
    local default_setting="com.apple.springboard 'SBFolderViewSuppressSetCurrentPage'"
    local val=$(exec_n_cap "--verbose" "login -f mobile defaults read $default_setting" 2>/dev/null | head -n 1 | grep -v "Last login")
    # if the key is already set don't do anything.
    [ ! -z "$val" ] && [ $val -eq 1 ] && return 0
    
    # Set the key
    exec_n_cap "login -f mobile defaults write $default_setting -bool YES 2>&1 >/dev/null"
    # read back
    local val=$(exec_n_cap "--verbose" "login -f mobile defaults read $default_setting" | head -n 1 | grep -v "Last login")
    [ $val -ne 1 ] && soft_failure "1" "Failed to turn off icon scrolling."

    # restart SpringBoard
    exec_n_cap "kill -9 $(ps -ef | grep "SpringBoard.app/SpringBoard" | head -n1 | awk '{print $2}')"
    sleep 3
}

function turn_on_icon_scrolling()
{
    local default_setting="com.apple.springboard 'SBFolderViewSuppressSetCurrentPage'"
    local val=$(exec_n_cap "--verbose" "login -f mobile defaults read $default_setting" 2>/dev/null | head -n 1 | grep -v "Last login")
    # if the key isn't set we're done
    [ -z "$val" ] && return 0
    # Set the key
    exec_n_cap "login -f mobile defaults remove $default_setting 2>&1 >/dev/null"
    # restart SpringBoard
    exec_n_cap "kill -9 $(ps -ef | grep "SpringBoard.app/SpringBoard" | head -n1 | awk '{print $2}')"
}

function get_username()
{
    local username="$1"
    if [ -z "$username" ]; then
        read -rp "Enter your Apple ID username: " username
    fi
    echo "$username"
}

function get_password()
{
    
    local password="$1"
    if [ -z "$password" ]; then
        read -rsp "Enter your Apple ID password: " password
    fi
    echo "$password"
}

function authenticate()
{
    if ! exec_n_cap "--verbose" "$ASCLIENT account" | grep -q "not signed"; then
        echo_v "Already signed in."
        return 0
    fi

    local applid_user="$(get_username $1)"
    local applid_pass="$(get_password $2)"
    if [ -z "$applid_user" ] || [ -z "$applid_pass" ]; then
        echoerr "Username or password are not set."
        return 1
    fi
    local response="$(exec_n_cap "--verbose" "$ASCLIENT authenticate $applid_user" "\"HIDE@$applid_pass\"")"
    if ! echo "$response" | grep -qe 'Response: Success\|responseType: Success'; then
        echoerr "Authentication Failed!"
        return 1
    fi
    exec_n_cap "$ASCLIENT pwsettings --free never --password" "\"HIDE@$applid_pass\""
    exec_n_cap "sleep 3"
    return 0
}

# Returns only when appstored is done executing all of it's jobs
function track_appstored_job_progress()
{
    local response job_count sleep_interval=$DEFAULT_TIMEOUT
    while true; do
        response=$(exec_n_cap "--verbose" "$ASCLIENT jobs list")
        job_count=$(echo "$response" | sed -n 's/.*Job Count: \([0-9]*\).*/\1/p')
        [ -z "$job_count" ] && break
        [ $job_count -le 3 ] && sleep_interval=5
        echo_v "Sleeping and re-querying..."
        exec_n_cap "sleep $sleep_interval"
    done
}

function install_apps()
{
    local app_ids="$@"
    [ -z "$app_ids" ] && return 1
    # Record which apps we're about to install only when we don't mix the existing apps
    echo "$app_ids" > "$INSTALLED_APPS"
    exec_n_cap "$ASCLIENT install $app_ids" \
        || hard_failure "$?" "Error while installing app ids [$app_ids]."
    sleep 3; track_appstored_job_progress
}

# Will split the install load to two parts.
# As the first part finishes the install, the second load will kick off,
# first part will be scrubbed in the background. All in an endless loop.
function infinite_installs()
{
    # Turn the input into an array
    local app_ids=( $@ )

    # index the app ids array
    local app_count="${#app_ids[@]}"
    local set1_end_index=$(($app_count/2))
    local set2_end_index=$(($app_count-$app_set1-1))

    # Create two arrays of equal size containing the total number of app ids
    local app_set1="${app_ids[@]:0:$set1_end_index}"
    local app_set2="${app_ids[@]:$set1_end_index:$set2_end_index}"

    # Debug logs
    echo_v "Total count: $app_count. Set1: $(echo $app_set1 | wc -w). Set2: $(echo $app_set2 | wc -w)"
    log_only "Set 1: ${app_set1[@]}\n"
    log_only "Set 2: ${app_set2[@]}\n"
    log_only "Total: $(echo ${app_ids[@]} | tr '\n' ' ')\n"

    # Execution
    local set_num=1
    while /usr/bin/true; do
        [ $set_num -eq 1 ] && install_apps "${app_set1[@]}" || install_apps "${app_set2[@]}"
        local ids_to_remove="$(cat $INSTALLED_APPS)"
        if [ ! -z "$ids_to_remove" ]; then
            exec_n_cap "rm -f $INSTALLED_APPS"
            # spawn the remove in the background
            exec_n_cap "$ASCLIENT remove $ids_to_remove" \
                || soft_failure "$?" "Could not remove all apps, but that's fine." &
        fi
        [ $set_num -eq 1 ] && set_num=2 || set_num=1
        exec_n_cap "sleep 1"
    done
}

function infinite_installs_no_sets()
{
    # Turn the input into an array
    local app_ids=( $@ )
    while /usr/bin/true; do
        install_apps "${app_ids[@]}" || hard_failure "$?" "App installation failed!."
        exec_n_cap "$ASCLIENT remove "${app_ids[@]}""
    done
}

function update_apps()
{
    local bundle_ids="$1"
    [ ! -z "$bundle_ids" ] || hard_failure "1" "app ids needed for update."
    exec_n_cap "$ASCLIENT updates reload"
    exec_n_cap "$ASCLIENT updates update $bundle_ids" \
        || hard_failure "$?" "Error while updating app ids [$bundle_ids]."
    sleep 3; track_appstored_job_progress
}

function downgrade_apps()
{
    local app_ids="$1"
    # since asclient won't return a non-zero code on a failure I have to read the resulting string 
    # <rdar://problem/39117805> asclient returns 0 even though a failure occurred
    local result=$(exec_n_cap "--verbose" "$ASCLIENT downgrade $app_ids")
    if [ -z "${result##*Server error*}" ]; then
       echoerr "Downgrade failed."
       return 1
    fi
}

# Given a specific (total) size provide enough app ID to achieve that size.
# Used to fill up a device up to a certain point with apps.
function get_app_ids_by_size()
{
    local size="$1"
    if [ -z "$size" ]; then
        echoerr "Undefined sizes are not allowed, please provide a valid size in GBs"
        return 1
    else
        # Convert GB size to bytes
        size=$(echo - | awk "{printf \"%.0f\", $size * 1000000000}")
        [ $size -le 0 ] && echoerr "Size needs to be at least 1 byte." &&  return 1
    fi


    local app_arr=( $(exec_n_cap "--verbose" \
                               "asclient lookup charts --count 1500" \
                               "| sed -n 's/\([0-9]\{3,\}\).*  \([0-9]\{3,\}\)/\1 \2/p' " \
                               "| sort -rn -k2" \
                               "| tr ' ' ':'") )

    if ! grep -qE '^[0-9]+:[0-9]+$'<<< "$app_arr"; then
        echoerr "Failed to query the app store. File a radar."
        return 1
    fi

    local app_id app_size 
    local size_sofar=0
    local app_ids=()

    for app in ${app_arr[@]}; do
        IFS=: read app_id app_size <<< "$app"
        [ $(($size_sofar + $app_size)) -gt $size ] && continue
        size_sofar=$((size_sofar + app_size))
        app_ids+=($app_id)
    done; unset IFS

    log_only "Resulting ids: ${app_ids[*]}\n"
    log_only "Total number of apps [${#app_ids[@]}]. Total size [$((size_sofar / 1000000000)) GB].\n"

    # Return result
    echo "${app_ids[@]}"
    return 0
}

function get_top_charts_app_ids()
{
    local count=${1:-100}
    local size=$2
    local exclude_local_apps_flag="$3"

    local local_app_ids="$(exec_n_cap "--verbose" "$ASCLIENT apps list user" \
                            | awk '{if ($1 ~/^[0-9]+$/) printf "%s ", $1}')"
    local app_ids
    if [ ! -z "$size" ]; then
        app_ids="$(get_app_ids_by_size $size)" || return 1
    else
        app_ids="$(exec_n_cap "--verbose" "$ASCLIENT lookup charts --verbose no --count $count")" || return 1
    fi

    if ! grep -qE '^([0-9]+ *)+$' <<< "$app_ids"; then
        echoerr "Invalid response from asclient [$app_ids]. Aborting"
        return 1
    fi

    # Don't let the top charts list overlap with the user's app list
    # Exclude ID's that are already on the system
    if [ ! -z "$exclude_local_apps_flag" ]; then
        local set1="$COMMON_PATH/set1.$$"
        local set2="$COMMON_PATH/set2.$$"
        echo "${app_ids[@]}" | tr ' ' '\n' > $set1
        echo "${local_app_ids[@]}" | tr ' ' '\n' > $set2
        app_ids="$(sort $set2 $set2 $set1 | uniq -u | tr '\n' ' ')"
        rm $set1 $set2
        [ -z "$app_ids" ] && echo_v "All app ids are already on the system." && return 0
    fi
    # return the app ids we filtered
    echo "$app_ids"
}

function downgrade_all_update_all()
{
    local use_user_apps="$1"
    local app_ids="$(cat $INSTALLED_APPS)"

    # use the already installed apps on the device if the user asked for it
    if [ ! -z "$use_user_apps" ]; then
        app_ids="$(exec_n_cap "--verbose" "$ASCLIENT apps list user" \
                    | awk '{if ($1 ~/^[0-9]+$/) printf "%s ", $1}')"
    fi
    local bundle_ids=""
    while /usr/bin/true; do
        downgrade_apps "$app_ids" || return 1
        if [ -z "$bundle_ids" ]; then
            bundle_ids="$(item_ids_to_bundle_ids $app_ids)"
            [ ! -z "$bundle_ids" ] || hard_failure "1" "Could not convert ids to bundle labels."
        fi
        update_apps "$bundle_ids"
    done
}

function shutdown_scenario()
{
    local response job_count
    while true; do
        echo_v "Cancelling all jobs"
        exec_n_cap "$ASCLIENT jobs cancelAll"
        echo_v "Waiting for other jobs to be scheduled..."
        exec_n_cap "sleep 20"
        response=$(exec_n_cap "--verbose" "$ASCLIENT jobs list")
        job_count=$(echo "$response" | sed -n 's/.*Job Count: \([0-9]*\).*/\1/p')
        # Stop when no jobs are detected
        [ -z "$job_count" ] && break
    done
    local ids_to_remove="$(cat $INSTALLED_APPS)"
    [ -z "$ids_to_remove" ] && return 0
    exec_n_cap "$ASCLIENT remove $ids_to_remove" \
        || soft_failure "$?" "Could not remove all apps, but that's fine."
    exec_n_cap "rm -f $INSTALLED_APPS"
    turn_on_icon_scrolling
    return $?
}

function wait_for_progress()
{
    local response job_count
    while true; do
        response=$(exec_n_cap "--verbose" "$ASCLIENT jobs list")
        job_count=$(echo "$response" | sed -n 's/.*Job Count: \([0-9]*\).*/\1/p')
        [ ! -z $job_count ] && [ $job_count -gt 0 ] && break
        exec_n_cap "sleep 5"
    done
}

function usage()
{
    local script_name="$(basename $0)"
    echo_v "$script_name [-a Apple ID] [-p Apple ID password] [-lqheSxunz] -s <scenario> [scenario args ...]"
    echo_v "Optional Flags:"
    echo_v "-d prints the description of the possible Scenarios to induce."
    echo_v "-c <common path> A path that will contain all artifacts generated by this script. This path needs to be"
    echo_v "   writable. Default path is the execution path. -l or -e will override the relative path of their respective actions."
    echo_v "-l <log path> A file to write stdout to (also stderr if -e wasn't specified), default appconditions.log"
    echo_v "-e <log path> A file to write stderr to, default appconditions.err"
    echo_v "-h prints this page."
    echo_v "-q make the script completely silent while still logging everything to the log file/s"
    echo_v "-S will disable the icon scrolling effect SpringBoard initiates, this will also restart SpringBoard."
    echo_v "  In order to restore the previous SpringBoard functionality you'll have to run the shutdown scenario."
    echo_v
    echo_v "The following options are only available for some scenarios:"
    echo_v "-n <number of apps> set the number of app to be installed."
    echo_v "-z <size of apps in GB> set amount of space you'd like the apps to take in GBs."
    echo_v "-x exclude local apps, do not use any local app for the action the script takes."
    echo_v "-u use local apps, use the local app for the actions the script takes."
    echo_v
    echo_v "Example:"
    echo_v "$script_name -a foo@gmail.com -p bar -s install-top-apps 10 --exclude-local-apps"
    echo_v "Will install the top 10 free apps from the app store while excluding the apps already present on the device"
}

function scenario_descriptions()
{
    echo_v "Possible Scenarios:"
    echo_v "infinite-top-app-installs [-n <number of apps>] [-z <size of apps in GBs>] [-e exclude local apps]:"
    echo_v "Will install the number of apps requested by the user (default 100 is wasn't specified)."
    echo_v "If -x is specified only the apps that don't already exist on the device will be downloaded and installed."
    echo_v "Once all apps are installed the script will remove all of them and reinstall them in a loop."
    echo_v
    echo_v "install-top-apps [-n <number of apps>] [-z <size of apps in GBs>] [-e exclude local apps]:"
    echo_v "Just like infinite-top-app-installs only this action will not go in to an infinite install/remove loop,"
    echo_v "the apps will stay on the device"
    echo_v
    echo_v "downgrade-all-update-all [-u use user apps]: Will downgrade all of the 3rd party app installed by"
    echo_v "this script (unless -u is specified) on the device and update"
    echo_v "them thus simulating a mass \"Update all\" scenario. This action will run in an infinite loop."
    echo_v
    echo_v "shutdown: Will stop all the activities of the appstore daemon and revert the actions of this script if possible."
}

function main()
{
    local appleid_username appleid_password app_id scenario err_log num_of_apps size_of_apps
    local exclude_local_apps_flag use_local_apps_flag stop_icon_scrolling_flag

    #### GET OPTIONS ####
    if ! args=$(getopt a:p:i:e:l:s:c:n:z:qhduxS $*); then
        usage
        exit 1
    fi

    set -- $args
    for i; do
        case "$i" in
            -a) appleid_username="$2";      shift 2;;
            -p) appleid_password="$2";      shift 2;;
            -s) scenario="$2";              shift 2;;
            -e) err_log="$2";               shift 2;;
            -n) num_of_apps="$2";           shift 2;;
            -z) size_of_apps="$2";          shift 2;;
            -l) APP_CONDITIONS_LOG="$2";    shift 2;;
            -c) COMMON_PATH="$2";           shift 2;;
            -u) use_local_apps_flag=1;      shift;;
            -x) exclude_local_apps_flag=1;  shift;;
            -S) stop_icon_scrolling_flag=1; shift;;
            -q) VERBOSE=0;                  shift;;
            -d) scenario_descriptions;      exit 0;;
            -h) usage;                      exit 0;;
            --) shift;                      break;;
        esac
    done

    # Create the common path if it doesn't exist
    if [ ! -z "$COMMON_PATH" ] && [ ! -d "$COMMON_PATH" ]; then
        mkdir -p "$COMMON_PATH" || hard_failure "$?" "Could not create: $COMMON_PATH"
    fi

    # Set the default paths for the logs and artifacts
    APP_CONDITIONS_LOG="${COMMON_PATH}/$APP_CONDITIONS_LOG" 
    APP_CONDITIONS_ERR_LOG="${COMMON_PATH}/$APP_CONDITIONS_LOG"
    INSTALLED_APPS="${COMMON_PATH}/installed_app_ids"

    # Set custom paths for logs if needed
    [ -z "$err_log" ] && APP_CONDITIONS_ERR_LOG="$APP_CONDITIONS_LOG" || APP_CONDITIONS_ERR_LOG="$err_log"
    [ -z "$scenario" ] && echoerr "A Scenario wasn't specified, aborting." && return 1

    log_only "############# New Run: $0 #############\n"
    # Clean up
    rm -f "${COMMON_PATH}"/*.{err,out}

    local app_ids=""
    # scenarios
    # SCENARIO - Install a large number of new apps on the device (default 100) in an INFINITE LOOP
    if [ "$scenario" = "infinite-top-app-installs" ]; then
        authenticate "$appleid_username" "$appleid_password" || return 1
        app_ids="$(get_top_charts_app_ids "$num_of_apps" "$size_of_apps" "$exclude_local_apps_flag")" || return 1
        [ ! -z "$stop_icon_scrolling_flag" ] && turn_off_icon_scrolling
        [ -z "$size_of_apps" ] && infinite_installs "${app_ids[@]}" || infinite_installs_no_sets "${app_ids[@]}"
    # SCENARIO - Install Install a large number of new apps on the device (default 100)
    elif [ "$scenario" = "install-top-apps" ]; then
        authenticate "$appleid_username" "$appleid_password" || return 1
        app_ids="$(get_top_charts_app_ids "$num_of_apps" "$size_of_apps" "$exclude_local_apps_flag")" || return 1
        [ ! -z "$stop_icon_scrolling_flag" ] && turn_off_icon_scrolling
        install_apps "${app_ids[@]}"
    # SCENARIO - Downgrade all 3rd party apps on the device and update them
    elif [ "$scenario" = "downgrade-all-update-all" ]; then
        authenticate "$appleid_username" "$appleid_password" || return 1
        [ ! -z "$stop_icon_scrolling_flag" ] && turn_off_icon_scrolling
        downgrade_all_update_all "$use_local_apps_flag"
    # SCENARIO - Cancel all jobs and remove apps installed by this script when possible.
    elif [ "$scenario" = "shutdown" ]; then
        shutdown_scenario
    # SCENARIO - waits  for a progress signal. Useful for testing when we want to know when the actual
    # app installation process began.
    elif [ "$scenario" = "wait-for-progress" ]; then
        wait_for_progress
    else
        echoerr "$scenario: No such scenario, aborting."
        return 1
    fi
}
main "$@"
