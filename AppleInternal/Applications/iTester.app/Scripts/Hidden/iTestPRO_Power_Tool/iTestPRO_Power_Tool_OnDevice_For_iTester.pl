$|++;
use strict;
use Cwd;
use Time::Local;

use iTestPRO_onDevice_Modules qw(:All);

our $BB_POWER_TOOL_VERSION = "v2.2";
#----------------------------------------------------------------------------
# 
# FileName :    iTestPRO_Power_Tool_OnDevice_For_iTester.pl
# Author :		Ghayasuddin Mohammed (ghayasuddin@apple.com)
# Company :		Apple Inc
# Version :     2.2
# Date:         11/27/2012 (mm/dd/yyyy)
# 
# Modify Dates:   
#
# Version Update Info
#
# Description:
#    Script to run power test case on the device from iTester
# 
# How To Run(Syntax Examples):
#       >perl iTestPRO_Power_Tool_OnDevice_For_iTester.pl
#
#----------------------------------------------------------------------------

my ($sec, $min, $hr, $day, $mon, $year) = localtime;
our $formattedDateTime = ($mon+1) . "_" . $day . "_" . ($year+1900_). "_" . $hr . "hrs" . $min . "m" . $sec . "s";

our $iTestPROPowerToolPath = "/var/mobile/Documents/iTester/Scripts/Hidden/iTestPRO_Power_Tool/";
our $iTestPROPowerToolLogsPath = "/var/mobile/Library/Logs/iTestPRO_Power_Tool_Logs";
our $configFilePath = "/var/mobile/Library/Logs/iTestPRO_Power_Tool_Logs/config.txt";
our $iTestPROPowerToolResultsPath = "/var/mobile/Library/Logs/iTestPRO_Power_Tool_Logs/Results/";
our $toolLogsPath = "/var/mobile/Library/Logs/iTestPRO_Power_Tool_Logs/toolLogs/";
our $statusFilePath = "/var/mobile/Library/Logs/iTestPRO_Power_Tool_Logs/StatusHostory.txt";
our $userInputMarker = "NONE";

our $postProcessingScriptPath = $iTestPROPowerToolPath . "PowerLog_PostProcessing.pl";
our $powerLogsLocation = "/Library/Logs/CrashReporter/";

if(!(-d $iTestPROPowerToolLogsPath))
{ 
	mkdir $iTestPROPowerToolLogsPath;
}
if(!(-d $iTestPROPowerToolResultsPath))
{ 
	mkdir $iTestPROPowerToolResultsPath;
}
if(!(-d $toolLogsPath))
{ 
	mkdir $toolLogsPath;
}

#our $deviceCrashReporterPath = "/var/wireless/Library/Logs/CrashReporter/";
#our $deviceBasebandLogsPath = "/var/wireless/Library/Logs/CrashReporter/Baseband/";
#our $iTestPROLogFolderPath = $deviceCrashReporterPath . "iTestPROLogs_" . $formattedDateTime . "/";
#our $iTestPROPowerLogsFolderPath = $iTestPROLogFolderPath . "iTestPROPowerLogs" . "/";

my $choice = $ARGV[0];
if(defined($choice))
{
	if($choice =~ m/START/i)
	{
		startTool();
	}
	elsif($choice =~ m/STOP/i)
	{
		my $static_num_Of_Args = $#ARGV + 1;
		if($static_num_Of_Args >= 2)
		{
			$userInputMarker = $ARGV[1];
		}
		stopTool();
	}
	elsif($choice =~ m/STATUS/i)
	{
		getStatus();
	}
	elsif($choice =~ m/TEST/i)
	{
		print "Test Mode\n";
		test();
	}
}
else
{
	print "Incorrect Syntax. Input argument was not provided\n";
	print "Syntax: perl iTestPRO_Power_Tool_OnDevice_For_iTester.pl \"START\" \n";
	print "        perl iTestPRO_Power_Tool_OnDevice_For_iTester.pl \"STOP\" \n";
}

