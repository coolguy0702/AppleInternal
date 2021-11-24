package iTestPRO_onDevice_Modules;

$|++;
use strict;
use Cwd;
use Time::Local;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
#-----------------------------------------------------------------------------------------
$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
					getEpochTime
					deleteiTestPROoldFiles
					printToLogFile
					printResultsToResultFile
					getCurrentBatteryPercentage
					apSleep
					loadWebpage
					loadWebpageWithTimeout
					unlockDevice
					makeMOVoiceCall
					getBBDiagFolders
					statusOfBBDiagLogging
					deleteExistingBBLogs
					deleteExistingPowerLogs
					getExistingPowerLogFileList
					turnOffWifi
					turnOnWifi
					getDeviceInfo
					waitUntilDirectorySizeIsConstant
					removeTabsAndSpaces
					sendSMS
					dumpBBLogs
					dumpAndMovePowerLogs
					dumpAndMoveBBAndPowerLogsToiTestPROLogsFolderInCrashReporter
					executePPScriptOnLogs
					deleteOldiTestPROPowerToolLogFolders
					moveiTestPROPowerToolLogAndResultFileToCrashReporter
					setNoIdle
					updatePowerLogDefaults
					delayBasedOnEpochTime
					getExistingBasebandLogFileList
					);
%EXPORT_TAGS = ( DEFAULT => [qw(&getEpochTime)],
                 All    => [qw(
					&getEpochTime
					&deleteiTestPROoldFiles
					&printToLogFile
					&printResultsToResultFile
					&getCurrentBatteryPercentage
					&apSleep
					&loadWebpage
					&loadWebpageWithTimeout
					&unlockDevice
					&makeMOVoiceCall
					&getBBDiagFolders
					&statusOfBBDiagLogging
					&deleteExistingBBLogs
					&deleteExistingPowerLogs
					&getExistingPowerLogFileList
					&turnOffWifi
					&turnOnWifi
					&getDeviceInfo
					&waitUntilDirectorySizeIsConstant
					&removeTabsAndSpaces
					&sendSMS
					&dumpBBLogs
					&dumpAndMovePowerLogs
					&dumpAndMoveBBAndPowerLogsToiTestPROLogsFolderInCrashReporter
					&executePPScriptOnLogs
					&deleteOldiTestPROPowerToolLogFolders
					&moveiTestPROPowerToolLogAndResultFileToCrashReporter
					&setNoIdle
					&updatePowerLogDefaults
					&delayBasedOnEpochTime
					&getExistingBasebandLogFileList
                 				)]);
#-----------------------------------------------------------------------------------------
# 
# FileName :    iTestPRO_onDevice_Modules.pm
# Author :		Ghayasuddin Mohammed (ghayasuddin@apple.com)
# Company :		Apple Inc
# Version :     1.0
# Date:         11/15/2012 (mm/dd/yyyy)
# 
# Modify Dates:   
#
# Version Update Info
#
# Description:
#    Modules that can be used for onDevice testing
# 
# How To Run(Syntax Examples):
#
#-----------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------
# *** GENERIC MODULES ***
#-----------------------------------------------------------------------------------------
sub getEpochTime{
	my ($sec, $min, $hr, $day, $mon, $year) = localtime;

	my $epochTime = timelocal($sec, $min, $hr, $day, $mon, $year);
	return $epochTime;
}

sub deleteiTestPROoldFiles{
	my $cmd = "rm -rf iTestPRO_Log_*.txt";
	system("$cmd");
	
	$cmd = "rm -rf iTestPRO_Result_*.csv";
	system("$cmd");
	
	deleteOldiTestPROPowerToolLogFolders();
}

sub printToLogFile{
	my($LOGFILE, $logText) = @_;
	
	chomp($logText);
	my ($sec, $min, $hr, $day, $mon, $year) = localtime;
	my $formattedDateTime = ($mon+1) . "_" . $day . "_" . ($year+1900_). "_" . $hr . "hrs" . $min . "m" . $sec . "s";
	print $LOGFILE $formattedDateTime . ", " . $logText . "\n";
	print $formattedDateTime . ", " . $logText . "\n";
}

