#!/bin/sh
#################################################################################################
#                                                                                               #
#   ScriptName: SanityTestJx.sh                                                                 #
#                                                                                               #
#   Usage:      <path_to_Script>/SanityTestAll.sh                                               #
#                                                                                               #
#   Purpose:    This Scripts runs a data sanity test                                            #
#                                                                                               #
#   Author:     Jerome Jesu                                                                     #    
#   Contact:    jesu@apple.com                                                                  #
#   Revision:   v1 - Jerome Jesu - Merged scripts and reduced time taken for Registration and   #
#                           data availability checks                                            #
#   Revision:   v2 - Jerome Jesu - Merged N94 and J2 scripts. Add Voice calls and SMS           #
#   Revision:   v3 - Jerome Jesu - Added P10x, N4x and Automatic mode ( LTE for Data only)      #
#   Revision:   v4 - Jerome Jesu - UMTS can be 3/4G, option for SleepCycler                     #
#   Revision:   v6 - Jerome Jesu - Adding N51 and J72/6. Fixed Ping Verification                #
#   Revision:   v7 - Jerome Jesu - Adding prints for Baseband Crashes                           #
#   Revision:   v8 - Jerome Jesu - Adding options for DIAG logging and Phone Number             #
#   Revision:   v9 - Jerome Jesu - Move the Command-Line arguments to done in the beginning     #
#                                                                                               #
#################################################################################################

## Version v9
VERSION=v9

DoSleep=1
number=0
diagValue=0
volteEnabled=0
echo "\n\n "
LOOP_BACK="4089619342"
TESTCT=`which testCT`
ABMTOOL=`which abmtool`
userCarrierName=0

while getopts 'dhvn:wc:' OPTION
do
	case "$OPTION" in	
		d )	diagValue=1
			echo " #### ENABLING DIAG LOGGING"
			${ABMTOOL} diag enabled true;;
			
		c) userCarrierName=1
			carrierName="$OPTARG";;

		h )	echo " USAGE : "
			echo "   $0  [ -option ] [ ... ] " 
			echo "        -w                 : Disable Sleep"
			echo "        -d                 : Enable DIAG Logging"
			echo "        -v                 : Enable VoLTE"
			echo "        -n  <Phone Number> : Phone Number to be called"
			echo "        -h                 : Help or Print this"
			echo "        -c  <CarrierName>  : Carrier Name(Verizon/Sprint/ATT/...)"
			exit 2;;

		n )	number=1
			calledNumber="$OPTARG";;
			
		v ) volteEnabled=1
			echo " #### ENABLING VOLTE"
			$TESTCT -b automatic
			sleep 2
			${TESTCT} -c "*5005*467#";;
		
		w )	DoSleep=0; 
			echo " #### DISABLING AP SLEEP";;

		/?)	echo "INVALID OPTIONS.\n"; 
			echo " USAGE: $0  [ -w | -d | -h | -n {Phone Number} ] " ;
			exit 2;;
	esac
done
shift $(($OPTIND - 1))

if [ $number -eq 0 ]; then  
	CALLED_NUMBER=${LOOP_BACK}
else
	CALLED_NUMBER=$calledNumber
fi
echo " #### PHONE NUMBER TO BE CALLED - ${CALLED_NUMBER}"

if [ $diagValue -eq 0 ]; then
	${ABMTOOL} diag enabled false
fi

diagValue=`/usr/local/bin/coreautomationd -command "coreTelephony.isDIAGLoggingEnabled" 2>&1 | tail -1`
if [ $diagValue -eq 1 ]; then
	echo " #### DIAG LOGGING IS ENABLED"
else
	echo " #### DIAG LOGGING IS DISABLED"
fi
echo; echo;

source /AppleInternal/Library/Bundles/Stress/CellularTestCases.bundle/BasebandStressTests/config.sh
APBUILD=`${GESTALT_QUERY} -undecorated BuildVersion`
BB=`${GESTALT_QUERY} -undecorated BasebandFirmwareVersion`
HARDWARE=`${GESTALT_QUERY} -undecorated HWModelStr | sed 's/AP//g'`
DEVICETYPE=`${GESTALT_QUERY} -undecorated DeviceClass`