#-----------------------------------------------------------------------------------------
# *** MODULES ***
#-----------------------------------------------------------------------------------------
sub test{

	my $fileList = getExistingBasebandLogFileList();
	print "$fileList \n";

	#my($lastModifiedPowerLogFile, $existingPowerLogFiles) = getExistingPowerLogFileList($powerLogsLocation);
	#print "Old Power Log Files : $existingPowerLogFiles \n";
	#print "Last Modified File : $lastModifiedPowerLogFile \n";
	
	# Get List of existing Power Log Files
	#my @files = glob($powerLogsLocation . "*.powerlog");
	
	
	#my $bbDiagLoggingStatus = statusOfBBDiagLogging();
	#print "BB Diag Status = $bbDiagLoggingStatus \n";
}

sub getStatus{
	my $toolStatus = "Status: Not Running";
	
	eval
	{
		open (our $STATUSFILE, "<$statusFilePath");
		my @lines = reverse <$STATUSFILE>;
		foreach my $line (@lines) 
		{
			if($line =~ m/Started BB Power Tool \:\s*(.*)/i)
			{
				$toolStatus = "Status: Running \nStarted at $1 \n";
				last;
			}
			elsif($line =~ m/Stopped BB Power Tool \:\s*(.*)/i)
			{
				$toolStatus = "Status: Not Running \nLast Stopped at $1 \n";
				last;
			}
		}
		
		close $STATUSFILE;
	} or do { };
	
	print "$toolStatus\n";
}