sub printResultsToResultFile{
	my($CSV_RESULT_FILE, $ref_htResults, $moduleName) = @_;
	
	my %htResults = %$ref_htResults;
	print $CSV_RESULT_FILE "MODULE NAME, $moduleName \n";
	for my $key1 ( sort {$a<=>$b} keys %htResults )
	{
		print $CSV_RESULT_FILE "$key1, $htResults{$key1} \n";
	}
	print $CSV_RESULT_FILE "\n\n";
}

sub getCurrentBatteryPercentage{
	my($LOGFILE) = @_;
	
	my $cmd = "powerlog -Bq";
 	my @result = `$cmd`;
 	
 	my $currentBatteryPercent = 0;
 	foreach(@result)
 	{
 		if($_ =~ m/\s+level\=(\d+)\.(\d+)\%/i)
 		{
 			$currentBatteryPercent = $1 . "." . $2;
 		}
 	}
 	printToLogFile($LOGFILE,"Current Battery Percent :: $currentBatteryPercent");
 	
 	return $currentBatteryPercent;
}

sub apSleepOld{
	 my ($sleepSeconds, $turnOnDisplay, $LOGFILE) = @_;
	
	 my $dParam = "";
	 if(defined($turnOnDisplay))
	 {
		if(($turnOnDisplay =~ m/YES/i) | ($turnOnDisplay =~ m/TRUE/i))
		{
			$dParam = " -d";
		}
	 }
	
	 printToLogFile($LOGFILE,"AP SLEEP>> Started; Duration = $sleepSeconds seconds");
	 my $cmd = "SleepCycler -n 1 -s " . $sleepSeconds . $dParam;
	 #system("$cmd");
	 `$cmd`;
	 printToLogFile($LOGFILE,"AP SLEEP>> Ended");
}

sub apSleep{
	my ($sleepSeconds, $turnOnDisplay, $LOGFILE) = @_;
	
	my $dParam = "";
	if(defined($turnOnDisplay))
	{
		if(($turnOnDisplay =~ m/YES/i) | ($turnOnDisplay =~ m/TRUE/i))
		{
			$dParam = " -d";
		}
	}
	
	#my $cmd = "SleepCycler -n 1 -s " . $sleepSeconds . $dParam;
	my $cmd = "SleepCycler -n 1 -s " . $sleepSeconds;
	my $startTime = getEpochTime();
	my $elapsedTime = 0;
	my $breakLoop = 0;
	printToLogFile($LOGFILE,"AP SLEEP>> Started; Duration = $sleepSeconds seconds; Start Epoch Time = " . $startTime);
	while($breakLoop == 0)
	{
		printToLogFile($LOGFILE,"AP SLEEP>> SleepCycler Command: " . $cmd);
		`$cmd`;
		
		my $endTime = getEpochTime();
		$elapsedTime = $endTime - $startTime;
		printToLogFile($LOGFILE,"AP SLEEP>> Ended; Elapsed Duration = $elapsedTime seconds; End Epoch Time = " . $endTime);
		if($elapsedTime < $sleepSeconds)
		{
			$cmd = "SleepCycler -n 1 -s " . ($sleepSeconds - $elapsedTime);
		}
		else
		{
			if($elapsedTime > ($sleepSeconds + 3))
			{
				printToLogFile($LOGFILE,"AP SLEEP>> SleepCycler :: ************ ELAPSED TIME HIGHER THAN GIVEN TIME + 3 seconds ************");
			}
			
			$breakLoop = 1;
			last;
		}
	}
	printToLogFile($LOGFILE,"AP SLEEP>> Final End");
}