PING=`which ping`
DATACONTEXT=`which DataContext`
LOCKDOWN_QUERY=`which lockdown_query`
RUN_SC=`which SleepCycler`
CT_MONITOR=`which CoreTelephonyMonitor`
STREAMPERF=`which StreamPerf`
CT_GET_RESET_STATE=`which CTGetResetState`
EVENTER=`which eventer`
KILLALL=`which killall`
crashDir="/Library/Logs/CrashReporter/"
wirelessDir="/var/wireless/Library/Logs/CrashReporter/"
logsDir="/private/var/wireless/Library/Logs/CrashReporter/Baseband/"
logFiles="$logsDir/*csi.txt"
mobileLogs="/var/mobile/Library/Logs/CrashReporter/*.plist"
mobileDir="/var/mobile/Library/Logs/CrashReporter/"
csiLogsDir="/var/root/CsiLogs"

${CT_MONITOR} -q 2> /tmp/CT.txt
CAMPED_RAT=`grep "Camped RAT" /tmp/CT.txt | head -1 | awk -F'[][]' '{print $2}'`

if [ $userCarrierName -eq 0 ]; then
	CARRIER=`grep "Operator" /tmp/CT.txt | head -1 | awk -F'[][]' '{print $2}'`
else
	CARRIER=$carrierName
fi

minorBuildVersion=`echo $APBUILD | awk '{print substr($0,0,2)}'`
strBuildChar=`echo $APBUILD | awk '{print substr($0,3,1)}'`
volteRegLoop=0
if [ $volteEnabled -eq 1 ]; then
	while [ $volteRegLoop -lt 600 ]
	do
		ims_reg_status=`/usr/local/bin/coreautomationd -command "coreTelephony.IMSRegistrationStatus" 2>&1 | tail -1`
		volteRegLoop=`expr $volteRegLoop + 1`
		if [ $ims_reg_status -eq 0 ]; then
			echo " #### VoLTE is not supported in this hardware"
		elif [ $ims_reg_status -eq 1 ]; then
			echo " #### VoLTE is supported in this hardware, but not registered to IMS"
		elif [ $ims_reg_status -eq 2 ]; then
			echo " #### VoLTE supported, but SMS_ONLY"
		elif [ $ims_reg_status -eq 3 ]; then
			if [ $minorBuildVersion -ge 13 ]; then
				echo " #### VoLTE supported on both VOICE and SMS"
				break
			elif [ "$strBuildChar" == "F" ]; then
				echo " #### VoLTE supported on both VOICE and SMS"
				break
			elif [ "$strBuildChar" == "H" ]; then
				echo " #### VoLTE supported but VOICE Only"
			else
				echo " #### VoLTE supported but VOICE Only"
			fi
		elif [ $ims_reg_status -eq 4 ]; then
			if [ $minorBuildVersion -ge 12 ]; then
				echo " #### VoLTE supported but VOICE Only"
			else
				echo "### Invalid Return Value"
			fi
		else
			echo "### Invalid Return Value"
		fi
		sleep 1
	done
fi

if [ $volteRegLoop -ge 600 ]; then
	echo " #### Device is not able register to Network in 10 minutes"
	exit 2
fi
	
echo " #### CARRIER CHOSEN IS - ${CARRIER}"

URL="www.apple.com"
PINGCOUNT="10"
SMSSTRING="Hello. How Are You?"
SLEEPOFFSET=30
scriptname=`basename $0 | sed 's/.sh//g' `
smsCount=0
callCount=0
sleepCount=0
maxTimeToWait=90
sleep 5;

ResultsFile="/var/root/${scriptname}_${HARDWARE}_Report.txt"
rm -rf $csiLogsDir
mkdir $csiLogsDir

if [ $HARDWARE == "P107" ] || [ $HARDWARE == "P103" ] || [ $HARDWARE == "J2" ] || [ $HARDWARE == "N42" ]; then
	rats=( automatic evdo hybrid 1x lte 1x )
	indicators=( 4 3 3 2 4 2 )
elif [ $HARDWARE == "N64" ] || [ $HARDWARE == "N65" ]; then
    rats=( automatic lte umts )
    indicators=( 4 4 3 )
elif [ $HARDWARE == "D101" ] || [ $HARDWARE == "D111" ]; then
	rats=( automatic dualgsm gsm dualumts lte umts )
	indicators=( 4 3 2 3 4 3 )
elif [ $HARDWARE == "D10" ] || [ $HARDWARE == "D11" ] || [ $HARDWARE == "J128" ] || [ $HARDWARE == "N69" ]; then
	if [[ $CARRIER == *Verizon* ]] || [[ $CARRIER == *Sprint* ]]; then
		rats=( automatic evdo hybrid 1x lte 1x )
		indicators=( 4 3 3 2 4 2 )
	else
		rats=( automatic dualgsm gsm dualumts lte umts )
		indicators=( 4 3 2 3 4 3 )
	fi