sub startTool{

	my %htDeviceInfo= ();
	my $currentTestFolderName = "PowerToolLogs_" . $formattedDateTime;
	my $currentTestFolderPath = $iTestPROPowerToolResultsPath . $currentTestFolderName;
	my $LogFileName = $toolLogsPath . "iTestPRO_Log_Start_" . $formattedDateTime . ".txt";
	
	#========================================================================================
	# open Config File and Log File
	#========================================================================================
	open (our $CONFIGFILE, ">$configFilePath");
	open (our $LOGFILE, ">$LogFileName");
	open (our $STATUSFILE, ">>$statusFilePath");
	print $CONFIGFILE "CURRENT_TOOL_LOG_PATH=" . $LogFileName . "\n";
	printToLogFile($LOGFILE, "iTestPRO BB Power Tool Start : Script Started");
	print $STATUSFILE "\n\n=================================================\n";
	my $localTime = localtime;
	print $STATUSFILE "Started BB Power Tool : " . $localTime . "\n";
	
	#========================================================================================
	# Create Folder for Current Test and Write Current Test Folder Path in Config files
	#========================================================================================
	mkdir $currentTestFolderPath;
	print $CONFIGFILE "CURRENT_RESULT_FOLDER_PATH=" . $currentTestFolderPath . "\n";
	printToLogFile($LOGFILE, "Create Folder for Current Test: " . $currentTestFolderPath);
	
	#========================================================================================
	# Get BB DIAG Logging Status
	#========================================================================================
	eval
	{
		my $bbDiagLoggingStatus = statusOfBBDiagLogging();
		print $CONFIGFILE "CURRENT_BB_DIAG_LOGGING_STATUS=" . $bbDiagLoggingStatus . "\n";
		printToLogFile($LOGFILE, "Current BB Diag Logging Status: " . $bbDiagLoggingStatus);
	} or do { printToLogFile($LOGFILE, "Error :: while getting BB Logging Status : $@");  };
	
	#========================================================================================
	# Enable Power Logging
	#========================================================================================
	system('coreautomationd -command "settings.setPowerlogEnabled:" -bool Yes ');
	printToLogFile($LOGFILE, "Enable Power Logging");
	
	#========================================================================================
	# Get the List of Existing Power Logs
	#========================================================================================
	printToLogFile($LOGFILE, "Getting List of Existing Power logs and current/last modified power log");
	my $lastModifiedPowerLogFile = "";
	my $existingPowerLogFiles = "";
	eval
	{
		my ($lastModifiedPowerLogFile_local, $existingPowerLogFiles_local) = getExistingPowerLogFileList($powerLogsLocation);
		$lastModifiedPowerLogFile = $lastModifiedPowerLogFile_local;
		$existingPowerLogFiles = $existingPowerLogFiles_local;
		print $CONFIGFILE "LIST_OF_EXISTING_POWER_LOGS=" . $existingPowerLogFiles . "\n";
		print $CONFIGFILE "LAST_MODIFIED_POWER_LOG=" . $lastModifiedPowerLogFile . "\n";
	} or do { printToLogFile($LOGFILE, "Error :: while getting power logs list : $@");  };
	
	#========================================================================================
	# Rsync the Current Power Log File to Current Test Folder
	#========================================================================================
	printToLogFile($LOGFILE, "Copy current power log file");
	eval
	{
		my $cmd = "rsync -av $lastModifiedPowerLogFile " . $currentTestFolderPath . "/startLog.powerlog";
		`$cmd`;
	} or do { printToLogFile($LOGFILE, "Error :: while rsyncing start power log : $@");  };
	
	#========================================================================================
	# Get the List of Existing Baseband Logs
	#========================================================================================
	printToLogFile($LOGFILE, "Getting List of Existing Baseband logs");
	eval
	{
		my($existingBBLogs) = getExistingBasebandLogFileList();
		print $CONFIGFILE "LIST_OF_EXISTING_BB_LOGS=" . $existingBBLogs . "\n";
	} or do { printToLogFile($LOGFILE, "Error :: while getting existing BB logs list : $@");  };

	#========================================================================================
	# Set/get Initial Configuration/Info
	#========================================================================================
	printToLogFile($LOGFILE, "*****Device Info*****");
	getDeviceInfo(\%htDeviceInfo);
	printToLogFile($LOGFILE, "DEVICE_PHONE_NUMBER >> " . $htDeviceInfo{"DEVICE_PHONE_NUMBER"});
	printToLogFile($LOGFILE, "DEVICE_IMEI >> " . $htDeviceInfo{"DEVICE_IMEI"});
	printToLogFile($LOGFILE, "DEVICE_FIRMWARE_BB_VERSION >> " . $htDeviceInfo{"DEVICE_FIRMWARE_BB_VERSION"});
	printToLogFile($LOGFILE, "DEVICE_REGISTRATION_STATUS >> " . $htDeviceInfo{"DEVICE_REGISTRATION_STATUS"});
	printToLogFile($LOGFILE, "DEVICE_NETWORK_OPERATOR >> " . $htDeviceInfo{"DEVICE_NETWORK_OPERATOR"});
	printToLogFile($LOGFILE, "DEVICE_SOFTWARE_VERSION >> " . $htDeviceInfo{"DEVICE_SOFTWARE_VERSION"});
	printToLogFile($LOGFILE, "DEVICE_SOFTWARE_AP_BUILD >> " . $htDeviceInfo{"DEVICE_SOFTWARE_AP_BUILD"});
	printToLogFile($LOGFILE, "DEVICE_HARDWARE_INFO	>> " . $htDeviceInfo{"DEVICE_HARDWARE_INFO"});
		
	print $STATUSFILE "SCRIPT VERSION >> " . $BB_POWER_TOOL_VERSION . "\n";
	print $STATUSFILE "DEVICE_PHONE_NUMBER >> " . $htDeviceInfo{"DEVICE_PHONE_NUMBER"} . "\n";
	print $STATUSFILE "DEVICE_IMEI >> " . $htDeviceInfo{"DEVICE_IMEI"} . "\n";
	print $STATUSFILE "DEVICE_FIRMWARE_BB_VERSION >> " . $htDeviceInfo{"DEVICE_FIRMWARE_BB_VERSION"} . "\n";
	print $STATUSFILE "DEVICE_REGISTRATION_STATUS >> " . $htDeviceInfo{"DEVICE_REGISTRATION_STATUS"} . "\n";
	print $STATUSFILE "DEVICE_NETWORK_OPERATOR >> " . $htDeviceInfo{"DEVICE_NETWORK_OPERATOR"} . "\n";
	print $STATUSFILE "DEVICE_SOFTWARE_VERSION >> " . $htDeviceInfo{"DEVICE_SOFTWARE_VERSION"} . "\n";
	print $STATUSFILE "DEVICE_SOFTWARE_AP_BUILD >> " . $htDeviceInfo{"DEVICE_SOFTWARE_AP_BUILD"} . "\n";
	print $STATUSFILE "DEVICE_HARDWARE_INFO	>> " . $htDeviceInfo{"DEVICE_HARDWARE_INFO"} . "\n";
	
	printToLogFile($LOGFILE, "=======Script Ended=======");
	printToLogFile($LOGFILE, "***iTestPRO BB Power Tool Started***");
	
	close $CONFIGFILE;
	close $LOGFILE;
	close $STATUSFILE;
}

