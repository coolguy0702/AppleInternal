hkLogVersion=170503

hkdir=/var/mobile/Documents/HomeKit
hklog=$hkdir/HomeKitWatcher.log
hkmemlog=$hkdir/HomeKitMemoryWatcher.csv
prevKeys=$hkdir/tmp/HomeKitWatcher_prevKeys.log
currKeys=$hkdir/tmp/HomeKitWatcher_currKeys.log
currHome=$hkdir/tmp/HomeKitWatcher_currHome.log
prevHome=$hkdir/tmp/HomeKitWatcher_prevHome.log
crashDir=/var/mobile/Library/Logs/CrashReporter
mkdir -p $hkdir/pcap

function homekit()
{
	if [[ $2 != *"u"* ]]
	then
		curl -sk --connect-timeout 1 https://homekit.apple.com/scripts/HomeKitLogCollectionScript.sh > /tmp/tmpLocation && cp /tmp/tmpLocation /var/root/.profile && mkdir -p /AppleInternal/Library/PreferenceBundles/HomeKitInternalSettings.bundle && cp /tmp/tmpLocation /AppleInternal/Library/PreferenceBundles/HomeKitInternalSettings.bundle/HomeKitLogCollectionScript.sh && source /var/root/.profile && echo 'Hey! I successfully updated myself! :)'
	fi
	if [ -z "$1" ]; then
		echo "====================================================================="
		echo "Welcome to HomeKit Helper v$hkLogVersion"
		echo "File bugs to : Purple HomeKit Tools | 1.0"
		echo
		echo "homekit dumpLogs      | Dump Logs"
		echo "homekit enableLogs    | Enable Logging"
		echo "homekit enableLogs h  |   - Enable Bluetooth HCI Tracing"
		echo "homekit enableLogs m  |   - Enable Memory Allocation (Malloc) Logging"
		echo "homekit pcap          |   - Start recording a single tcpdump"
		echo "homekit pcaps         |   - Start recording rolling tcpdumps (5x 50MB)"
		echo "homekit memWatch      |   - Start HomeKit Memory Watcher"
		echo "homekit disableLogs   |   - Disable all logging"
		echo "homekit sanity        | Check the basics of a HomeKit setup"
		echo "homekit clear         | Clear on-disk homed cache and reload from cloud"
		echo "homekit watcher       | Start HomeKit Watcher"
		echo "homekit remoteTest    | Choose from a couple of remote testing options"
		echo "====================================================================="
	else
		case $1 in
			*"dumpLogs"*) hmLogs $2 "${*:3}" ;;
			*"enableLogs"*) enableHKlogs $2 ;;
			*"memWatch"*) echo "Watching..."; hkMemWatcher & ;;
			*"disableLogs"*) disableHKlogs ;;
			*"watcher"*) hkWatch ;;
			*"sanity"*) hmSanity ;;
			*"remoteTest"*) remoteScript ;;
			*"pcaps"*) startPCAP ;;
			*"clear"*) clearHomed ;;
			*"pcap"*) echo "Ctrl+C to stop" && tcpdump -w $crashDir/network-logs.pcap ;;
			*) homekit ;;
		esac
	fi
}
function startPCAP()
{
	echo "Recording rolling 5x 50MB tcpdumps, continues until reboot. Collect with a HomeKit log dump." 
	rm -rf /var/mobile/Documents/HomeKit/pcap
	nohup tcpdump -C 50 -W 5 -w /tmp/rolling_pcap &
}
function clearHomed()
{
	echo Backing up homed cache...
	cd /var/mobile/Library
	tar -cpzf /var/mobile/Library/homed-backup-`date "+%Y-%m-%dT%H.%M.%S"`.tgz ./homed/
	echo Copying backup to CrashReporter directory...
	cp homed*.tgz /var/mobile/Library/Logs/CrashReporter/
	cd - >/dev/null 2>&1
	echo Clearing out homed\'s cache...
	rm -rf /var/mobile/Library/homed/*
	echo Relaunching homed...
	killall -9 homed && killall -9 homed
	homeutil v
}
function hmSanity()
{
	echo
	echo "=>>= HomeKit Version"
	homeutil v
	echo
	echo "=>>= Roots on device"
	darwinup list
	echo
	echo "=>>= WiFi Network (Should be same as wifi for accessories)"
	wl assoc 2>&1 | sed -n '1p'
	echo "IP addresses on this device:"
	ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2
	ping -c 3 -t 5 www.apple.com
	echo
	echo "=>>= IDS Registration (Should show Active & Enabled : YES)"
	idstool list | grep -A 6 "Service:  com.apple.private.alloy.willow"
	echo
	echo "=>>= Known Devices (Should show any other devices on same iCloud)"
	idstool devices -s com.apple.private.alloy.willow | grep Name
	echo
	echo "=>>= Home Key (Should be only one, same on all device of same iCloud)"
	security item class=genp,sync=1,agrp=com.apple.hap.pairing
	echo
	echo "=>>= DNS-SD services (All devices on local network appear here)"
	{ dns-sd -B _hap & }
	sleep 3
	killall -9 dns-sd &> /dev/null
}
function hmLogs()
{
	local timestamp=$(date "+%Y-%m-%dT%H.%M.%S")
	local deviceName=$(scutil --get HostName)
	local logsFolderName="HomeKitLogs-$deviceName-$timestamp"
	local logsFolderPath="$crashDir/$logsFolderName"
	local hmInfo="$logsFolderPath/_HomeInfo.log"
	local hmLog="$logsFolderPath/_HomeKit.log"
	local siriLog="$logsFolderPath/_assistant.log"
	local siriLogSum="$logsFolderPath/_assistant-summary.log"
	local miscLog="$logsFolderPath/_misc.log"
	local buildVer=$(gestalt_query BuildVersion | awk -F'"' '{ print substr($2,0,2) }')

	echo "====================================================================="
	echo "HomeKit Log Collection Script v$hkLogVersion"
	echo "File bugs to : Purple HomeKit | 1.0"
	
	if [ -z "$1" ]
	then
		echo "Dump options:"
		echo "   q = Quick       (Excludes a sysdiagnose)"
		echo "   s = Sysdiagnose (Now collected by default!)"
		echo "   w = WiFi        (Connectivity, Remote, Pairing)"
		echo "   i = IDS         (Home Sharing, Remote, Watch)"
		echo "   d = DiscoveryD  (Pairing, Reachability)"
		echo "   k = Keychain    (Keys never arrive)"
		echo "   l = Location    (Geofence / iBeacon Triggers)"
		echo "   p = Power       (Performance, Power drain)"
		echo "   c = Cache       (All HomeKit files on disk)"
		echo "   a = All         (Rarely needed)"
    	read -p "Dump logs? : " dumpThis
		# Secret Commands
		# f = Provide a file path to dump the logs to
		# n = Skip log collection altogether
		# u = Don't attempt to update /var/mobile/.profile
		# z = Provide a timestamp to start log collection from (New logging only)
	else
		local dumpThis=$1
	fi
	commentText=$2
	
	if [[ $dumpThis == *"n"* ]]
	then
		echo Skipping...
		exit
	fi
	
	if [[ $dumpThis == *"f"* ]]
	then
		commentText=$(echo $2 | sed 's/[^ ]* //')		# All text after first space
		logsFolderPath=$(echo $2 | awk '{print $1;}')	# All text before first space
		logsFolderName=$(basename "$logsFolderPath")	# Should remove extension
		logsFolderName=${logsFolderName%.*}				# Definitely removes extensions
		logsFolderPath="$(dirname "$logsFolderPath")/$logsFolderName"
		echo "Okie dokie, output file will be saved as : $logsFolderPath.tgz"
		
		# Clear the directory if anything exists...
		mkdir -p /tmp/OldHomeKitLogs/
		cp -a $logsFolderPath /tmp/OldHomeKitLogs/ >/dev/null 2>&1
		cp -a $logsFolderPath.tgz /tmp/OldHomeKitLogs/ >/dev/null 2>&1
		rm $logsFolderPath.tgz >/dev/null 2>&1
		rm -rf $logsFolderPath >/dev/null 2>&1
		rm -rf /tmp/$logsFolderName >/dev/null 2>&1
		
		# Re-define all paths as things have moved....
		local hmInfo="$logsFolderPath/HomeInfo.log"
		local hmLog="$logsFolderPath/HomeKit.log"
		local siriLog="$logsFolderPath/assistant.log"
		local siriLogSum="$logsFolderPath/assistant-summary.log"
		local miscLog="$logsFolderPath/misc.log"
	fi
	
	if [ -z "$commentText" ]
	then
    	read -p "Add a comment? : " commentText
    else
    	if [[ $dumpThis != *"f"* ]]; then
			local commentText="${*:2}"
		fi
		echo "Comment : $commentText"
	fi
	
	if [[ $dumpThis == *"a"* ]]
	then
		local dumpThis="swilkpc"
	fi

	if [[ $dumpThis == *"i"* ]]; then
		if [[ "$buildVer" > "13" ]]; then 
			dumpThis=$(echo $dumpThis | tr i s)
		fi
	fi

	if [ -n "$commentText" ]; then
		mkdir -p $logsFolderPath/Retired
		echo $commentText > $logsFolderPath/_Comment.txt
	fi

	if [ -z "$1" ]
		then
		echo "You can also run this script with arguments, ex :"
		echo "    homekit dumpLogs q Short problem description here"
	fi
	echo "====================================================================="
	
	# Get ready...
	mkdir -p $logsFolderPath/Retired/
	touch $hmLog $siriLog $miscLog $hmLog $hmInfo $hklog
	echo "$(date '+%Y-%m-%d %H:%M:%S') | HomeKit  | Logs dumped. Reason : $commentText" >> $hklog
	
	# Grabbing some Stackshots
	if [ "$EUID" -eq 0 ]; then
		echo Collecting Stackshots...
		mkdir -p $logsFolderPath/Stacks
		homedPID=$(pgrep homed)
		crstackshot -p $homedPID >/dev/null 2>&1
		crstackshot -p $homedPID >/dev/null 2>&1
		crstackshot -p $homedPID >/dev/null 2>&1
		mv $crashDir/stacks+homed* $logsFolderPath/Stacks/
	fi
	
	# Log the version of iOS and homed	
	echo Collecting Device Information...
	syslog -B > $logsFolderPath/sys.log
	sample homed 2 -mayDie -file $logsFolderPath/homed.sample.txt >/dev/null 2>&1
	scutil --get HostName >> $miscLog
	gestalt_query ProductType HWModelStr SerialNumber BuildVersion UniqueDeviceID ReleaseType RegionInfo >> $miscLog
	echo "hmLogs : $hkLogVersion" >> $miscLog
	wl assoc 2>&1 | sed -n '1p' >> $miscLog
	ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2 >> $miscLog
	testCT -b active >> $miscLog 2>&1
	ping -c 3 -t 5 apple.com >> $miscLog 2>&1
	homeutil version >> $miscLog
	darwinup list >> $miscLog

	# Dump the Device usage information
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo Device Resource Usage >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo ">> CPU & More >>" >> $miscLog
	top -o cpu -l 2 -n 5 | tail -n 15 >> $miscLog
	echo ">> Disk Usage >>" >> $miscLog
	df -kh >> $miscLog

	# Dump the accounts logged into
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo Account information >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	accounts_tool listAccounts >> $miscLog

	# Dump the IDS information
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo IDS status >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo idstool list | grep -A28 willow >> $miscLog
	idstool list | grep -A28 willow >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo idstool devices -s com.apple.private.alloy.willow >> $miscLog
	idstool devices -s com.apple.private.alloy.willow >> $miscLog

	# Collect dns-sd logs
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo dns-sd output >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo "$ dns-sd -B _hap" >> $miscLog
	{ dns-sd -B _hap >> $miscLog & } 2>/dev/null
	sleep 1
	echo "killall -9 dns-sd" | at now &> /dev/null
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo "$ dns-sd -Z _hap" >> $miscLog
	{ dns-sd -Z _hap >> $miscLog & } 2>/dev/null
	sleep 1
	echo "killall -9 dns-sd" | at now &> /dev/null
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo "$ dns-sd -B _homekit" >> $miscLog
	{ dns-sd -B _homekit >> $miscLog & } 2>/dev/null
	sleep 1
	echo "killall -9 dns-sd" | at now &> /dev/null
	
	# Dump the MobileAsset configuration
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo MobileAsset configuration >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	defaults read com.apple.MobileAsset >> $miscLog
	
	# Dump the Bluetooth state 
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo Bluetooth State >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	BTReporter >> $miscLog 2>&1 
	
	# Dump the accounts logged into and more
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo Account Information, Continued  >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	accounts_tool listAccountsForType com.apple.account.AppleAccount >> $miscLog
	
	# Dump the Keychain configuration
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo Security Sync configuration >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo ">> security sync -i >>" >> $miscLog
	security sync -i >> $miscLog
	echo ">> security sync -D >>" >> $miscLog
	security sync -D >> $miscLog
	
	# Dump the LaunchCTL configuration
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo Launchctl configuration >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	launchctl print system/com.apple.homed >> $miscLog
	cp /var/log/com.apple.xpc.launchd/launches.current.log $logsFolderPath
	
	# Dump the Defaults configuration
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	echo All defaults on device >> $miscLog
	echo ">>>>>>>>>>>>>>>>" >> $miscLog
	login -f mobile defaults read >> $miscLog
	login -f mobile defaults read -g >> $miscLog
	
	echo Collecting HomeKit Logs...
	homeutil version >> $hmInfo
	# Collect the HAP keychain items
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo HomeKit Keychain items >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo security item class=genp,sync=1,agrp=com.apple.hap.pairing >> $hmInfo
	security item class=genp,sync=1,agrp=com.apple.hap.pairing >> $hmInfo 2>&1
	echo security item class=genp,sync=0,agrp=com.apple.hap.pairing >> $hmInfo
	security item class=genp,sync=0,agrp=com.apple.hap.pairing >> $hmInfo 2>&1
	echo security item class=genp,sync=0,agrp=com.apple.hap.metadata >> $hmInfo
	security item class=genp,sync=0,agrp=com.apple.hap.metadata >> $hmInfo 2>&1
	echo ">> security sync -i and security sync -D output in misc.log" >> $hmInfo

	# Collect home configuration
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo Home Configuration >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	homeutil dump-all >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo Home Invites >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	homeutil manage-invites -l >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo Homed State >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	homeutil state-dump >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo Homed State -a >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	homeutil state-dump -a >> $hmInfo
	
	# Collect Process information
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo Process Info >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	launchctl procinfo `pgrep homed` >> $hmInfo
	
	# Collect homed memory information
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo vmmap -v homed >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	vmmap -v homed >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo leaks homed >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	leaks homed >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo heap -guessNonObjects homed >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	heap -guessNonObjects homed >> $hmInfo

	# Collect homed memory information
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo vmmap -v Home >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	vmmap -v Home >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo leaks Home >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	leaks homed >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	echo heap -guessNonObjects Home >> $hmInfo
	echo ">>>>>>>>>>>>>>>>" >> $hmInfo
	heap -guessNonObjects Home >> $hmInfo
	
	# Collect metadata information
	if [[ "$buildVer" > "12" ]]; then 
		homeutil write-metadata -a -d $logsFolderPath/hapDefinitions.plist >/dev/null 2>&1
	fi

	# Collate HomeKit logs
	cp $crashDir/HomeKitHeap* $logsFolderPath/ >/dev/null 2>&1
	mv $crashDir/DiagnosticLogs/Home*.gz $logsFolderPath/Retired >/dev/null 2>&1
	gunzip $logsFolderPath/Retired/*.gz >/dev/null 2>&1
	cp $crashDir/DiagnosticLogs/Retired/Home* $logsFolderPath/Retired >/dev/null 2>&1
	cat $logsFolderPath/Retired/* > $logsFolderPath/_HomeKit-Retired.log 2>&-
	mkdir $crashDir/DiagnosticLogs/Retired >/dev/null 2>&1
	for log in $crashDir/DiagnosticLogs/Home*
	do
		echo ">>>>>>>>>>>>>>>>" >> $hmLog
		echo $log >> $hmLog
		echo ">>>>>>>>>>>>>>>>" >> $hmLog

		cat $log >> $hmLog
	done
	for file in `ls -dt $crashDir/DiagnosticLogs/Home* | awk 'NR>1'`
		do mv "$file" "$crashDir/DiagnosticLogs/Retired"; done
	rm -rf $logsFolderPath/Retired
	
	# Collect HomeKit Watcher info
	sed "s/$/$(printf '\r\n')/" $hkdir/HomeKitWatcher.log > $logsFolderPath/_HomeKitWatcher.log
	cp $hkdir/HomeKitMemoryWatcher.csv $logsFolderPath/ >/dev/null 2>&1
	cp -R $hkdir/HomeDiffs $logsFolderPath/ >/dev/null 2>&1
	cp -R $hkdir/KeyDiffs $logsFolderPath/ >/dev/null 2>&1
	cp -R $hkdir/Samples $logsFolderPath/ >/dev/null 2>&1

	# Collect HomeKit Caches
	if [[ $dumpThis == *"c"* ]]
	then
		echo Collecting HomeKit Caches...
		mkdir -p $logsFolderPath/Caches/
		cp -rf /var/mobile/Library/Caches/com.apple.homed $logsFolderPath/Caches/
		cp -rf /var/mobile/Library/Caches/com.apple.HomeKit $logsFolderPath/Caches/
		cp -rf /var/mobile/Library/Caches/com.apple.Home $logsFolderPath/Caches/
		cp -rf /var/mobile/Library/homed $logsFolderPath/Caches/
	fi

	# Grab AWD Metrics
	#mkdir -p $logsFolderPath/AWD/
	#cp /var/wireless/Library/Logs/awd/* $logsFolderPath/AWD/ >/dev/null 2>&1
	#cp /var/wireless/awdd/staging/* $logsFolderPath/AWD/ >/dev/null 2>&1
	#cp /var/mobile/Library/Logs/awd/awd-homed.log $logsFolderPath/AWD >/dev/null 2>&1
	#gunzip $logsFolderPath/AWD/*.gz >/dev/null 2>&1
	cp /var/mobile/Library/Logs/awd/awd-homed.log $logsFolderPath >/dev/null 2>&1

	# Collect Sysdiagnose
	if [[ $dumpThis == *"q"* ]]
	then
		# Grabbing new syslog thing
		echo Collecting System Log...
		log collect --output $logsFolderPath/syslog-$deviceName-$timestamp.logarchive >/dev/null 2>&1
	else
		echo Collecting Sysdiagnose...
		echo | sysdiagnose -f $logsFolderPath >/dev/null 2>&1
	fi

	# Collect Siri logs
	if ls $crashDir/Assistant/assistant_*log 1> /dev/null 2>&1; then
		echo Collecting Siri Logs...
		assistant_tool listAccounts >> $siriLog
		mkdir $crashDir/Assistant/Retired >/dev/null 2>&1
		for log in $crashDir/Assistant/assistant_*log 
		do
			echo ">>>>>>>>>>>>>>>>" >> $siriLog
			echo $log >> $siriLog
			echo ">>>>>>>>>>>>>>>>" >> $siriLog
			
			cat $log >> $siriLog
		done
		for file in `ls -dt $crashDir/Assistant/assistant_*log | awk 'NR>1'`
			do mv "$file" "$crashDir/Assistant/Retired"; done
	fi
	
	# Prepare Siri Summary
	assistant_tool listAccounts > $siriLogSum
	echo ">>>>>>>>>>>>>>>>" >> $siriLogSum
	grep "Assistant Loaded Version:" $siriLog >> $siriLogSum
	echo ">>>>>>>>>>>>>>>>" >> $siriLogSum
	echo "Utterances and Responses" >> $siriLogSum
	echo ">>>>>>>>>>>>>>>>" >> $siriLogSum
	grep "  Recognition Text\|Finished speaking" $siriLog >> $siriLogSum
	echo ">>>>>>>>>>>>>>>>" >> $siriLogSum
	echo "HomeKit Events (Response includes only 2x trailing lines)" >> $siriLogSum
	echo ">>>>>>>>>>>>>>>>" >> $siriLogSum
	grep -A2 "Incoming Siri command\|Response for Siri command" $hmLog >> $siriLogSum

	# Grab Tunnel logs
	if ls /var/mobile/Library/Logs/HomeKitTunnel/*log 1> /dev/null 2>&1; then
		echo Collecting Tunnel Logs...
		cp -R /var/mobile/Library/Logs/HomeKitTunnel $logsFolderPath/ >/dev/null 2>&1
		rm `ls -dt /var/mobile/Library/Logs/HomeKitTunnel/* | awk 'NR>1'` >/dev/null 2>&1
	fi
	
	# Grab HAK logs
	if ls /var/mobile/Library/Logs/HAPAccessoryKit/*log 1> /dev/null 2>&1; then
		echo Collecting HAK Logs...
		cp -R /var/mobile/Library/Logs/HAPAccessoryKit $logsFolderPath/ >/dev/null 2>&1
		rm `ls -dt /var/mobile/Library/Logs/HAPAccessoryKit/* | awk 'NR>1'` >/dev/null 2>&1
	fi
	
	# Grab HMCata.logs
	echo Collecting HMCata.logs...
	mkdir -p $logsFolderPath/HMCatalog
	for f in `find /var/mobile/Containers/ | grep "HMCatalog2_"`; 
		do cp "$f" $logsFolderPath/HMCatalog
	done
	for f in `find /private/var/mobile/Containers/ | grep "HomeKitSample_"`; 
		do cp "$f" $logsFolderPath/HMCatalog
	done	
	
	# Grab Salix logs
	echo Collecting Salix Logs...
	mkdir -p $logsFolderPath/Salix
	for f in `find /var/mobile/Containers/ | grep "SalixLog"`; 
		do cp "$f" $logsFolderPath/Salix
	done
	
	# Collect Bluetooth logs
	echo Collecting Bluetooth Logs...
	killall -USR1 BTServer
	sleep 1
	cp -R /var/mobile/Library/Logs/Bluetooth $logsFolderPath/ >/dev/null 2>&1
	mv $crashDir/BluetoothDiagnostics/* $logsFolderPath >/dev/null 2>&1
	#gunzip $logsFolderPath/Bluetooth/*.gz >/dev/null 2>&1

	# Collect IDS logs
	if [[ $dumpThis == *"i"* ]]
	then
		echo Collecting IDS Logs...
		mv $crashDir/IDS/* $logsFolderPath >/dev/null 2>&1
		idstool dump >/dev/null 2>&1
		local sleepTime=120
		while [ ! -f $crashDir/IDS/*.zip -a $sleepTime -gt 0 ] ; do sleep 1 ; ((sleepTime--)) ; done
	fi
	mv $crashDir/IDS/* $logsFolderPath >/dev/null 2>&1
	
	# Collect DiscoveryD logs
	if [[ $dumpThis == *"d"* ]]; then echo Collecting DiscoveryD Logs... ; fi
	if [[ $dumpThis == *"d"* && $dumpThis != *"i"* && $dumpThis != *"w"* ]]
	then
		echo | get-mobility-info >/dev/null 2>&1
	fi
	mv /Library/Logs/CrashReporter/mobility*.tar $logsFolderPath >/dev/null 2>&1
	mv $crashDir/bonjour.pcap $logsFolderPath >/dev/null 2>&1
	mv $crashDir/network-logs.pcap $logsFolderPath >/dev/null 2>&1
	(cd /tmp/ && for f in rolling_pcap*; do cp "$f" $logsFolderPath/"$f.pcap"; done)
		
	# Collect CloudKit logs
	echo Collecting CloudKit Logs...
	mkdir -p $logsFolderPath/CloudKit
	mv $crashDir/DiagnosticLogs/com.apple.cloudkit.asl/*.asl $logsFolderPath/CloudKit/ >/dev/null 2>&1
	
	# Collect iCloud Keychain logs
	if [[ $dumpThis == *"k"* ]]; 
	then
		echo Collecting Keychain Logs...
		/usr/local/sbin/ckcdiagnose.sh >/dev/null 2>&1
	fi
	mv /Library/Logs/CrashReporter/ckcdiagnose*.tgz $logsFolderPath >/dev/null 2>&1
	
	# Collect WiFi logs
	if [[ $dumpThis == *"w"* ]]
	then
		echo Collecting WiFi Logs...
		mkdir -p $logsFolderPath/WiFi
  		collectWiFiDebugInfo.sh >/dev/null 2>&1
		mv $crashDir/WiFi/* $logsFolderPath/WiFi >/dev/null 2>&1
	fi
	
	# Collect securityd logs
	echo Collecting Security Logs...
	mkdir -p $logsFolderPath/securityd/
	mv $crashDir/DiagnosticLogs/security* $logsFolderPath/securityd/ >/dev/null 2>&1
	gunzip $logsFolderPath/securityd/*.gz >/dev/null 2>&1
	
	# Collect Location logs
	if [[ $dumpThis == *"l"* ]]
	then
		echo Collecting Location Logs...
		mkdir -p $logsFolderPath/Location/
		cp /var/root/Library/Caches/locationd/locationd.log $logsFolderPath/Location/ >/dev/null 2>&1
		cp /var/root/Library/Caches/locationd/logs/*.log $logsFolderPath/Location/ >/dev/null 2>&1
	fi
	
	# Collect Power logs
	if [[ $dumpThis == *"p"* ]]
	then
		echo Collecting Power Logs...
		/usr/local/bin/PLLog -Q SafeLogFile -c path="$logsFolderPath/powerlog_$timestamp.PLSQL" >/dev/null 2>&1
	fi
	
	# Grabbing the crashes...
	mkdir -p $logsFolderPath/Crashes/
	cp $crashDir/*.ips $logsFolderPath/Crashes/ >/dev/null 2>&1

	# Bundle it up
	echo Preparing the goods...
	find $logsFolderPath -type l -delete
	find $logsFolderPath -type f -empty -delete
	find $logsFolderPath -type d -empty -delete
	cd $logsFolderPath/../
	tar cfzp $logsFolderName.tgz $logsFolderName/* && echo Saved : $logsFolderName.tgz
	cd -  >/dev/null 2>&1
	if [ -f $logsFolderPath.tgz ]; then mv $logsFolderPath /tmp/ ; else echo Saved : $logsFolderName  ; fi

	echo "====================================================================="
}

function hkWatch ()
{
	# Note: Due to the nature of monitoring multiple files simultaneously
	# the events in the combined log will not necessarily be in proper order.
	mkdir -p $hkdir/tmp
	touch $hklog $currHome
	sleep 1
	[[ `ps -f|grep script|grep homeutil.txt|grep -v grep` ]] || (
	mkdir -p $hkdir/HomeDiffs
	mkdir -p $hkdir/KeyDiffs
	mkdir -p $hkdir/Samples
	#hKill
	echo "Starting up the watchers..."
	if [ -f /usr/local/bin/assistant_tool ]; then
    	assistant_tool enableLogging 1
    	assistant_tool listAccounts >/dev/null 2>&1
    	siriWatcher &
    fi
    hkRoller &
	homeutilWatcher &
	wifiWatcher &
	hkWatcher &
	#hkMemWatcher &
	homeDiff
	) &
	disown
	sleep 2
	echo "I'm watching..."
	tail -Fn0 $hklog
}
function hKill ()
{
	echo "Murdering previous sessions..."
	killall -9 siriWatcher
	killall -9 hkWatcher
	killall -9 homeutilWatcher
	killall -9 wifiWatcher
	killall -9 hkMemWatcher
	killall -9 tail
	killall -9 homeutil
	killall -9 script
}
function siriWatcher ()
{
	local info
	while [ ! -f $crashDir/Assistant/assistant-latest.log ] ; do sleep 1 ; done
	tail -F -n0 $crashDir/Assistant/assistant-latest.log | grep --line-buffered "Recognition Text\|utterance: \"\|HMAssistantSyncHome Finishing sync" | while read line ; do
		timestamp=$(date "+%Y-%m-%d %H:%M:%S")
		case $line in
			*"utterance: \""*)
				info=$(echo $line | awk -F\" '{print $(NF-1)}' | xargs)
				echo "$timestamp | Siri     | User typed \"$info\"" >> $hklog
				;;
			"Recognition Text"*)
				info=$(echo $line | awk -F\" '{print $(NF-1)}' | xargs)
				echo "$timestamp | Siri     | User spoke \"$info\"" >> $hklog
				;;
			*"HMAssistantSyncHome Finishing sync"*)
				echo "$timestamp | Siri     | Sync Completed" >> $hklog
				;;
			*) 
				continue;
				;;
		esac
	done
}
function homeutilWatcher ()
{
	local tmpFile=$hkdir/tmp/homeutil.txt
	rm -f $tmpFile && touch $tmpFile
	local hklog=$hkdir/HomeKitWatcher.log
	script -aq -t 0 $tmpFile homeutil -i -m > /dev/null 2>&1 &
	tail -fn0 $tmpFile | while read line ; do
		echo "                    | homeutil | $line" >> $hklog
	done
}
function wifiWatcher ()
{
	local info
	while [ ! -f /Library/Logs/wifi.log ] ; do sleep 1 ; done
	tail -F -n0 /Library/Logs/wifi.log | grep --line-buffered "Joined:\|Device powering OFF" | while read line ; do
		timestamp=$(date "+%Y-%m-%d %H:%M:%S")
		case $line in
			*"Joined"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | WiFi     | Joined: $info" >> $hklog
				sleep 8
				homeDiff && wait
				;;
			*"OFF"*)
				echo "$timestamp | Wifi     | Disconnected" >> $hklog
				sleep 8
				homeDiff && wait
				;;
			*) 
				continue;
				;;
		esac
	done
}
function hkWatcher ()
{
	while [ ! -f $hkdir/HomeKit-latest.log ] ; do sleep 1 ; done
	local info
	tail -Fn0 $hkdir/HomeKit-latest.log | while read line ; do
		timestamp=$(date "+%Y-%m-%d %H:%M:%S")
		case $line in
			*"[AWD] EventMetric -- Add home:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User added home: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Remove home:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User removed home: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Add room:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User added room: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Remove room:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User removed room: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Add zone:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User added zone: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Remove zone:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User removed zone: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Add action set:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User added action set: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Remove action set:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User removed action set: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Add service group:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User added service group: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Remove service group:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User removed service group: $info" >> $hklog
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Add user:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | Adding shared user: $info" >> $hklog
				homeDiff && wait
				;;
			*"Removed user:"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | Removed shared user: $info" >> $hklog
				homeDiff && wait
				;;
			*"Uploaded data to cloud"*)
				echo "$timestamp | HomeKit  | iCloud Sync Completed" >> $hklog
				homeDiff && wait
				;;
			*"Posted sync data changed notification 0"*)
				echo "$timestamp | HomeKit  | Sync will happen soon..." >> $hklog
				homeDiff && wait
				;;
			*"home.config size"*)
				homeDiff && wait
				;;
			*"[AWD] EventMetric -- Remove accessory"*)
				info=$(echo $line | cut -d":" -f5 | xargs)
				echo "$timestamp | AWD      | User removed accessory: $info" >> $hklog
				homeDiff && wait
				;;
			*"Accessory manager received request to start pairing accessory"*)
				info=$(echo $line | cut -d"=" -f3 | cut -d"," -f1 | xargs)
				echo "$timestamp | AWD      | Adding accessory: $info" >> $hklog
				homeDiff && wait
				;;
			*"Spinning up remote access"*)
				info=$(echo $line | cut -d"=" -f2 | cut -d"," -f1 | xargs)
				echo "$timestamp | HomeKit  | Attempting remote access for home: $info" >> $hklog
				homeDiff && wait
				;;
			*"Updating active controller identifier"*)
				pidDiff && wait
				;;
			*"kResetConfigRequestKey"*)
				echo "$timestamp | HomeKit  | Reset Configuration" >> $hklog
				sleep 1
				homeDiff && wait
				;;
			*)
				continue;
				;;
		esac
		#echo "                     | $line"
	done
}
function homeDiff ()
{
	 # Only check home dump once per second
	[[ `find $hkdir/tmp/HomeKitWatcher_currHome.log -mtime -1s` ]] && return;
	
	local diff
	touch $prevHome $currHome
	homeutil dump-all | grep -v "(CH)\|(MD)" | tail -c +26 > $currHome
	cmp --silent $prevHome $currHome && return;
	
	local timestamp=$(date +%Y-%m-%dT%H.%M.%S)
	local fileName="$hkdir/HomeDiffs/HomeDiff-$timestamp.txt"
	echo "$(date '+%Y-%m-%d %H:%M:%S') | HomeKit  | Home change detected (HomeDiff-$timestamp.txt)" >> $hklog
	diff $prevHome $currHome | tail -n +2 | sed 's/^/                    |          | /' >> $hklog
	
	pidDiff &
	keyDiff &
	local hklog="$hkdir/HomeKitWatcher.log"
	
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	cat "$prevHome" >> $fileName
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	diff $prevHome $currHome | tail -n +2 >> $fileName
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	cat "$currHome" >> $fileName
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	cp $currHome $prevHome
}
function keyDiff ()
{
	local diff
	touch $prevKeys $currKeys
	
	echo security item class=genp,sync=1,agrp=com.apple.hap.pairing > $currKeys
	security item class=genp,sync=1,agrp=com.apple.hap.pairing >> $currKeys 2>&1
	echo security item class=genp,sync=0,agrp=com.apple.hap.pairing >> $currKeys
	security item class=genp,sync=0,agrp=com.apple.hap.pairing >> $currKeys 2>&1
	echo security item class=genp,sync=0,agrp=com.apple.hap.metadata >> $currKeys
	security item class=genp,sync=0,agrp=com.apple.hap.metadata >> $currKeys 2>&1
	
	cmp --silent $prevKeys $currKeys && return;
	
	local timestamp=$(date +%Y-%m-%dT%H.%M.%S)
	local fileName="$hkdir/KeyDiffs/KeysDiff-$timestamp.txt"
	echo "$(date '+%Y-%m-%d %H:%M:%S') | HomeKit  | Key difference detected (KeysDiff-$timestamp.txt)" >> $hklog
	diff $prevKeys $currKeys | tail -n +2 | sed 's/^/                    |          | /' >> $hklog

	local hklog="$hkdir/HomeKitWatcher.log"
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	cat "$prevKeys" >> $fileName
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	diff $prevKeys $currKeys | tail -n +2 >> $fileName
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	cat "$currKeys" >> $fileName
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> $fileName
	cp $currKeys $prevKeys
}
function pidDiff ()
{
	local prevPIDpath=$hkdir/tmp/prevHomeKitPID.txt && touch $prevPIDpath
	local prevPID=$(cat $prevPIDpath)
	local currPID=$(pgrep homed)
	if [[ "$currPID" != "$prevPID" ]]; then
		local hklog="$hkdir/HomeKitWatcher.log"
		echo "$(date '+%Y-%m-%d %H:%M:%S') | HomeKit  | Relaunched – PID Changed from $prevPID to $currPID" >> $hklog
		echo $currPID > $prevPIDpath
	fi
}
function hkRoller ()
{
	symLink=$hkdir/HomeKit-latest.log
	homeutil v >/dev/null 2>&1
	cd $crashDir/DiagnosticLogs/
	currLog=`ls -tr HomeKit* | grep -v gz | tail -n 1`
	while [ ! -f `ls -tr HomeKit* | grep -v gz | tail -n 1` ] ; do sleep 1 ; done
	while true ; do
		cd $crashDir/DiagnosticLogs/
		currLog=`ls -tr HomeKit* | grep -v gz | tail -n 1`
		if [[ "$currLog" != "$prevLog" && "$currLog" != "" ]]; then
			ln -f -s $crashDir/DiagnosticLogs/$currLog $symLink
			echo "$(date '+%Y-%m-%d %H:%M:%S') | HomeKit  | Log rolled. Was $prevLog and is now $currLog" >> $hklog
			prevLog=$currLog
		fi
		sleep 1
	done
}
function hkMemWatcher ()
{
	sampleLimit=12000000 # Above this many bytes, a sample will be taken
	curMem=0
	pid=0
	backoff=0
	mkdir -p $hkdir/Samples
	
	while true ; do
		if pid=$(pgrep homed) && [[ ! -z pid ]]; then
			curMem=$(jetsam_priority -k 2>&1 | grep homed)
			curMem=$(echo $curMem | awk '{print $5;}')
			curMem=$(echo $curMem | sed -e s/KB/000/)
			timestamp=$(date +%Y-%m-%dT%H.%M.%S)
			echo "$timestamp,$curMemNum" >> $hkmemlog
			if [[ $curMem -gt $sampleLimit ]] && [[ $backoff -eq 0 ]]; then
				echo "$(date '+%Y-%m-%d %H:%M:%S') | HomeKit  | Memory exceeded specified limit, sampling homed. Currently at $curMem bytes with limit set to $sampleLimit bytes." >> $hklog
				sample homed 10 -mayDie -file $hkdir/Samples/homed.sample.$timestamp.txt >/dev/null 2>&1 &
				echo | hmLogs q
				backoff=200 # Only take a sample at most once every ~5m (Sleep 1 =/= 1s per loop)
			fi
		fi
		if [[ $backoff -gt 0 ]]; then let backoff-=2 ; fi
		sleep 2
	done
}

function disableHKlogs () 
{
	echo "Resetting HomeKit logging..."
	log config --reset --subsystem "com.apple.HomeKit"
	
	#echo "Disabling HomeKit Advanced logging..."
	#login -f mobile defaults delete /var/mobile/Library/Preferences/.GlobalPreferences.plist HomeKitLogLevel

	echo "Disabling IDS logging..."
    login -f mobile /usr/local/bin/idstool logging -t ids -s 0 >/dev/null 2>&1 >/dev/null 2>&1
    if [ -f /usr/local/bin/assistant_tool ]; then
    	echo "Disabling Siri logging..."
    	assistant_tool enableLogging 0
    fi
    echo "Disabling DiscoveryD logging..."
    discoveryutil loglevel None >/dev/null 2>&1
    killall -USR1 mDNSResponder >/dev/null 2>&1
    echo "Disabling Bluetooth logging..."
    login -f mobile defaults write com.apple.MobileBluetooth.debug DiagnosticMode NO >/dev/null 2>&1
	echo "Disabling Bluetooth HCI Trace logging..."
	login -f mobile defaults write com.apple.MobileBluetooth.debug HCITraces -dict StackDebugEnabled FALSE >/dev/null 2>&1
    killall -USR1 BTServer >/dev/null 2>&1
    
    echo "Disabling Location logging..."
    login -f mobile defaults delete com.apple.locationd LogFileLevel >/dev/null 2>&1
	login -f mobile defaults delete com.apple.locationd LogFileStorageCount >/dev/null 2>&1
    killall locationd >/dev/null 2>&1
    
    echo "Disabling Power logging..."
    PLLog -C 0 >/dev/null 2>&1
    
    echo "Disabling WiFi logging..."
    profilectl remove com.apple.defaults.managed.corecapture.wifi.megawifi >/dev/null 2>&1

	echo "Disabling Malloc logging..."
	jetsam_properties delete com.apple.homed ActiveMemoryLimit >/dev/null 2>&1
	jetsam_properties delete com.apple.homed InactiveMemoryLimit >/dev/null 2>&1
	launchctl unload /System/Library/LaunchDaemons/com.apple.homed.plist >/dev/null 2>&1
	defaults delete /System/Library/LaunchDaemons/com.apple.homed.plist EnvironmentVariables >/dev/null 2>&1
	launchctl load /System/Library/LaunchDaemons/com.apple.homed.plist >/dev/null 2>&1
	echo "     Malloc logging will not be fully disabled until a reboot."
	
	echo "Disabling AVConference (IP Camera) logging..."
	login -f mobile defaults delete com.apple.VideoConference errorLogLevel >/dev/null 2>&1
	killall mediaserverd
}

function enableHKlogs () 
{
	echo "Enabling HomeKit logging..."
# 	log config --mode "persist:info" --subsystem "com.apple.HomeKit"
	log config --mode "level:debug,persist:debug" --subsystem com.apple.HomeKit
	log config --mode "persist:info" --subsystem "com.apple.mDNSResponder"
	#echo "Enabling HomeKit Advanced logging..."
	#login -f mobile defaults write /var/mobile/Library/Preferences/.GlobalPreferences.plist HomeKitLogLevel -int 7
	
	echo "Enabling IDS logging..."
    login -f mobile /usr/local/bin/idstool logging -t ids -s 1 >/dev/null 2>&1
    
    
    if [ -f /usr/local/bin/assistant_tool ]; then
    	echo "Enabling Siri logging..."
    	assistant_tool enableLogging 1
    	login -f mobile defaults write com.apple.assistantd "Legacy Logging Enabled" 1
    	killall -9 assistantd >/dev/null 2>&1
    fi
    echo "Enabling DiscoveryD logging..."
    discoveryutil loglevel Basic >/dev/null 2>&1
	syslog -c mDNSResponder -i >/dev/null 2>&1   # Include "INFO" level logs in syslog outputs
    killall -USR1 mDNSResponder >/dev/null 2>&1  # Traces all the api calls, core calls, platform calls via logging with syslog
    
    echo "Enabling Bluetooth logging..."
    login -f mobile defaults write com.apple.MobileBluetooth.debug DiagnosticMode YES >/dev/null 2>&1
    login -f mobile defaults write com.apple.MobileBluetooth.debug DefaultLevel Notice >/dev/null 2>&1
    if [[ $1 == *"h"* ]]; then
		echo "Enabling Bluetooth HCI Trace logging..."
		echo " - HCI Tracing will affect performance on carry devices."
		echo " - Disable in Internal Settings -> Bluetooth -> HCI Tracing"
		login -f mobile defaults write com.apple.MobileBluetooth.debug HCITraces -dict StackDebugEnabled TRUE UnlimitedHCIFileSize TRUE >/dev/null 2>&1
    fi
    killall -USR1 BTServer >/dev/null 2>&1
    
    echo "Enabling WiFi logging..."
    profilectl install! /AppleInternal/Library/WiFi/Profiles/MegaWifi\ Profile.mobileconfig >/dev/null 2>&1

	echo "Enabling Location logging..."
	login -f mobile defaults write com.apple.locationd LogFileLevel -int 3 >/dev/null 2>&1
	login -f mobile defaults write com.apple.locationd LogFileStorageCount -int 8 >/dev/null 2>&1
	login -f mobile defaults write com.apple.locationd LogFileRotationSize -int 52428800 >/dev/null 2>&1
	killall locationd >/dev/null 2>&1
	
	echo "Enabling Power logging..."
	PLLog -C 1 >/dev/null 2>&1
    
    if [[ $1 == *"m"* ]]; then
		echo "Enabling Malloc Logging..."
		jetsam_properties set com.apple.homed ActiveMemoryLimit -1
		jetsam_properties set com.apple.homed InactiveMemoryLimit -1
		launchctl unload /System/Library/LaunchDaemons/com.apple.homed.plist
		defaults write /System/Library/LaunchDaemons/com.apple.homed.plist EnvironmentVariables '{ MallocStackLogging = 1; }';
		launchctl load /System/Library/LaunchDaemons/com.apple.homed.plist
		read -p "Press [Enter] to reboot now, or Ctrl+C to reboot later." reboot
		reboot
    fi
    
	echo "Enabling AVConference (IP Camera) logging... (Collect logs with : syslog -w)"
	login -f mobile defaults write com.apple.VideoConference errorLogLevel INFO >/dev/null 2>&1
	killall mediaserverd >/dev/null 2>&1
    
    echo "All done!"
    
    #echo "Starting HomeKit Watcher... (Requires relaunch after reboot, type 'homekit watcher')"
    #homekit watcher
}
remoteScript()
{
	cmdOne=""
	cmdTwo=""
	testType=0
	autoOption=y
	localPass=0
	localFail=0
	remotePass=0
	remoteFail=0
	total=0
	echo
	echo "Let's figure out what and how we're testing..."
	echo "  1. Test writing local, then writing remote, repeatedly."
	echo "  2. Test varying lengths of time between remote writes, repeatedly."
	read -p "Choose wisely : " testType
	echo
	if [[ "$testType" == *"1"* ]]; then
    	echo "Okay, we're testing local / remote cycling."
    	echo "  You can either specify a homeutil command, or use the automatic option, 'Siri, are the lights on?'"
    	read -p "Would you like to use the automatic option? (y/n) : " autoOption
    	if [ -z "$autoOption" ]; then autoOption=y; fi
    	echo
    	if [[ "$autoOption" != *"y"* ]]; then
    		echo "To use a homeutil command, type 'homeutil dump-all' on your device, and formulate a write command like:"
    		echo "  homeutil write -h \"HomeName\" -a \"AccessoryName\" -r 14 -c 17 -b 1"
    		while [ -z "$cmdOne" ]; do
    			read -p "Enter your homeutil command here : " cmdOne
    			echo
    		done
    		read -p "Optionally enter a second command to run while remote : " cmdTwo
    		echo
    		if [ -z "$cmdTwo" ]; then
    			cmdTwo=$cmdOne
    		fi
    	fi
    	echo "Let's do this!"
    	echo
    	
    	# The actual test begins...
		echo "total=$total ; remotePass=$remotePass ; remoteFail=$remoteFail ; localPass=$localPass ; localFail=$localFail"
		while [ true ]; do
			# Local write
			mobilewifitool manager power 1
			sleep 10
			homeutil show-date
			if [[ "$autoOption" == *"y"* ]]; then
				result=$(assistant_tool startRequest "Are the lights on?")
				echo $result && ((total++))
				if [[ $result == *"Sorry"* ]] || [[ $result == *"Hmm"* ]] ; then ((localFail++)) ; else ((localPass++)); fi
			else
				echo $cmdOne
				result=`eval $cmdOne`
				echo $result && ((total++))
				if [[ $result == *"wrote"* ]] ; then ((localPass++)) ; else ((localFail++)); fi
			fi
			echo "total=$total ; remotePass=$remotePass ; remoteFail=$remoteFail ; localPass=$localPass ; localFail=$localFail"
			#sleep 10
				
			# Remote write
			mobilewifitool manager power 0
			sleep 20
			homeutil show-date
			if [[ "$autoOption" == *"y"* ]]; then
				result=$(assistant_tool startRequest "Are the lights on?")
				echo $result && ((total++))
				if [[ $result == *"Sorry"* ]] || [[ $result == *"Hmm"* ]] ; then ((remoteFail++)) ; else ((remotePass++)); fi
			else
				echo $cmdTwo
				result=`eval $cmdTwo`
				echo $result && ((total++))
				if [[ $result == *"wrote"* ]] ; then ((remotePass++)) ; else ((remoteFail++)); fi
			fi
			echo "total=$total ; remotePass=$remotePass ; remoteFail=$remoteFail ; localPass=$localPass ; localFail=$localFail"
			#sleep 10
		done
		# nohup ./remoteScript.sh &> $crashDir/remoteTest.txt&
		# result=$(homeutil write -h Test -a "My ecobee3" -r 16 -c 20 -f 27)
    	
	elif [[ "$testType" == *"2"* ]]; then
		echo "Okay, we're testing remote writes at varying intervals."
    	echo "  You can either specify a homeutil command, or use the automatic option, 'Siri, are the lights on?'"
    	read -p "Would you like to use the automatic option? (y/n) : " autoOption
    	if [ -z "$autoOption" ]; then autoOption=y; fi
    	echo
    	if [[ "$autoOption" != *"y"* ]]; then
    		echo "To use a homeutil command, type 'homeutil dump-all' on your device, and formulate a write command like:"
    		echo "  homeutil write -h \"HomeName\" -a \"AccessoryName\" -r 14 -c 17 -b 1"
    		while [ -z "$cmdOne" ]; do
    			read -p "Enter your homeutil command here : " cmdOne
    			echo
    		done
    	fi
    	echo "We're going to attempt writes at increasing increments. Choose the increment and maximum to use."
    	echo " For example, max=60, increment=5. To use these defaults, just hit enter on both."
    	read -p "Choose the final wait time : " maxTime
    	read -p "Choose the increment : " incTime
    	if [ -z "$maxTime" ]; then maxTime=60; fi
    	if [ -z "$incTime" ]; then incTime=5; fi
    	echo
    	echo "Starting at 0 min, increasing by $incTime min until $maxTime min."
    	echo
    	echo "Let's do this!"
    	echo

		# The actual test begins...
		mobilewifitool manager power 0
		echo "Total=$total; Pass=$remotePass; Fail=$remoteFail"
		while [ true ]; do
			if [[ $timer -gt $maxTime ]]; then timer=0; fi
			echo Waiting $timer minutes...
			let seconds=timer*60
			sleep $seconds
			echo Attempting write...
			homeutil show-date
			if [[ "$autoOption" == *"y"* ]]; then
				result=$(assistant_tool startRequest "Are the lights on?")
				echo $result && ((total++))
				if [[ $result == *"Sorry"* ]] || [[ $result == *"Hmm"* ]] ; then ((remoteFail++)) ; else ((remotePass++)); fi
			else
				echo $cmdOne
				result=`eval $cmdOne`
				echo $result && ((total++))
				if [[ $result == *"wrote"* ]] ; then ((remotePass++)) ; else ((remoteFail++)); fi
			fi
			echo "Total=$total; Pass=$remotePass; Fail=$remoteFail"
			timer=$((timer+incTime))
		done
		
	else remoteScriptStartup
	fi
}
function siri()
{
	local i
	local request=""

	if [ "$1" = "sync" ]; then
		interact menu;     scripter -c "UIATarget.localTarget().setVoiceRecognitionStrings(new Array('$request'));" && scripter -c "UIATarget.localTarget().holdMenu(1);"; interact menu
		return
	elif [ "$1" = "forcesync" ]; then
		assistant_tool sync --forceReset com.apple.homekit.name
		return
	fi

	for i in $*
	do
		request="$request $i"
	done

set -x
    scripter -c "UIATarget.localTarget().setVoiceRecognitionStrings(new Array('$request'));" && scripter -c "UIATarget.localTarget().holdMenu(1);"
set +x
}
function try ()
{
	"$@"
	while [ $? -ne 0 ]
	do
		sleep 1
		"$@"
	done
}
function homedLeaks()
{
	echo Starting collection, hit Ctrl+C to Stop.
	while true; do
		ctime="`date \"+%Y-%m-%d-%H-%M-%S\"`"
		heap -guessNonObjects homed > /var/mobile/Library/Logs/CrashReporter/HomeKitHeap-${ctime}.log
		sleep 10
	done
}