elif [ $HARDWARE == "N51" ] || [ $HARDWARE == "J72" ] ||  [ $HARDWARE == "J76" ] ||  [ $HARDWARE == "N61" ] || [ $HARDWARE == "J86" ] || \
	[ $HARDWARE == "N56" ] || [ $HARDWARE == "E86" ] || [ $HARDWARE == "J96" ] || [ $HARDWARE == "J86m" ] || [ $HARDWARE == "J82" ] || \
	[ $HARDWARE == "J108" ] || [ $HARDWARE == "J97" ] || [ $HARDWARE == "J108" ] || [ $HARDWARE == "N66" ] || [ $HARDWARE == "N71" ] || \
	[ $HARDWARE == "J99" ] || [ $HARDWARE == "N66m" ] || [ $HARDWARE == "N71m" ] || [ $HARDWARE == "J99a" ]; then 
	if [[ $CARRIER == *Verizon* ]] || [[ $CARRIER == *Sprint* ]]; then
		rats=( automatic evdo hybrid 1x lte 1x )
		indicators=( 4 3 3 2 4 2 )
	else
		rats=( automatic dualgsm gsm dualumts lte umts )
		indicators=( 4 3 2 3 4 3 )
	fi
elif [ $HARDWARE == "N53" ] || [ $HARDWARE == "N48" ] ||  [ $HARDWARE == "J73" ] ||  [ $HARDWARE == "J77" ]; then 
	if [[ $CARRIER == *Verizon* ]] || [[ $CARRIER == *Sprint* ]]; then
		rats=( automatic evdo hybrid 1x lte 1x )
		indicators=( 4 3 3 2 4 2 )
	else
		rats=( automatic dualgsm gsm dualumts lte umts )
		indicators=( 4 3 2 3 4 3 )
	fi
elif [ $HARDWARE == "P102" ] || [ $HARDWARE == "P106" ] ||  [ $HARDWARE == "J2a" ] || [ $HARDWARE == "N41" ]; then 
	rats=( automatic dualgsm gsm dualumts lte umts )
	indicators=( 4 3 2 3 4 3 )
elif [ $HARDWARE == "N94" ] && [ ${CAMPED_RAT} == "Hybrid" ]; then 
	rats=( automatic 1x evdo hybrid )
	indicators=( 3 2 3 3 )
elif [ $HARDWARE == "N94" ] && [ ${CAMPED_RAT} == "UMTS" ]; then 
	rats=( automatic dualgsm gsm dualumts umts )
	indicators=( 4 3 2 3 3 )
else
	rats=( automatic dualgsm gsm dualumts umts )
	indicators=( 4 3 2 3 3 )
fi

getRegistrationStatus()
{
	/bin/rm /tmp/CT.txt
	echo `date` "$1: Dumping CoreTelephonyMonitorStats: "
	${CT_MONITOR} -q 2> /tmp/CT_${RAT}.txt
	egrep "Data Indicator:|Operator:|Registration Status:|Data 0 |Camped|Allowed Radio|Uplink|Downlink" /tmp/CT_${RAT}.txt

}

dPrintToSTATS()
{
	stringToPrint=$1; statsFile=$2;
	echo `date` ": $stringToPrint"
	if [ "$2" ]; then  echo `date` ": $stringToPrint" >> $statsFile; fi
}

endCallIfActive()
{
	${TESTCT} -x | grep "status"
	if [ $? -eq 0 ]; then ${TESTCT} -e; fi
	sleep 5
}

killHungProcess()
{
		sleep $2
		echo "*** $3 : killing $1 after $2 seconds."
		PIDS=`ps -A | grep "$1" | grep -v grep | awk '{print $1}' `
		echo " $3 : KILLING Processes -- $PIDS for $1"
        if [ -z "$PIDS" ]; then
            echo "$1: Process stopped"
        else
            kill -9 $PIDS
        fi
}