sub loadWebpage{
	my($currentWebpage, $isDevicePasscodeLocked, $devicePasscode, $LOGFILE) = @_;
	
	my $isPageSuccessful = "FAIL";
	my $pageLoadTime = 0;
	
	my $scripterCommand = "scripter -i \"SafariTests.js:PHTesting.js\" -c \"test.testName=\\\"ExecuteTest\\\"; test.main=safariTest_loadSafariPage; test.argv=[\\\"" . $currentWebpage . "\\\"]; test.execute()\"";
	
	printToLogFile($LOGFILE,"Loading Webpage >> $currentWebpage");
	printToLogFile($LOGFILE,"Scripter Command >> $scripterCommand");
	
	unlockDevice($isDevicePasscodeLocked, $devicePasscode, $LOGFILE); # If device Passcode is given
	
	my @result = `$scripterCommand`;
	foreach(@result)
	{
		printToLogFile($LOGFILE,$_);
	}
	
	my $browsingStartTime = -999;
	my $browsingEndTime = -999;
	my $noOfValues = 3;
	foreach(@result)
	{
		if($_ =~ m/report\:\s+Test\:\s+ExecuteTest\s+PASS/i)
		{
			$isPageSuccessful = "PASS";
			$noOfValues--;
		}
		elsif($_ =~ m/report\:\s+Test\:\s+ExecuteTest\s+FAIL/i)
		{
			$isPageSuccessful = "FAIL";
			$noOfValues--;
		}
		
		if($_ =~ m/(\w+)\s*(\d+)\,\s*(\d+)\,?\s*(\d+):(\d+):(\d+)\s*(.*)loadPageAndWait:\s*Loading/i)
		{
			my $hrs = $4;
			my $mins = $5;
			my $secs = $6;
			
			$browsingStartTime = ($hrs * 60 * 60) + ($mins * 60) + $secs;
			$noOfValues--;
		}
		elsif($_ =~ m/(\w+)\s*(\d+)\,\s*(\d+)\,?\s*(\d+):(\d+):(\d+)\s*(.*)waitForPageToLoad: Done loading page/i)
		{
			my $hrs = $4;
			my $mins = $5;
			my $secs = $6;
			
			$browsingEndTime = ($hrs * 60 * 60) + ($mins * 60) + $secs;
			$noOfValues--;
		}
		
		if($noOfValues == 0) { last; }
	}
	
	if($browsingEndTime > 0 && $browsingStartTime > 0)
	{
		$pageLoadTime = $browsingEndTime - $browsingStartTime;
	}
	printToLogFile($LOGFILE,"Webpage Load Completed");
	
	return($isPageSuccessful, $pageLoadTime);
}

sub loadWebpageWithTimeout{
	my($currentWebpage, $isDevicePasscodeLocked, $devicePasscode, $timeoutSeconds, $LOGFILE) = @_;
	
	my $isPageSuccessful = "FAIL";
	my $pageLoadTime = 0;

	printToLogFile($LOGFILE,"Loading Webpage >> $currentWebpage");
	unlockDevice($isDevicePasscodeLocked, $devicePasscode, $LOGFILE); # If device Passcode is given
	
	`killall -9 MobileSafari`; # Kill Safari app
	
	printToLogFile($LOGFILE,"Loading Webpage >> Launching Safari");
	my $scripterCommand = "scripter -uiautomation -YES -i \"Safari.js\" -c \"safari.launchIfNotActive()\"";
	`$scripterCommand`;

	$scripterCommand = "scripter -uiautomation -YES -i \"Safari.js\" -c \"safari.loadPageAndWait('" . $currentWebpage . "'," . $timeoutSeconds .  ")\"";
	printToLogFile($LOGFILE,"Scripter Command >> $scripterCommand");
	
	my @result = `$scripterCommand`;
	foreach(@result)
	{
		printToLogFile($LOGFILE,$_);
	}
	
	my $browsingStartTime = -999;
	my $browsingEndTime = -999;
	my $noOfValues = 2;
	foreach(@result)
	{
		if($_ =~ m/ERROR\t*\s*loadPageAndWait\:\s*FAIL to laod page\s*\-\-\s*Time out/i)
		{
			$isPageSuccessful = "FAIL";
			$noOfValues = 0;
		}
		
		if($_ =~ m/(\w+)\s*(\d+)\,\s*(\d+)\,?\s*(\d+):(\d+):(\d+)\s*(.*)loadPageAndWait:\s*Loading/i)
		{
			my $hrs = $4;
			my $mins = $5;
			my $secs = $6;
			
			$browsingStartTime = ($hrs * 60 * 60) + ($mins * 60) + $secs;
			$noOfValues--;
		}
		elsif($_ =~ m/(\w+)\s*(\d+)\,\s*(\d+)\,?\s*(\d+):(\d+):(\d+)\s*(.*)waitForPageToLoad: Done loading page/i)
		{
			my $hrs = $4;
			my $mins = $5;
			my $secs = $6;
			
			$browsingEndTime = ($hrs * 60 * 60) + ($mins * 60) + $secs;
			$noOfValues--;
			$isPageSuccessful = "PASS";
		}
		
		if($noOfValues == 0) { last; }
	}
	
	if($browsingEndTime > 0 && $browsingStartTime > 0)
	{
		$pageLoadTime = $browsingEndTime - $browsingStartTime;
	}
	printToLogFile($LOGFILE,"Webpage Load Completed");
	
	return($isPageSuccessful, $pageLoadTime);
}

