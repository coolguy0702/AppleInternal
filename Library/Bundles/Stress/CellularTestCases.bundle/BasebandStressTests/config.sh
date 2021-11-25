#!/bin/sh


SCRIPTS_DIR="/AppleInternal/Library/Bundles/Stress/CellularTestCases.bundle/BasebandStressTests/"


# PATHS
TOOLS_DIR="/usr/local/bin"
SEND_AT_COMMAND=`which SendATCommand`
CT_GET_RESET_STATE=`which CTGetResetState`
TESTCT=`which testCT`
LOCKDOWN_QUERY=`which lockdown_query`
CT_MONITOR=`which CoreTelephonyMonitor`
STREAMPERF=`which StreamPerf`
LOCMON=`which locmon`
RUN_SC=`which SleepCycler`
CT_HISTORY=`which cthistory`
GESTALT_QUERY=`which gestalt_query`

LOOP_BACK="4089619342"

#wifi parameters
WIFI_MODULO=3
SSID=""	
WEPKEY=""
SECURITY=""

# DEVICE INFO
DEVICENAME=`hostname`

UDID=`${GESTALT_QUERY} -undecorated UniqueDeviceID`
HARDWARE=`${GESTALT_QUERY} -undecorated HWModelStr | sed 's/AP//g'`
IMEI=`${GESTALT_QUERY} -undecorated InternationalMobileEquipmentIdentity`
MEID=`${GESTALT_QUERY} -undecorated MobileEquipmentIdentifier`
SERIAL=`${GESTALT_QUERY} -undecorated SerialNumber`
PHONE_NUMBER=`${GESTALT_QUERY} -undecorated PhoneNumber 2>&1`
APBUILD=`${GESTALT_QUERY} -undecorated BuildVersion`
CTVERSION=`grep "TraceModuleExtreme::CSILog::fLastCTVersion" /var/wireless/Library/Preferences/csidata | tr '=' ' ' | awk '{print $2}'`

DEVICETYPE=`${GESTALT_QUERY} -undecorated DeviceClass`
ProductType=`${GESTALT_QUERY} -undecorated ProductType`
BOOTARGS=`/usr/sbin/nvram boot-args`

${CT_MONITOR} -q 2> /tmp/CT.txt
ALLOWEDRADIOMODE=`grep "Allowed Radio Mode" /tmp/CT.txt | head -1 | awk '{print $4}' | tr -d [' ':]`
CAMPED_RAT=`grep "Camped RAT" /tmp/CT.txt | head -1 | awk '{print $3}' | tr -d [' ':]`
CARRIER=`grep "Operator" /tmp/CT.txt | head -1 | awk ' {print $2}' | tr -d [' ':]`
PREFERRED_RAT=`grep "^RAT:" /tmp/CT.txt | head -1 | awk '{print $2}' | tr -d [' ':]`
MCCMNC=`grep "^Operator Numeric Code:" /tmp/CT.txt | head -1 | awk '{print $4}' | tr -d [' ':]`
BB=`grep 'Firmware Version:' /tmp/CT.txt | tr -d 'Firmware Version:' | tr -d ' []'`
if [[ -z "$CTVERSION" ]]; then CTVERSION=`grep -i "CoreTelephony Version" /tmp/CT.txt | head -1 |awk '{print $3}' | tr -d [' ':]`; fi
# Check Perl
PERL=`which perl`
SNUM=`${GESTALT_QUERY} BasebandSerialNumber | awk '{print $3}' | tr -d ' ()'`

# OTHERS
DLCI_DEV_NODE="/dev/dlci.spi-baseband.extra_0"

if [ $HARDWARE == "N90" ] || [ $HARDWARE == "K94" ]  || [ $HARDWARE == "K48" ] || [ $HARDWARE == "N88" ]; then 
	HARDWARE_TYPE="ICE";
elif [ $HARDWARE == "K95" ] || [ $HARDWARE == "N92" ]; then 
	HARDWARE_TYPE="EUREKA_SPI";
else 
	HARDWARE_TYPE="EUREKA";
	if [ $HARDWARE == "N94" ]; then
		BASEBAND_TYPE="TREK"
	elif  [ $HARDWARE == "J2" ] || [ $HARDWARE == "J2a" ]; then
		BASEBAND_TYPE="MAV4"
	elif  [ $HARDWARE == "N41" ] || [ $HARDWARE == "N42" ] || [ $HARDWARE == "P102" ]|| [ $HARDWARE == "P103" ] || [ $HARDWARE == "P106" ] || [ $HARDWARE == "P107" ]; then
		BASEBAND_TYPE="MAV5"
	elif  [ $HARDWARE == "N48" ] || [ $HARDWARE == "N51" ] || [ $HARDWARE == "N53" ]|| [ $HARDWARE == "J72" ] || [ $HARDWARE == "J73" ] || [ $HARDWARE == "J76" ] || [ $HARDWARE == "J77" ]; then
		BASEBAND_TYPE="MAV78"
	else
		BASEBAND_TYPE="MAV78"
	fi