processCsiLogs()
{
	echo `date` ": _____PROCESSING CSI LOGS - $dcount _____"  >> $LOGSFILE
	totalCsiLogs=`ls $csiLogsDir/*csi* | wc -l | awk '{print $1}'`
	totalBasebandCrashes=`cat /tmp/crashReasons | grep "BBCrash_"| wc -l | awk '{print $1}'`
	totalBBLocationCrashes=`cat /tmp/crashReasons | grep "locationd PDS" | wc -l | awk '{print $1}'`
	totalModemBootup=`cat /tmp/crashReasons | grep -i "Modem Boot" | grep -i "failure" | wc -l | awk '{print $1}'`
	totalPowerLogs=`cat /tmp/crashReasons | grep -i "by Powerlog" | wc -l | awk '{print $1}'`
	totalHardResets=`cat /tmp/crashReasons | grep -i "HardReset" | grep -i "error" | egrep -v "locationd|ATCS" | wc -l | awk '{print $1}'`
	
	totalUSBErrors=`cat /tmp/crashReasons | grep -i "usb" | grep -i "error" | egrep -v "locationd|HardReset" | wc -l | awk '{print $1}'`
	totalUARTErrors=`cat /tmp/crashReasons | grep -i "uart" | grep -i "error" | grep -v "HardReset" | wc -l | awk '{print $1}'`
	totalTraceDiag=`cat /tmp/crashReasons | grep -i "DIAG" | grep -v "HardReset" | wc -l | awk '{print $1}'`
	
	totalLocationdErrors=`cat /tmp/crashReasons | grep -i "locationd" | grep -i "error" | grep -v "debug" | wc -l | awk '{print $1}'`
	totalTrafficChannelMismatch=`cat /tmp/crashReasons | grep -i "Traffic channel Call" | grep -i "mismatch" | wc -l | awk '{print $1}'`
	totalDataStalls=`cat /tmp/crashReasons | grep -i "Data stall on" | wc -l | awk '{print $1}'`
	totalModemResets=`cat /tmp/crashReasons | grep "modem reset" | wc -l | awk '{print $1}'`
	totalAtTimeouts=`cat /tmp/crashReasons | grep -i "timeout" | egrep "AT|ATCS" | grep -v "modem reset" | wc -l | awk '{print $1}'`
	totalASM=`cat /tmp/crashReasons | grep -i "Fatal Error"| egrep -i "SPI|ASM" | wc -l | awk '{print $1}'`
	totalTempTimeouts=`cat /tmp/crashReasons | grep "temperature update" | grep -v "modem reset" | wc -l | awk '{print $1}'`
	totalProxTimeouts=`cat /tmp/crashReasons | grep "Start/Stop Tx" |  wc -l | awk '{print $1}'`
	
	totalCallFailures=`cat /tmp/crashReasons | grep -i "call fail" | wc -l | awk '{print $1}'`
	totalCallDrops=`cat /tmp/crashReasons | grep -i "call drop"| wc -l | awk '{print $1}'`
	totalDumps=`cat /tmp/crashReasons | grep "Dump" | wc -l | awk '{print $1}'`
	totalUserDumps=`cat /tmp/crashReasons | grep "User" | wc -l | awk '{print $1}'`
	totalFTO=`cat /tmp/crashReasons | grep "FTO" | wc -l | awk '{print $1}' `
	totalAPCrashes=`echo "$CsiLogsFile" | perl -lne 'open (F, "$_"); $total = 0;
		while (<F>) { if ( /CommCenter/ || /locationd$/i  || /awdd$/i || /WirelessCoexManagerd/ && ! /Sandbox/i ) {
				($r, $APCrashes) = (split /,/)[0,1];
				if ( $r !~ /\QSandbox\E/) {$total += $APCrashes};
			} else { next; }
		}  print $total;  
	'  `

	totalBasebandCrashes=$(($totalBasebandCrashes + $totalBBLocationCrashes))
	totalBBResets=$(($totalAPCrashes + $totalBasebandCrashes + $totalHardResets + $totalPowerLogs + $totalModemBootup + $totalLocationdErrors + $totalDataStalls ))
	totalBBResets=$(($totalBBResets + $totalModemResets + $totalAtTimeouts + $totalTempTimeouts + $totalASM  + $totalTrafficChannelMismatch + $totalProxTimeouts ))
	totalBBResets=$(($totalBBResets + $totalUSBErrors + $totalUARTErrors + $totalTraceDiag ))
	# The above line can be removed if they are not applicable anymore post Innsbruck since they are only for N92/N90 and before.
	#totalBBResets=$(($totalAPCrashes + $totalModemResets + $totalBasebandCrashes + $totalAtTimeouts + $totalTempTimeouts + $totalASM + $totalTraceDiag + $totalLocationdErrors + $totalUSBErrors + $totalUARTErrors + $totalProxTimeouts + $totalDataStalls + $totalTrafficChannelMismatch + $totalPowerLogs + $totalModemBootup ))
	totalLogs=$(($totalBBResets + $totalCallFailures + $totalCallDrops + $totalDumps + $totalUserDumps + $totalFTO))
	totalOthers=$(($totalCsiLogs - $totalLogs))
	
	echo "\n ****************  LOG DETAILS:  *********************"
	echo " RESETS: USB:$totalUSBErrors, ATCS:$totalAtTimeouts, location:$totalLocationdErrors, TraceDIAG:$totalTraceDiag, Temp:$totalTempTimeouts"
	echo " CRASHES: BB Crash:$totalBasebandCrashes, Bootup:$totalModemBootup"
	echo " FAIL-$totalCallFailures,  DROPS-$totalCallDrops, DUMPS-$totalDumps, USERDUMPS-$totalUserDumps"
	echo " FTO-$totalFTO,  OTHERS-$totalOthers"
} 