sub unlockDevice{
	my($isDevicePasscodeLocked, $devicePasscode, $LOGFILE) = @_;
	if($isDevicePasscodeLocked eq "YES")
	{
		printToLogFile($LOGFILE,"Device is Locked, Unlocking the device");
		my $passcodeUnlockCmd = "scripter -uiautomation YES -i \"SpringBoard.js\" -c \"UIATarget.localTarget().unlockScreenIfNecessary('" . $devicePasscode . "')\"";
		`$passcodeUnlockCmd`;
	}
}

sub makeMOVoiceCall{
	my($serverPhoneNumber, $callDurationSeconds, $LOGFILE) = @_;
	
	my $callSetupStatus = "FAIL";
	my $callMaintenanceStatus = "FAIL";
	
	printToLogFile($LOGFILE,"Making Voice Call to Phone Number >> $serverPhoneNumber");
	my $cmd = "testCT -c " . $serverPhoneNumber;
	my @result = `$cmd`;
	foreach(@result)
	{
		printToLogFile($LOGFILE,$_);
	}
	
	foreach(@result)
	{
		if($_ =~ m/CallStatusActive PASS/i)
		{
			$callSetupStatus = "PASS";
			last;
		}
	}
	printToLogFile($LOGFILE,"Voice Call Setup Status >> $callSetupStatus");
	
	if($callSetupStatus =~ m/PASS/i)
	{
		my $startTime = getEpochTime();
		my $breakLoop = 0;
		while($breakLoop == 0)
		{
			@result = `testCT -x`;
			
			foreach(@result)
			{
				printToLogFile($LOGFILE,$_);
			}
			
			my $gotStatusActive = "FAIL";
			foreach(@result)
			{
				if($_ =~ m/call 0 status active/i)
				{
					$gotStatusActive = "PASS";
					last;
				}
			}
			
			if($gotStatusActive =~ m/PASS/i)
			{
				$callMaintenanceStatus = "PASS";
			}
			else
			{
				$callMaintenanceStatus = "FAIL";
				$breakLoop = 1;
				last;
			}
			
			sleep 3;
			
			my $endTime = getEpochTime();
			my $timeDiff = $endTime - $startTime;
			
			printToLogFile($LOGFILE,"Voice Call Current Time Diff : $timeDiff");
			if($timeDiff >= $callDurationSeconds)
			{
				$breakLoop = 1;
				last;
			}
		}
		
		if($callMaintenanceStatus =~ m/PASS/i)
		{
			@result = `testCT -e`;
		}
	}
	printToLogFile($LOGFILE,"Voice Call End, Maint Status >> $callMaintenanceStatus");
	
	return($callSetupStatus, $callMaintenanceStatus);
}

sub deleteExistingBBLogs{
	`killall -USR2 CommCenter`;
	sleep 1;
	`killall -USR2 CommCenterClassic`;
	sleep 1;
	
	waitUntilDirectorySizeIsConstant("/var/wireless/Library/Logs/CrashReporter/", 3);
	
	sleep 1;
	`rm -rf /var/wireless/Library/Logs/CrashReporter/Baseband/`;
}