sub stopTool{
	
	my %htDeviceInfo= ();

	my $currentTestFolderPath = "";
	my @listOfExistingPowerLogs = ();
	my $listOfExistingPowerLogs_scalar = "";
	my $LogFileName = "";
	my $bbDiagLoggingStatus = "ENABLED";
	my $lastModifiedPowerLog = "";
	my $listOfExistingBBLogs_scalar = "";

	
	#========================================================================================
	# Set/get Initial Configuration/Info
	#========================================================================================
	getDeviceInfo(\%htDeviceInfo);
	
	#========================================================================================
	# open Config File and get details from config file
	#========================================================================================
	open (our $STATUSFILE, ">>$statusFilePath");
	open (our $CONFIGFILE, "<$configFilePath");

	eval
	{	
		while(my $line = <$CONFIGFILE>)
		{
			if($line =~ m/CURRENT_RESULT_FOLDER_PATH\=(.*)/i)
			{
				$currentTestFolderPath = $1;
				print "Current Test Folder Path: $currentTestFolderPath \n";
			}
			elsif($line =~ m/LIST_OF_EXISTING_POWER_LOGS\=(.*)/i)
			{
				$listOfExistingPowerLogs_scalar = $1;
				@listOfExistingPowerLogs = split('\|', $listOfExistingPowerLogs_scalar);
				print "List of Existing Power Logs: $listOfExistingPowerLogs_scalar \n";
			}
			elsif($line =~ m/CURRENT_TOOL_LOG_PATH\=(.*)/i)
			{
				$LogFileName = $1;
				print "Log File Name: $LogFileName \n";
			}
			elsif($line =~ m/CURRENT_BB_DIAG_LOGGING_STATUS\=(.*)/i)
			{
				$bbDiagLoggingStatus = $1;
				print "BB Diag Logging Status: $bbDiagLoggingStatus \n";
			}
			elsif($line =~ m/LAST_MODIFIED_POWER_LOG\=(.*)/i)
			{
				$lastModifiedPowerLog = $1;
				print "Last Modified Power Log: $lastModifiedPowerLog \n";
			}
			elsif($line =~ m/LIST_OF_EXISTING_BB_LOGS\=(.*)/i)
			{
				$listOfExistingBBLogs_scalar = $1;
			}
		}
	} or do { print "Error :: while reading from config file : $@";  };
	
	#========================================================================================
	# Open Log File and append
	#========================================================================================
	open (our $LOGFILE, ">>$LogFileName");
	printToLogFile($LOGFILE, "iTestPRO BB Power Tool Stop : Script Started");
	
	#========================================================================================
	# Get Last Modified Power Log file Name Only
	#========================================================================================
	my @path = split('\/', $lastModifiedPowerLog);
	my $lastModifiedPowerLogFileNameOnly = "iTESTPRO_BB_TOOL_NONE_XYYYZZZZ";
	if(length($path[@path - 1]) > 0)
	{
		$lastModifiedPowerLogFileNameOnly = $path[@path - 1];
		printToLogFile($LOGFILE, "STEP: Last Modified Power Log File Name: $lastModifiedPowerLogFileNameOnly");
	}
	
	#========================================================================================
	# Get the Power Logs for this test only
	#========================================================================================
	printToLogFile($LOGFILE, "STEP: Copy the power Logs of this Test to Results folder");
	eval
	{
		my @allPowerLogfiles = glob($powerLogsLocation . "*.powerlog");
		foreach(@allPowerLogfiles)
		{
			#----------------------------------------------------------------------------
			# If Power Log File does not contain in the existing power log list, copy it
			#----------------------------------------------------------------------------
			if($listOfExistingPowerLogs_scalar !~ m/$_/i)
			{
				eval
				{
					my $cmd = "rsync -av $_ " . $currentTestFolderPath;
					printToLogFile($LOGFILE, "RSYNC Command: $cmd");
					my @output = `$cmd`;
					
					# Print output to log
					foreach(@output)
					{
						printToLogFile($LOGFILE, "$_");
					}
				} or do { printToLogFile($LOGFILE,"Error :: while copying power log : $@");  };
			}
			
			#----------------------------------------------------------------------------
			# If current Power Log equals last modified power log, remove the top lines
			#----------------------------------------------------------------------------
			my $NumberOfExtraLinesToTruncate = 1;
			if($_ =~ m/$lastModifiedPowerLogFileNameOnly/i)
			{
				eval
				{
					printToLogFile($LOGFILE, "\n");
					printToLogFile($LOGFILE, "========= Truncate this File =========");
					my $cmd = "wc -l " . $currentTestFolderPath . "/startLog.powerlog";
					my $output = `$cmd`;
					if($output =~ m/(\d+)/i)
					{
						if($1 > 0)
						{
							$NumberOfExtraLinesToTruncate = $1;
						}
					}
					printToLogFile($LOGFILE, "Number of Extra Lines to truncate from power log: $NumberOfExtraLinesToTruncate");
					
					my $sedCommand = "sed -i '' '1,$NumberOfExtraLinesToTruncate" . "d' " . $currentTestFolderPath . "/" . $lastModifiedPowerLogFileNameOnly;
					printToLogFile($LOGFILE, "sed command: $sedCommand");
					`$sedCommand`;
					printToLogFile($LOGFILE, "======================================");
					printToLogFile($LOGFILE, "\n");
				} or do { printToLogFile($LOGFILE,"Error :: while removing top lines from start power log : $@");  };
			}
		}
	} or do { printToLogFile($LOGFILE,"Error :: while getting the power logs : $@");  };
	
	#----------------------------------------------------------------------------
	# Remove Start Log
	#----------------------------------------------------------------------------
	eval
	{
		my $cmd = "rm -rf " . $currentTestFolderPath . "/startLog.powerlog";
		printToLogFile($LOGFILE,"Delet Start Power Log, cmd: $cmd");
		`$cmd`;
	} or do { printToLogFile($LOGFILE,"Error :: while deleting start power log : $@");  };
	
	#========================================================================================
	# If BB Logging Enabled, Rsync BB logs for this test only
	#========================================================================================
	eval
	{
		if($bbDiagLoggingStatus =~ m/ENABLED/i)
		{
			# Dump existing BB Logs for this test
			dumpBBLogs("iTestPRO_BB_Power_tool : Testing Logs");
		
			printToLogFile($LOGFILE, "Getting List of Existing Baseband logs");
			my($listofBBLogs_scalar) = getExistingBasebandLogFileList();
			my @BBLogs = split('\|', $listofBBLogs_scalar);
			
			foreach(@BBLogs)
			{
				#----------------------------------------------------------------------------
				# If BB Log File does not contain in the existing BB log list, copy it
				#----------------------------------------------------------------------------
				my $path = "|" . $_ . "|";
				if($listOfExistingBBLogs_scalar !~ m/\|$_\|/i)
				{
					eval
					{
						$currentTestFolderPath =~ s/\/+$//;
						my $cmd = "rsync -av $_ " . $currentTestFolderPath . "/BasebandLogs/";
						printToLogFile($LOGFILE, "RSYNC Command: $cmd");
						my @output = `$cmd`;
						
						# Print output to log
						foreach(@output)
						{
							printToLogFile($LOGFILE, "$_");
						}
					} or do { printToLogFile($LOGFILE,"Error :: while copying BB log : $@");  };
				}
			}
		}
	} or do { printToLogFile($LOGFILE,"Error :: while copying BB logs for this test only : $@");  };
	
	#========================================================================================
	# Execute Post Processing script on Power Logs
	#========================================================================================
	my $inputArgs = "";
	#if($bbDiagLoggingStatus =~ m/DISABLED/i)
	#{
		#$inputArgs = "ThresholdsForEndUserMode:ARM=30,BDPH=4";
		#$inputArgs = "USETHRESHOLDS=BBOFF";
	#}
	#elsif($bbDiagLoggingStatus =~ m/ENABLED/i)
	#{
		#$inputArgs = "ThresholdsForEndUserMode:ARM=50,BDPH=4";
		#$inputArgs = "USETHRESHOLDS=BBON";
	#}
	
	my $currentTestFolderPath_withTAG = "iTestPROLOGPATH=" . $currentTestFolderPath;
	my $smsResultToSend = "";
	eval 
	{
		$smsResultToSend = executePPScriptOnLogs($postProcessingScriptPath, $currentTestFolderPath_withTAG, $LOGFILE,$inputArgs);
	} or do { printToLogFile($LOGFILE,"Error :: while running PP Script on power logs : $@");  };

	eval
	{
		# If to file radar, give Log Folder name in SMS
		if($smsResultToSend =~ m/Priority/i)
		{
			$currentTestFolderPath =~ s/\/+$//;
			my @tempPath = split('\/', $currentTestFolderPath);
			$smsResultToSend = $smsResultToSend . "; Logs Folder=" . $tempPath[@tempPath - 1];
		}
		$smsResultToSend = "iTestPRO_BB_Power_Tool Finished: " . $smsResultToSend;
	} or do { };
	
	#========================================================================================
	# Update and Copy Status File
	#========================================================================================
	print $STATUSFILE "RESULT : " . $smsResultToSend . "\n";
	my $localTime = localtime;
	print $STATUSFILE "Stopped BB Power Tool : " . $localTime . "\n";
	print $STATUSFILE "=================================================\n";
	close $STATUSFILE;
	eval
	{
		my $copyCmd = "cp " . $statusFilePath . " " . $currentTestFolderPath;
		`$copyCmd`;
	} or do { printToLogFile($LOGFILE,"Error :: while copying history file to current test logs folder : $@");  };
	
	#========================================================================================
	# If User input marker is given, create a file and put the marker in it
	#========================================================================================
	printToLogFile($LOGFILE, "Create Marker File User Input: $userInputMarker");
	eval
	{
		$currentTestFolderPath =~ s/\/+$//;
		my $cmd = "touch " . $currentTestFolderPath . "/userReason.txt";
		printToLogFile($LOGFILE, "Create Marker File: $cmd");
		`$cmd`;
		
		$cmd = "echo \"User Requested Reason:" . $userInputMarker . "\" > " . $currentTestFolderPath . "/userReason.txt";
		`$cmd`;
	} or do { };

	
	#========================================================================================
	# Move this sciprts log files and result file into iTestPROPowerLogs folder
	#========================================================================================
	eval
	{
		my $moveCmd = "mv " . $currentTestFolderPath . " /var/mobile/Library/Logs/CrashReporter/";
		`$moveCmd`;
	} or do { printToLogFile($LOGFILE,"Error :: while moving BB logs to current test logs folder : $@");  };
	
	#========================================================================================
	# Send SMS When Test Execution and PP is completed
	#========================================================================================
	eval
	{
		sendSMS($htDeviceInfo{"DEVICE_PHONE_NUMBER"}, $smsResultToSend);
	} or do { printToLogFile($LOGFILE,"Error :: while sending SMS : $@");  };


	printToLogFile($LOGFILE, "Script Ended");
	printToLogFile($LOGFILE, "***iTestPRO Power Tool Ended***");
	print "\n\n\n";
	printToLogFile($LOGFILE, "***Please follow the instructions in the messagge you recevied!!***");
	
	close $CONFIGFILE;
	close $LOGFILE;
}