#No need to dump logs for this, Dumping Logs is in main Logic
checkForRegistrationAndDataAvailability()
{
	technology=$1; INDICATOR=$2;
	isRegistered=0
	dataAvailability=0
	loopCount=0
	
	while  [ $isRegistered -eq 0 ]; do
		((loopCount++))
		getRegistrationStatus $technology
		result=`grep "Registration Status:" /tmp/CT_${RAT}.txt | grep -c -i Home`
		if [ $result -eq 0 ]; then
			echo "  $technology : $loopCount : Device is Not Registered to the network\n Waiting for another 10 seconds to check Registration status..."
			isRegistered=0
		else
			dPrintToSTATS "  $technology : Device is REGISTERED to the network after $loopCount tries" "$ResultsFile"
			isRegistered=1; break;
		fi
		sleep 10;
		if [ $loopCount -eq 10 ]; then break; fi
		
	done
	tempCampedNetwork=`grep "Camped" /tmp/CT_${RAT}.txt | awk '{print $3}' | tr -d [' ':] `
	if [ $tempCampedNetwork == "UMTS" ]; then  INDICATOR="3|4";  fi 
		
	loopCount=0
	while [ $dataAvailability -eq 0 ]; do
		
		((loopCount++))
		getRegistrationStatus $technology
		result=`grep "Data Indicator:" /tmp/CT_${RAT}.txt | grep -c -i None`	
		if [ $result -ge 1 ]; then
			echo "  $technology : $loopCount : Device is not READY for DataTest..\nWaiting for another 10 seconds to try again..."
			dataAvailability=0
		else
			result=`grep "Data Indicator:" /tmp/CT_$RAT.txt | egrep -c -i "$INDICATOR" `
			if [ $result -eq 0 ]; then 
				result=`grep "Data Indicator:" /tmp/CT_$RAT.txt`
				echo "  $technology : $loopCount : Device is not READY for DataTest..\n Current Technology = $result"
			else 
				dPrintToSTATS "  $technology : Device is READY for DataTest after $loopCount tries"   "$ResultsFile"
				dataAvailability=1; break;
			fi
		fi
		sleep 10;
		if [ $loopCount -eq 10 ]; then break; fi	
	done
	tempDataIndicator=`grep "Data Indicator:" /tmp/CT_${RAT}.txt | awk '{print $3}'`
}

DataTest()
{
		technology=$1
		dPrintToSTATS " ***** STARTING DATA TEST FOR $technology"    "$ResultsFile"
        echo "$technology : Data Context Up Test Start"        
        activatePDPContext
        runPingTest
        runDataDownloadTest
        bringDownDataContext
}


activatePDPContext()
{
        $DATACONTEXT up >& /tmp/DataContextStatus
        sleep 2
    
        result=`grep -c -i "PDP Context 0 is up" /tmp/DataContextStatus`
        if [ $result -eq 1 ]; then
            dPrintToSTATS  "  $technology : PDP Context Up Test \t [PASSED]"   "$ResultsFile"
        else    
            dPrintToSTATS  "  $technology : PDP Context Up Test \t [FAILED]"  "$ResultsFile"
            ${TESTCT}  -l  "$technology : PDP Context Up Test FAILED"
            sleep 30
        fi
        sleep 10
}