sub deleteExistingPowerLogs{
	# Stop Power log by deleting currentPowerlog
	`rm -rf /Library/Logs/CurrentPowerlog.powerlog`;
	
	# Delete Old Power Logs
	`rm -rf /Library/Logs/CrashReporter/*.powerlog`;
}

sub turnOffWifi{
	`mobilewifitool manager power 0`;
}

sub turnOnWifi{
	`mobilewifitool manager power 1`;
}

sub getDeviceInfo{
	my($ref_htResults) = @_;

	my($devicePhoneNumber, $deviceIMEI, $deviceFirmwareBBVersion, $deviceRegistrationStatus,
		$deviceNetworkOperator, $deviceSoftwareVersion, $deviceSoftwareAPBuild, $deviceHardwareInfo) = 
		("", "", "", "", "", "", "", "");

	$$ref_htResults{"DEVICE_PHONE_NUMBER"} = "";
	$$ref_htResults{"DEVICE_IMEI"} = "";
	$$ref_htResults{"DEVICE_FIRMWARE_BB_VERSION"} = "";
	$$ref_htResults{"DEVICE_REGISTRATION_STATUS"} = "";
	$$ref_htResults{"DEVICE_NETWORK_OPERATOR"} = "";
	$$ref_htResults{"DEVICE_SOFTWARE_VERSION"} = "";
	$$ref_htResults{"DEVICE_SOFTWARE_AP_BUILD"} = "";
	$$ref_htResults{"DEVICE_HARDWARE_INFO"} = "";
	
	# Get SOFTWARE VERSION
	my @result = `sw_vers`;
	foreach(@result)
	{
		chomp($_);
		if($_ =~ m/ProductVersion\:s*(.*)/i)
		{
			$deviceSoftwareVersion = $1;
		}
		
		if($_ =~ m/BuildVersion\:s*(.*)/i)
		{
			$deviceSoftwareAPBuild = $1;
		}
	}
	
  	# Get HEARDWARE VERSION
	@result = `memdump -a syscfg -r -k CFG#`;
	foreach(@result)
	{
		chomp($_);
		if($_ =~ m/CFG#\:\s*(.*)/i)		#  CFG#:  N41/PVTENG/1TM1/441/1RB7/06374  
		{
			$deviceHardwareInfo = $1;
		}
	}
	
	# Get OTHER Info of the device
	@result = `CoreTelephonyMonitor -q 2>&1`;
	foreach(@result)
	{
		chomp($_);
		if($_ =~ m/^Firmware Version\:.*\[(.*)\]/i)
		{
			$deviceFirmwareBBVersion = $1;
		}
		
		if($_ =~ m/^IMEI\:.*\[(.*)\]/i)
		{
			$deviceIMEI = $1;
		}
		
		if($_ =~ m/^Phone Number\:.*\[(.*)\]/i)
		{
			$devicePhoneNumber = $1;
		}
		
		if($_ =~ m/^Registration Status\:.*\[(.*)\]/i)
		{
			$deviceRegistrationStatus = $1;
		}
		
		if($_ =~ m/^Operator\:.*\[(.*)\]/i)
		{
			$deviceNetworkOperator = $1;
		}
	}
	
	removeTabsAndSpaces(\$devicePhoneNumber);
	removeTabsAndSpaces(\$deviceIMEI);
	removeTabsAndSpaces(\$deviceFirmwareBBVersion);
	removeTabsAndSpaces(\$deviceRegistrationStatus);
	removeTabsAndSpaces(\$deviceNetworkOperator);
	removeTabsAndSpaces(\$deviceSoftwareVersion);
	removeTabsAndSpaces(\$deviceSoftwareAPBuild);
	removeTabsAndSpaces(\$deviceHardwareInfo);
	
	$$ref_htResults{"DEVICE_PHONE_NUMBER"} = $devicePhoneNumber;
	$$ref_htResults{"DEVICE_IMEI"} = $deviceIMEI;
	$$ref_htResults{"DEVICE_FIRMWARE_BB_VERSION"} = $deviceFirmwareBBVersion;
	$$ref_htResults{"DEVICE_REGISTRATION_STATUS"} = $deviceRegistrationStatus;
	$$ref_htResults{"DEVICE_NETWORK_OPERATOR"} = $deviceNetworkOperator;
	$$ref_htResults{"DEVICE_SOFTWARE_VERSION"} = $deviceSoftwareVersion;
	$$ref_htResults{"DEVICE_SOFTWARE_AP_BUILD"} = $deviceSoftwareAPBuild;
	$$ref_htResults{"DEVICE_HARDWARE_INFO"} = $deviceHardwareInfo;
}

sub waitUntilDirectorySizeIsConstant{
	my($directoryPath,$waitTimeSeconds) = @_;
	
	if(!(defined($waitTimeSeconds)))
	{
		$waitTimeSeconds = 5;
	}
	elsif($waitTimeSeconds <= 0)
	{
		$waitTimeSeconds = 5;
	}
	
	my $cmd = "du -sc " . $directoryPath;
	my $breakLoop = 0;
	my $previousDirectorySize = -1;
	my $currentDirectorySize = 0;
	my $numberOfTimesToBeEqual = 3;
	
	if(-d $directoryPath)
	{
		print "BB directory: Exists \n";
	}
	else
	{
		print "BB directory: Does not Exist \n";
	}
	
	print "Checking BB directory Size \n";
	my $i = 1;
	while($breakLoop == 0)
	{
		print "iteration: $i , wait Time: $waitTimeSeconds; cmd: $cmd\n";
		$i++;
		
		sleep $waitTimeSeconds;
		
		my @result = `$cmd`;
		foreach(@result)
		{
			print "result: $_ \n";
			if($_ =~ m/(\d+)\s*total/i)
			{
				$currentDirectorySize = $1;
				last;
			}
		}
		
		print "BB directory Size :: Current: $currentDirectorySize, Previous: $previousDirectorySize\n";
		if($currentDirectorySize == $previousDirectorySize)
		{
			$numberOfTimesToBeEqual--;
		}
		else
		{
			$numberOfTimesToBeEqual = 3;
		}
		
		if($numberOfTimesToBeEqual == 0)
		{
			$breakLoop = 1;
		}
		
		$previousDirectorySize = $currentDirectorySize;
	}
}

sub removeTabsAndSpaces{
	my($ref_txt) = @_;
	
	chomp($$ref_txt);
	$$ref_txt =~ s/^\s+//;
	$$ref_txt =~ s/\s+$//;
	$$ref_txt =~ s/^\t+//;
	$$ref_txt =~ s/\t+$//;
}

sub sendSMS{
	my($phoneNumber, $message) = @_;
	my $cmd = "testCT -s " . $phoneNumber . " \"" . $message . "\"";
	`$cmd`;
}

sub getBBDiagFolders{
	my($ref_array) = @_;
	
	my $BBLogPath = "/var/wireless/Library/Logs/CrashReporter/Baseband";
	
	opendir my($dh), $BBLogPath or die "Couldn't open directory '$BBLogPath': $!";
	my @files = grep { /.*\-diag$/ } readdir $dh;
	closedir $dh;
	
	print "List of Diag Folders \n";
	for(my $i = 0; $i < @files; $i++)
	{
		$$ref_array[$i] = $files[$i];
		print $files[$i] . "\n";
	}
}

sub statusOfBBDiagLogging{
	my $BBDiagLoggingStatus = "ENABLED";
	
	my @diagFolderList1 = ();
	my @diagFolderList2 = ();
	
	# Dump existing BB Logs
	dumpBBLogs("iTestPRO_BB_Power_tool : First Instance");
	
	# Get List of Diag Folders
	getBBDiagFolders(\@diagFolderList1);
	
	sleep 5;
	
	# Dump existing BB Logs
	dumpBBLogs("iTestPRO_BB_Power_tool : Second Instance");
	
	# Get List of Diag Folders
	getBBDiagFolders(\@diagFolderList2);
	
	# Compare the two lists
	if(@diagFolderList2 > @diagFolderList1)
	{
		print "BB DIAG Logging is enabled \n";
		$BBDiagLoggingStatus = "ENABLED";
	}
	else
	{
		print "BB DIAG Logging is disabled \n";
		$BBDiagLoggingStatus = "DISABLED";
	}
	
	return $BBDiagLoggingStatus;
}

sub dumpBBLogs{
	my($reason) = @_;
	
	my $cmd = "testCT -l " . $reason;
	`$cmd`;
	#sleep 10;
	
	my $i = 0;
	my $BBLogPath = "/var/wireless/Library/Logs/CrashReporter/Baseband";
	print "Checking If BB directory is created \n";
	while(!(-d $BBLogPath))
	{
  		sleep 1;
  		$i++;
  		if($i > 60)
  		{
  			print "No BB Logs Folder is Created, Timeout = 60 seconds\n";
  			last;
  		}
  		else
  		{
  			print "Waiting for BB Log Folder, Wait time Elapsed: $i\n";
  		}
  	}
  	print "BB directory is created \n";
  	
	waitUntilDirectorySizeIsConstant("/var/wireless/Library/Logs/CrashReporter/", 3);
}

sub getExistingBasebandLogFileList{
	
	my $existingBasebandLogFiles = "";
	my @files = ();
	
	# Get List of existing BB Log Files
	eval
	{
		#my $dirPath = "/var/wireless/Library/Logs/CrashReporter/Baseband/*";
		@files = </var/wireless/Library/Logs/CrashReporter/Baseband/*>;
	} or do { };
	
	# Update the list of existing Baseband Log Files
	foreach(@files)
	{
		$existingBasebandLogFiles = $existingBasebandLogFiles . "|" . $_;
		#print "File: $_\n";
	}
	$existingBasebandLogFiles = $existingBasebandLogFiles . "|";
	#$existingBasebandLogFiles =~ s/^\|+//;
	#$existingBasebandLogFiles =~ s/\|+$//;
	
	print "Existing BB Log Files : $existingBasebandLogFiles \n";
	
	return ($existingBasebandLogFiles);
}

sub getExistingPowerLogFileList{
	my ($powerLogsLocation) = @_;
	
	my $existingPowerLogFiles = "";
	my $lastModifiedPowerLogFile = "";
	my $lastModifiedPowerLogFileEpochTime = 0;

	# Get List of existing Power Log Files
	my @files = glob($powerLogsLocation . "*.powerlog");
	
	# Get the last Modified Power Log File
	foreach(my $i = 0; $i < @files; $i++)
	{
		my $modifiedTimeOfFile = (stat ($files[$i]))[9];	# Get Modified Time of the File
		
		# IF first File, assign it as last modified file
		# IF current File's Modified Time is greater than previous one, update the last modified file name
		if(($i == 0) | ($modifiedTimeOfFile > $lastModifiedPowerLogFileEpochTime))
		{
			$lastModifiedPowerLogFile = $files[$i];
			$lastModifiedPowerLogFileEpochTime = $modifiedTimeOfFile;
		}
	}

	# Update the list of existing Power Log Files (Except Latest Power Log File which is getting updated)
	foreach(@files)
	{
		if($_ ne $lastModifiedPowerLogFile)
		{
			$existingPowerLogFiles = $existingPowerLogFiles . "|" . $_;
		}
	}
	$existingPowerLogFiles =~ s/^\|+//;
	$existingPowerLogFiles =~ s/\|+$//;
	
	print "Old Power Log Files : $existingPowerLogFiles \n";
	print "Last Modified File : $lastModifiedPowerLogFile \n";
	
	return ($lastModifiedPowerLogFile, $existingPowerLogFiles);
}

sub dumpAndMovePowerLogs{
	my($iTestPROPowerLogsFolderPath) = @_;
		
	# Move Power Logs into iTestPROLogFolder power logs
	my $cmd = "mv /Library/Logs/CrashReporter/*.powerlog " . $iTestPROPowerLogsFolderPath;
	`$cmd`;

	# Stop Power log by deleting currentPowerlog
	`rm -rf /Library/Logs/CurrentPowerlog.powerlog`;
}

sub dumpAndMoveBBAndPowerLogsToiTestPROLogsFolderInCrashReporter{
	my($iTestPROLogFolderPath, $iTestPROPowerLogsFolderPath, $deviceBasebandLogsPath) = @_;
	
	# Create iTestPROLogFolder in CrashReporter
	my $cmd = "mkdir " . $iTestPROLogFolderPath;
	`$cmd`;
	
	# Create /PowerLogs folder in iTestPROLogFolder
	$cmd = "mkdir " . $iTestPROPowerLogsFolderPath;
	`$cmd`;
	
	# DUMP  and move BB Logs into iTestPROLogFolder
	dumpBBLogs("iTestPRO Power Tool Logs");
	$cmd = "mv " . $deviceBasebandLogsPath . " " . $iTestPROLogFolderPath;
	`$cmd`;
	
	# DUMP and move Power Logs into iTestPROLogFolder
	dumpAndMovePowerLogs($iTestPROPowerLogsFolderPath);
}

sub executePPScriptOnLogs{
	my($postProcessingScriptPath, $iTestPROPowerLogsFolderPath, $LOGFILE, $inputArgs) = @_;

	my $resultMessage = ""; #"iTestPRO_Power_Tool:Execution Complete.STATUS:";
	my $resultMessageFromPPLog = "NONE";
	
	if(!defined($inputArgs))
	{
		$inputArgs = "";
	}
	
	# Execute the Post processing Script
	my $cmd = "perl \"" . $postProcessingScriptPath . "\" \"" . $iTestPROPowerLogsFolderPath . "\" " . $inputArgs ;
	print "command:: $cmd \n";
	my @ppLog = `$cmd`;
	printToLogFile($LOGFILE, "====================== Post Processing Log Start ======================");
	foreach(@ppLog)
	{
		chomp($_);
		printToLogFile($LOGFILE, $_);
		
		if($_ =~ m/CRITERIA RESULT\: (.*)/i)
		{
			$resultMessageFromPPLog = $1;
		}
	}
	printToLogFile($LOGFILE, "====================== Post Processing Log End   ======================");
	
	$resultMessage = $resultMessage . $resultMessageFromPPLog;
	
	# Move Results to Power Logs Folder
	$cmd = "mv /var/root/PowerLog_ARM_Utility_Values.csv " . $iTestPROPowerLogsFolderPath;
	`$cmd`;
	
	$cmd = "mv /var/root/PowerLog_BatteryLevel_Values.csv " . $iTestPROPowerLogsFolderPath;
	`$cmd`;
	
	$cmd = "mv /var/root/PowerLog_PDF_CDF.csv " . $iTestPROPowerLogsFolderPath;
	`$cmd`;
	
	
	return($resultMessage);
}

sub deleteOldiTestPROPowerToolLogFolders{
	`rm -rf /var/wireless/Library/Logs/CrashReporter/iTestPROLogs*`;
}

sub moveiTestPROPowerToolLogAndResultFileToCrashReporter{
	my($ResultFileName, $LogFileName, $iTestPROLogFolderPath) = @_;
	
	my $cmd = "mv /var/root/" . $ResultFileName . " " . $iTestPROLogFolderPath;
	`$cmd`;
	$cmd = "mv /var/root/" . $LogFileName . " " . $iTestPROLogFolderPath;
	`$cmd`;	
}

sub setNoIdle{
	`nohup pmset noidle &`;
}

sub updatePowerLogDefaults{
	'defaults write com.apple.powerlog PLRotatePowerLog -bool NO';
}

sub delayBasedOnEpochTime{
	my($durationSeconds) = @_; 
	
	my $breakLoop = 0;
	my $startTime = `date +%s`;
	while($breakLoop == 0)
	{
		my $endTime = `date +%s`;
		my $delayElapsed = $endTime - $startTime;
		if($delayElapsed >= $durationSeconds)
		{
			$breakLoop = 1;
		}
	}
}