fi


### LOG PRINT STRINGS
commentLogPrint=" "
updateComments() {
	commentLogPrint="${commentLogPrint}$1::"
} 

if [[ ! -z "$CTVERSION" ]]; then  updateComments "${CTVERSION}"; fi
isAANSEnabled=2
isSleepEnabledLogPrint="AP_SLEEP = ENABLED"
isLocmonEnableLogPrint="LOCMON = DISABLED"
locationdLoggingLogPrint="LOCATIOND LOGGING = ENABLED"
powerLoggingLogPrint="POWER LOGGING = DISABLED"	

isPowerLogEnabled=`ls /Library/Logs/CrashReporter/Power* | grep -c Power`
if [ $isPowerLogEnabled -ne 0 ]; then  
	updateComments "PowerLog_ON"
	powerLoggingLogPrint="POWER LOGGING = ENABLED"	
fi

locationdLogging=`ls -rlt /var/root/Library/Caches/locationd/locationd* | grep -c locationd`
if [ $locationdLogging -eq 0 ]; then
	updateComments "GPSLog_OFF"
	locationdLoggingLogPrint="LOCATIOND LOGGING = DISABLED"	
fi

#changes for ABM TLF
if [ -f /var/wireless/Library/Preferences/com.apple.AppleBasebandManager.plist ];
then
   diagEnabled=`defaults read /var/wireless/Library/Preferences/com.apple.AppleBasebandManager "Trace::DIAG::Enabled"`
else
   diagEnabled=`grep DIAG::fEnabled= /private/var/wireless/Library/Preferences/csidata | grep -c "0x1"`
fi

if [ $diagEnabled -eq 1 ]; then 
	isDIAGLoggingLogPrint="DIAG_LOGGING = ENABLED";
	echo "DIAG Logging is enabled, so cannot check Auto_Answer"
	isAANSEnabled=2
	#updateComments "DIAG_ON"
else 
	isDIAGLoggingLogPrint="DIAG_LOGGING = DISABLED";
	updateComments "DIAG_OFF"
	echo "Not Checking Auto_Answer for MAV5"
	isAANSEnabled=2
	#isAANSEnabled=`ETLTool nvread 74 | egrep -c "01|02" `
	if [ ${BASEBAND_TYPE} == "TREK" ]; then
		isAANSEnabled=`ETLTool nvread 74 | grep "0000" | egrep -c "01|02" `
	fi
fi

isOOBEnabledLogPrint="OOB_REMOTE_WAKEUP = ENABLED";
isQMIoverUARTLogPrint="QMI_OVER_UART = ENABLED"
isResumeMissWorkaroundLogPrint="Workaround_For_Resume_Miss = ENABLED"
isPreSundance=`echo $APBUILD  | grep -c "9[A-D]"`
getLeaksFlag=`defaults read /System/Library/LaunchDaemons/com.apple.CommCenter EnvironmentVariables  | grep  MallocStackLogging | grep -c 1 `
if [ $getLeaksFlag -ne 0 ]; then  updateComments "LeaksEnabled"; fi
#getLeaksFlag=0

#if [ ${HARDWARE_TYPE} == "EUREKA" ] && [ $isPreSundance -eq 0 ]; then
#	isOOBEnabled=`/usr/sbin/nvram boot-args | grep -c hsic-debug-hsic-baseband-wake`
#	if [ $isOOBEnabled -gt 0 ]; then isOOBEnabledLogPrint="OOB_REMOTE_WAKEUP = ENABLED"; fi

#	isQMIoverUARTEnabled=`defaults read /var/wireless/Library/Preferences/com.apple.TelephonyIPCPreferences CommCenter | grep -c uart_supports_qmi`
#	if [ $isQMIoverUARTEnabled -gt 0 ]; then isQMIoverUARTLogPrint="QMI_OVER_UART = ENABLED"; fi

#	isResumeMissWorkaround=`defaults read /var/wireless/Library/Preferences/com.apple.TelephonyIPCPreferences hsic_num_resume_retries | grep -c "1"`
#	if [ $isResumeMissWorkaround -gt 0 ]; then isResumeMissWorkaroundLogPrint="Workaround_For_Resume_Miss = ENABLED"; fi
#fi


echo "Device Name: $DEVICENAME"
echo "AP: $APBUILD"
echo "Baseband: $BB"
echo "UDID: $UDID"
echo "SERIAL: $SERIAL"
echo "IMEI: $IMEI"
echo "MEID: $MEID"
echo "BB SNUM: $SNUM"
echo "Phone Number: $PHONE_NUMBER"