runPingTest()
{
        echo "$technology : Ping Test Start "
        $PING  -c $PINGCOUNT $URL >& /tmp/DataContextStatus
        sleep 40
        result=`egrep -c -i "100.0% packet loss|Unknown host" /tmp/DataContextStatus`
        if [ $result -eq 0 ]; then
            dPrintToSTATS  "  $technology : Ping Test for 10 pings\t [PASSED]"   "$ResultsFile"
        else    
            dPrintToSTATS  "  $technology : Ping Test \t [FAILED]"    "$ResultsFile"
            ${TESTCT}  -l  "$technology : Ping Test FAILED"
            sleep 30
        fi
        sleep 10
}        
 
 
runDataDownloadTest()
 {
        echo "$technology : Data Download Test Start - http://pttest.apple.com/1MB.txt "
        killHungProcess StreamPerf 200 $technology &
        dataThroughput=`${STREAMPERF} HTTP -MT 180 http://pttest.apple.com/1MB.txt | grep Average | awk '{ print $5}'`
        killHungProcess "sleep 200" 2 $technology
        isValidThroughput=`echo "$dataThroughput" | perl -lne ' if ( /^\d{1,3}[.]\d{1,5}/ && ! /^[0]{1,3}[.][0]{3,}/ && ! /^$/ ) { print "1"} else {print "0"}' `
        if [ $isValidThroughput -eq 1 ]; then
            dPrintToSTATS "  $technology : Data Download Test \t\t [PASSED]"   "$ResultsFile"
            dPrintToSTATS "  $technology : Data Throughput = $dataThroughput"   "$ResultsFile"
        else    
            dPrintToSTATS "  $technology : Data Download Test \t\t [FAILED]"   "$ResultsFile"
            dPrintToSTATS "  $technology : Data Throughput = $dataThroughput"   "$ResultsFile"
            ${TESTCT}  -l "$technology : Throughput = $dataThroughput. Data Download Test FAILED"
            sleep 30
        fi
        sleep 10
 }       
        
        
bringDownDataContext()
{
        echo "$technology : Data Context Down Test"
        $DATACONTEXT down >& /tmp/DataContextStatus
        result=`grep -c -i "Failed" /tmp/DataContextStatus`
        result2=`grep -c -i "Nothing to do." /tmp/DataContextStatus`
        if [ $result -eq 1 ] || [ $result2 -eq 1 ]; then
            dPrintToSTATS "  $technology : PDP Context Down Test \t [FAILED]"    "$ResultsFile"
            ${TESTCT}  -l  "$technology : PDP Context Down Test FAILED"
            sleep 30
        else
            dPrintToSTATS "  $technology : PDP Context Down Test \t [PASSED]"    "$ResultsFile"

        fi
        sleep 10
}

CallTest()
{	
	((callCount++));
	technology=$1
	rm /tmp/callstat.txt;
	
	dPrintToSTATS "  $technology : MO VOICE CALL $callCount START - 30 seconds "
    $TESTCT -c ${CALLED_NUMBER} >& /tmp/callstat.txt
	dPrintToSTATS "  $technology : Wait for 30 seconds before ending the call..."
	sleep 30
    grep "status Active" /tmp/callstat.txt; resultCall=$?; cat /tmp/callstat.txt; 
    if [ $resultCall -eq 0 ]; then
		if [[ $technology == "LTE" ]] || [[ $technology == "AUTOMATIC" ]]; then
			if [[ volteEnabled -eq 1 ]]; then
				${CT_MONITOR} -q 2> /tmp/CT.txt
				CAMPED_RAT=`grep "Camped RAT" /tmp/CT.txt | head -1 | awk '{print $3}' | tr -d [' ':]`
				if [[ $CAMPED_RAT != "1x" ]]; then
					dPrintToSTATS "  $technology : (VoLTE ENABLED) MO Voice Call Test \t [PASSED]"    "$ResultsFile" 
				else
					dPrintToSTATS "  $technology : (VoLTE ENABLED) MO Voice Call Test, Going Thru CS \t [FAILED]"    "$ResultsFile"
					${TESTCT}  -l  "$technology : (VoLTE ENABLED) MO Voice Call Test, Going Thru CS so FAILED"
					sleep 30
				fi
			else
				dPrintToSTATS "  $technology : MO Voice Call Test \t [PASSED]"    "$ResultsFile"
			fi
		else
			dPrintToSTATS "  $technology : MO Voice Call Test \t [PASSED]"    "$ResultsFile" 
		fi
	else
		dPrintToSTATS "  $technology : MO Voice Call Test \t [FAILED]"    "$ResultsFile"
		${TESTCT}  -l  "$technology : MO Voice Call Test Failed"
		sleep 30
	fi
	endCallIfActive;
	dPrintToSTATS "  $technology : MO VOICE CALL $callCount END"
	sleep 5;
}

SmsTest()
{
	technology=$1
	((smsCount++));
	PHONE_NUMBER=`${GESTALT_QUERY} -undecorated PhoneNumber 2>&1 | sed 's/[-]//g' | sed 's/ //g' | sed 's/[(]//g' | sed 's/[)]//g' | sed 's/[+][1]//g' `
    isValidNumber=` echo $PHONE_NUMBER | grep -c "Couldnotlookup" `
    if [ $isValidNumber -eq 1 ]; then  PHONE_NUMBER=${CALLED_NUMBER};    fi
	
	dPrintToSTATS "  $technology : SENDING MO SMS TO ${PHONE_NUMBER} "
    $TESTCT -s ${PHONE_NUMBER} "${PHONE_NUMBER} : $SMSSTRING " >& /tmp/smsstat.txt
    sleep 5
    
    grep "SMSSent PASS" /tmp/smsstat.txt; resultSms=$?; rm /tmp/smsstat.txt;    
    if [ $resultSms -eq 0 ]; then
    	dPrintToSTATS "  $technology : MO-MT SMS Test \t\t [PASSED]"    "$ResultsFile" 
    else
    	dPrintToSTATS "  $technology : MO-MT SMS Test \t\t [FAILED]"    "$ResultsFile" 
        ${TESTCT}  -l  "$technology : MO-MT SMS Test FAILED"
		sleep 10
    fi
}

checkResetState()
{
	${CT_GET_RESET_STATE} | grep "CommCenter in reset state";	
	if [ $? -eq 0 ]; then isBBResetReset=1;
	else isBBReset=0;
	fi
	dPrintToSTATS "  CheckResetState: isBBReset = $isBBReset."
}

readyToRunSleepCycler()
{
	timeToSleep=0
	maxTimeToWait=210
	isBBReset=0
	isPowerAsserted=0
	
	checkResetState
	
	while [ $isBBReset -eq 1 ]; 
	do
		dPrintToSTATS  "  Sleeping for 30 seconds before checking again."
		sleep 30;
		timeToSleep=$(($timeToSleep + 30));
		
		if [ $timeToSleep -ge $maxTimeToWait ]; then 
			dPrintToSTATS  ": Max Timer exceeded $maxTimeToWait seconds wait period."
			break; 
		fi
		dPrintToSTATS  "  Checking again after $timeToSleep seconds... since isBBReset = $isBBReset."
		checkResetState
		
	done
	dPrintToSTATS  "  readyToRunSleepCycler: isBBReset = $isBBReset"   "$ResultsFile" 
}

runSleepCyclerIfEnabled()
{
	if [ $DoSleep -ne 0 ]; then
		dPrintToSTATS " ***** STARTING SLEEPCYCLER FOR $technology"   "$ResultsFile"
		cp  $logFiles  $csiLogsDir/
		runSleepCycler
	fi
}

runSleepCycler()
{
	sleepInterval=$((RANDOM % 30 + $SLEEPOFFSET))
    dPrintToSTATS "  Check if we are READY to run SleepCycler..."
	readyToRunSleepCycler
	
	if [ $isBBReset -eq 0 ]; then
		sleep 2
		((sleepCount++))
		dPrintToSTATS "  $sleepCount. Sleepcycling 1 time -n 1 -s $sleepInterval"   "$ResultsFile" 
		${RUN_SC} -n 1 -s $sleepInterval;
		dPrintToSTATS "  $sleepCount. wake up from sleep"  "$ResultsFile" 
	else 
		dPrintToSTATS  "  Skipping SleepCycler since Baseband is resetting..."   "$ResultsFile" 
	fi
}


############################  START TESTS  ##########################
/bin/rm $ResultsFile
echo "##### Turning off WiFi..."
/usr/local/bin/coreautomationd -command "WiFi.off" > /tmp/WiFiOff.txt &
sleep 5;

dPrintToSTATS  "#######################################"  "$ResultsFile"
dPrintToSTATS  " #####  HARDWARE = $HARDWARE"  "$ResultsFile"
dPrintToSTATS  " #####  AP BUILD = $APBUILD"   "$ResultsFile"
dPrintToSTATS  " #####  BASEBAND = $BB"        "$ResultsFile"
dPrintToSTATS  " #####  CARRIER  = $CARRIER"   "$ResultsFile"
dPrintToSTATS  " #####  VERSION  = $VERSION"   "$ResultsFile"
dPrintToSTATS  "#######################################"  "$ResultsFile"

for (( i = 0 ; i < ${#rats[@]} ; i++ ))
do
 
	isRegistered=0
	dataAvailability=0
	RAT=${rats[i]}
	INDICATOR=${indicators[i]}
	technology=`echo $RAT | tr '[a-z]' '[A-Z]' `
	
	echo "  ##### RAT = $technology, Data Indicator = ${INDICATOR}G"
	dPrintToSTATS " ***** Selecting $technology RAT on the Device"    "$ResultsFile"
	dPrintToSTATS " $TESTCT -b $RAT"
	$TESTCT -b $RAT
	echo " Sleeping for 30 seconds..." 
	sleep 30
	checkForRegistrationAndDataAvailability $technology  $INDICATOR
	dPrintToSTATS " ******* $technology : Registration=$isRegistered -- $tempCampedNetwork, dataAvailability=$dataAvailability--$tempDataIndicator"   "$ResultsFile"
	
	if [ $isRegistered -eq 0 ]; then
			dPrintToSTATS " ***** SKIPPING $technology RAT since Device is not Registered - Registration=$isRegistered -- $tempCampedNetwork"    "$ResultsFile"
        	dPrintToSTATS "  $technology : ALL TESTS \t\t [FAILED]"    "$ResultsFile"
        	${TESTCT}  -l   "$technology : ALL TESTS FAILED - Device Not Registered"
	else
		
		if [ $dataAvailability -eq 0 ]; then
			dPrintToSTATS " ***** SKIPPING $technology RAT since DATA TEST is NOT POSSIBLE - Registration=$isRegistered -- $tempCampedNetwork, dataAvailability=$dataAvailability--$tempDataIndicator"    "$ResultsFile"
        	dPrintToSTATS "  $technology : DATA TESTS \t\t [FAILED]"    "$ResultsFile"
        	${TESTCT}  -l   "$technology : DATA TESTS FAILED - since no Data Indicator"
		else
			sleep 5
			runSleepCyclerIfEnabled
			sleep 5
			DataTest   $technology
			sleep 5
		fi
		
		runSleepCyclerIfEnabled
		
		if [[ $DEVICETYPE == "iPhone" ]] && [[ $RAT != "evdo" ]]; then
			if [[ $RAT != "lte" ]] || [[ volteEnabled -eq 1 ]]; then
				dPrintToSTATS " ***** STARTING VOICE AND SMS TEST FOR $technology"    "$ResultsFile"
       			CallTest   $technology
       			sleep 5
       			runSleepCyclerIfEnabled
       			sleep 5
       			SmsTest    $technology
       			sleep 5
			fi
		fi

		checkForRegistrationAndDataAvailability $technology  $INDICATOR
		dPrintToSTATS " ******* $technology : Registration=$isRegistered -- $tempCampedNetwork, dataAvailability=$dataAvailability--$tempDataIndicator"   "$ResultsFile"
		if [ $dataAvailability -ne 0 ] && [ $DoSleep -ne 0 ]; then
			runPingTest   $technology
			sleep 5
		fi
	
	fi
	
	echo " Sleeping for 5 seconds..." 
	sleep 5
	cp  $logFiles  $csiLogsDir/
	dPrintToSTATS " ***** END  ALL Tests for $technology \n\n#########################\n"    "$ResultsFile"
done


dPrintToSTATS " ***** SLEEP CYCLER Results "    "$ResultsFile"
grep TimeAsleep nohup.out  >> "$ResultsFile" 
dPrintToSTATS " \n\n ***** CRASHES SUMMARY #########################\n"    "$ResultsFile"
processCsiLogs
ls ${csiLogsDir}/*csi.txt
head -1 ${csiLogsDir}/*csi.txt  >> $ResultsFile

dPrintToSTATS " \n\n ***** CRASHES CORE-DUMP REASONS #########################\n"    "$ResultsFile"
grep "Crash at"  ${csiLogsDir}/*csi.txt   >>  $ResultsFile
dPrintToSTATS " \n\n ***** CRASHES SUMMARY END #########################\n"    "$ResultsFile"

if [ $DoSleep -eq 0 ]; then
	echo "\n\n ************************ Getting Crash Reasons from backup : "
	head -1 ${csiLogsDir}/*csi.txt
	grep "Crash at"  ${csiLogsDir}/*csi.txt	
fi

if [ $volteEnabled -eq 1 ]; then
	#Turn Off VoLTE
	${TESTCT} -c "#5005*467#"
fi

dPrintToSTATS " ***** DONE \n\n#########################\n"    "$ResultsFile"
dPrintToSTATS " DONE\n\n"

echo " #### **********************************************######\n"
echo " #### ***************** Test Summary ***************######\n"
echo " #### **********************************************######\n\n"

if [[ -e $ResultsFile ]]; then
    cat $ResultsFile
 fi
