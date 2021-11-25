#--------------------------START OF DOCUMENTATION--------------------------------------------------
# 
# FileName :    PowerLog_PostProcessing.pl
# Version :     3.6
# Date:         10/30/2012 (mm/dd/yyyy)
# Author:	    Ghayasuddin Mohammed (ghayasuddin@apple.com)
# 
# Modify Dates:   
#	v2.1	:	11/26/2012 (mm/dd/yyyy)
#	v2.2	:	11/29/2012 (mm/dd/yyyy)
#	v2.3	:	11/29/2012 (mm/dd/yyyy)
#	v2.4	:	12/03/2012 (mm/dd/yyyy)
#	v2.5	:	12/04/2012 (mm/dd/yyyy)
#	v2.6	:	12/05/2012 (mm/dd/yyyy)
#	v2.7	:	12/11/2012 (mm/dd/yyyy)
#	v2.8	:	12/13/2012 (mm/dd/yyyy)
#	v3.0	:	12/18/2012 (mm/dd/yyyy)
#	v3.1	:	01/03/2012 (mm/dd/yyyy)
#	v3.2	:	01/10/2012 (mm/dd/yyyy)
#	v3.3	:	01/15/2012 (mm/dd/yyyy)
#	v3.4	:	01/17/2012 (mm/dd/yyyy)
#	v3.5	:	01/19/2012 (mm/dd/yyyy)
#	v3.6	:	01/21/2012 (mm/dd/yyyy)
# 
# Version Update Info:
#	v2.1:
#	1. 	Display ON Duration
#	2.	Display OFF Duration
#
#	v2.2:
#		Ignore While in Charging State
#
#	v2.3:
#		AP Awake Time
#		BB Connected mode Duration for WCDMA
#
#	v2.4:
#		Ignore any duration when assertion is held by audio
#
#	v2.5:
#		Update Thresholds to ARM Utility = 50%
#		Add for End User Mode Threshold/Criteria for Result
#
#	v2.6:
#		Update PDF/CDF Plots to print from Min to Max rather than Max to Min
#		Fixed Issue: Error in calculating ARM Utility (with User Activity) due to BAttery Charging State misplaced variable
#
#	v2.7:
#		Remove BDPH for End User Mode
#
#	v2.8:
#		Additional Fxnality for N94 as it has different search string for ARM Utility
#
#	v3.0:
#		Completely overhauled the script with following changes:
#		1. Sort based on timestamp  (all messages are on same clock) and then calculate
#		2. BDPH Bin-ing 0 to 20 with 0.5 bin size
#		3. Remove extra -9999 when other messages
#		4. User Activity and Non-User Activity Durations
#		5. Voice Call Duration (WCDMA)
#		6. Input argument: EndUserMode or FocusedTestMode or can give endUserMode threshold values and Help
#
#	v3.1:
#		Minor change wrt handling when input logs folder path is given
#
#	v3.2:
#		Add MPSS PDF/CDF Calculation (will be used when BB logging is ON)
#		Input parameter to select MPSS vs ARM Utility and their thresholds
#		Input parameter to decide on priority (Format: P1=90;P2=80:90;P3=70:80    first value: >= second value: < )
#		Seperate csv file for above threshold ARM/MPSS values (including flag for consecutive samples)
#		
#		Priority Decision:
#					BB ON: 						BB Off:
#		P1			>=90						>=80				(Occurance)
#		P2			>=80 and <90				>=65 and <80		(CDF of 99%)
#		P3			>70 and <80					>50 and <65			(CDF of 99%)
#		P4			No Radar					No Radar
#
#	v3.3:
#		Ignore ARM Activity when APPS/Peripherals are above minimum threshold
#		Normalization for time duration: Reset the timer when we ignore the Value
#		BB on and off has same priority decision as below
#
#		Priority Decision:
#					BB ON/OFF:
#		P1			>=80				(Occurance)
#		P2			>=70 and <80		(CDF of 99%)
#		P3			>60 and <70			(CDF of 99%)
#		P4			No Radar
#
#	v3.4:
#		Priority Decision:
#					BB ON/OFF:
#		P1			>=85				(CDF of 99%) or any occurrence of =100 
#		P2			>=70 and <85		(CDF of 99%)
#		P3			>60 and <70			(CDF of 99%)
#		P4			No Radar
#
#	v3.5:
#		Remove Battery Charging from User Activity
#
#	v3.6:
#		Add code to remove personal hotspot as it is a user activity
#		Threshold for taking ARM only when APPS/Peripherals value is  (P3_Threshold_Min - 10) [Previously it was P3_Threshold_Min]
# 
# Description:
#     Script to get the PDF/CDF for Power Level and ARM Utility:
#		
#
#--------------------------END OF DOCUMENTATION--------------------------------------------------

use strict;
use Cwd;
use POSIX qw/floor/;
use Time::Local;
#use DateTime;

our $DEBUG_MODE = 0;
our $PRINT_DURATION_PRINTS = 1;  # REMOVE

my $logsFolderPath = "";
my $static_num_Of_Args = $#ARGV + 1;
if($static_num_Of_Args == 1)
{
	$logsFolderPath = $ARGV[0];
}

#=========================================================================================
# CONFIG
#=========================================================================================
our $scriptMode = "EndUserMode";  # "FocusedTestMode" "EndUserMode"

# Thresholds -- Default
my $ARM_Activity_Max_PDF_Bucket = "50";
my $Battery_Drain_Max_PDF_Bucket = "4";
my $ARM_Activity_Max_PDF_Bucket_Filtered = "50";
my $Battery_Drain_Max_PDF_Bucket_Filtered = "4";

#NOTE: Only these values are used no matter whether BBON or BBOFF (v3.3 update)

my $useThresholds = "BBON"; #"BBOFF"  
my $CDFPercentToLookFor = "99";
my $P1_Threshold = "85";
my $P2_Threshold_Min = "70";
my $P2_Threshold_Max = "85";
my $P3_Threshold_Min = "60";
my $P3_Threshold_Max = "70";

# Bins
our $roundingFactor = "%0.6f";
my $userDefinedDurationForBatteryLevelBining = 3600;
my $userDefinedDurationForARMActivityBining = 300;
my $userDefinedDurationForMPSSActivityBining = 300;
my $userDefinedDurationForARMActivityBining_Filtered = 300;
my $userDefinedDurationForMPSSActivityBining_Filtered = 300;
my $userDefinedDurationForBatteryLevelBining_Filtered = 300;

if($static_num_Of_Args >= 1)
{
	for(my $i = 0; $i < $static_num_Of_Args; $i++)
	{
		my $temp = $ARGV[$i];
		if($temp =~ m/MODE\=EndUserMode/i)
		{
			$scriptMode = "EndUserMode";
		}
		elsif($temp =~ m/MODE\=FocusedTestMode/i)
		{
			$scriptMode = "FocusedTestMode";
		}
		
		if($temp =~ m/USETHRESHOLDS\=(.*)/i)
		{
			$useThresholds = $1;
			
			if($useThresholds =~ m/BBOFF/i)  # Same Values as BB ON is applied
			{
				$P1_Threshold = "85";
				$P2_Threshold_Min = "70";
				$P2_Threshold_Max = "85";
				$P3_Threshold_Min = "60";
				$P3_Threshold_Max = "70";
			}
		}
		
		if($temp =~ m/iTestPROLOGPATH\=(.*)/i)
		{
			$logsFolderPath = $1;
		}
		
		if($temp =~ m/ThresholdsForEndUserMode\:ARM\=(\d+)\,BDPH\=(\d+)/i)
		{
			if($1 > 0) { $ARM_Activity_Max_PDF_Bucket_Filtered = $1; }
			if($2 > 0) { $Battery_Drain_Max_PDF_Bucket_Filtered = $2; }
			print "Updated Thresholds For EndUserMode based on User Input: \n";
			print "ARM Activity : $ARM_Activity_Max_PDF_Bucket \n";
			print "BDPH         : $Battery_Drain_Max_PDF_Bucket \n";
		}
		
		if($temp =~ m/DEBUGMODE/i)
		{
			$DEBUG_MODE = 1;
		}
		
		if(($temp =~ m/HELP/i) | ($temp =~ m/\-+H/i))
		{
			print "Syntax for this script:\n";
			print "--------------------------------------------------------------------------------------------------------------\n";
			print "1. perl PowerLog_PostProcessing.pl \n";
			print "2. perl PowerLog_PostProcessing.pl \"FullLogsFolderPath\"                   [If Logs are not in the CD]\n";
			print "3. perl PowerLog_PostProcessing.pl Mode=FocusedTestMode                     [For Focused Test Mode] \n";
			print "4. perl PowerLog_PostProcessing.pl Mode=EndUserMode                         [Default is EndUserMode] \n";
			print "5. perl PowerLog_PostProcessing.pl ThresholdsForEndUserMode:ARM=20,BDPH=2   [Applicable to EndUserMode only]  \n";
			print "6. perl PowerLog_PostProcessing.pl USETHRESHOLD=BBON                        [Use BB On or off thresholds based on given input] \n";
			print "7. perl PowerLog_PostProcessing.pl -h                                       [Prints this help] \n";
			print "--------------------------------------------------------------------------------------------------------------\n";
			die;
		}
	}
}

print "***** SCRIPT EXECUTION MODE: $scriptMode *****\n";

# Thresholds/Criteria ( Default Values are End User Mode )
	# Focused Mode
	if($scriptMode =~ m/FocusedTestMode/i)
	{
		$ARM_Activity_Max_PDF_Bucket = "50";
		$Battery_Drain_Max_PDF_Bucket = "4";

		$userDefinedDurationForBatteryLevelBining = 3600; # RATEperHOURbasedOnUserDefinedBin
		$userDefinedDurationForARMActivityBining = 300;
	}

	
	# End User Mode
		# Default Values are End User Mode
	#if($scriptMode =~ m/EndUserMode/i)
	#{
	#	$ARM_Activity_Max_PDF_Bucket_Filtered = "50";
	#	$Battery_Drain_Max_PDF_Bucket_Filtered = "4";
	#}
#=========================================================================================

our $current_Log_Directory = getcwd;
my @static_log_file_names = <*.powerlog>;
if (-d $logsFolderPath)
{
	$current_Log_Directory = $logsFolderPath;
	$current_Log_Directory =~ s/\/$//;
	chdir $current_Log_Directory;
	
	$logsFolderPath = $logsFolderPath . "/*.powerlog";
	print "Log Folder : $logsFolderPath \n";
	@static_log_file_names = glob "$logsFolderPath";
}

#----------------------------------------------------------------------------
# Variables
#----------------------------------------------------------------------------
our $criteriaResult = "Criteria met, Don't file any radar";

my $ResultFilePDFCDF = "PowerLog_PDF_CDF.csv";
open (my $CSV_RESULT_PDF_CDF, ">$ResultFilePDFCDF");

my $armUtilityValuesFile = "PowerLog_ARM_Utility_Values.csv";
open (my $CSV_RESULT_ARM_UTILITY_VALUES, ">$armUtilityValuesFile");

my $mpssUtilityValuesFile = "PowerLog_MPSS_Utility_Values.csv";
open (my $CSV_RESULT_MPSS_UTILITY_VALUES, ">$mpssUtilityValuesFile");

my $BatteryLevelValuesFile = "PowerLog_BatteryLevel_Values.csv";
open (my $CSV_RESULT_BatteryLevel_VALUES, ">$BatteryLevelValuesFile");

my $KPIFile = "PowerLog_KPIs.csv";
open (my $CSV_RESULT_KPIS, ">$KPIFile");

my $armUtilityValuesFile1 = "PowerLog_ARM_Utility_Values_aboveThreshold.csv";
open (my $CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD, ">$armUtilityValuesFile1");

my $mpssUtilityValuesFile1 = "PowerLog_MPSS_Utility_Values_aboveThreshold.csv";
open (my $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD, ">$mpssUtilityValuesFile1");

#----------------------------------------------------------------------------

my $HeaderValues = "TotalLogDuration,DisplayOnDuration,DisplayOffDuration,DisplayUnknownDuration,APSleepDuration,APAwakeDuration,APUnknownDuration,BBWCDMAConnectedModeDuration,BBWCDMANOTConnectedModeDuration,BBWCDMAUnknownModeDuration,DurationOfUserUsingTheDevice,DurationOfUserNotUsingTheDevice,WCDMAVoiceCallDuration";
our @HeaderIndices = split(',', $HeaderValues);

print $CSV_RESULT_ARM_UTILITY_VALUES "FILENAME, DATE_TIME, VALUE, TIMEDIFF, ARMActivityValue, ARMActivityValue_Filtered \n";
print $CSV_RESULT_MPSS_UTILITY_VALUES "FILENAME, DATE_TIME, VALUE, TIMEDIFF, MPSSActivityValue, MPSSActivityValue_Filtered \n";
print $CSV_RESULT_BatteryLevel_VALUES "FILENAME, DATE_TIME, VALUE, TIMEDIFF, VALUEDIFF, BDPH, BDPH_Filtered \n";
print $CSV_RESULT_KPIS "FileName, $HeaderValues \n";
print $CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD "FILENAME, DATE_TIME, TIMEDIFF, ARMActivityValue_Filtered, isConsecutiveValue \n";
print $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD "FILENAME, DATE_TIME, TIMEDIFF, MPSSActivityValue_Filtered, isConsecutiveValue \n";

my %ht_Cumulative_KPIs   = ();
$ht_Cumulative_KPIs{FileName} = "Cumulative";
#=========================================================================================

my $numberOfLogs = 0;
foreach my $file (@static_log_file_names)
{
	print "Processing File : $file \n";
	open (my $LOGFILE, "<$file");
	
	print $CSV_RESULT_ARM_UTILITY_VALUES "$file \n";
	print $CSV_RESULT_MPSS_UTILITY_VALUES "$file \n";
	print $CSV_RESULT_BatteryLevel_VALUES "$file \n";
	print $CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD "$file \n";
	print $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD "$file \n";
	
	my %ht_Current_Log_KPIs   = ();
	$ht_Current_Log_KPIs{FileName} = $file;
		
	my %ht_ForValuesOfCurrentLogFile = ();
	my $ARMUtilityDurationTracking = 0;
	my $getLogStartTimeStamp = 1;
	
	my $currentDate = "";
	my $currentTime = "";
	my $currentEpochTime = "";
	
	my $currentARMUtilityValue = "";		# To track these two values and add when we get the
	my $currentAPPSXOShutdownValue = "";	# Peripherals value.
	
	while(my $line = <$LOGFILE>)
	{
		
		$currentDate = "";
		$currentTime = "";
		$currentEpochTime = "";

		if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*/i)
		{
			$currentDate = $1 . "-" . $2 . "-"  . $3;
			
			my $decValue = $7;
			if(length($decValue) == 0)
			{
				$decValue = ".0";
			}
			$currentTime = $4 . ":" . $5 . ":"  . $6 . $decValue;
			
			$currentEpochTime = timelocal($6, $5, $4, $2, $1 - 1, $3);
			
			$currentEpochTime = $currentEpochTime . $decValue;
			
			if($getLogStartTimeStamp == 1)
			{
				addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "LOG_START_TIME", "YES");
				$getLogStartTimeStamp = 0;
			}
		}
		
		
		if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Battery\](.*)charging_state\=Inactive;/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "BATTERY_CHARGING_INACTIVE", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Battery\](.*)charging_state\=Active;/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "BATTERY_CHARGING_ACTIVE", "YES");
		}
		
		if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[BB HW Log\]\s*.*Duration\=(\d+).(\d+)\;/i)
		{
			$ARMUtilityDurationTracking = $8 . "." . $9;
			if($ARMUtilityDurationTracking < 0)
			{
				$ARMUtilityDurationTracking = 0;
			}
		}
		elsif(($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW RPM\]\s*XO_Shutdown\=\[(\d+)\.(\d+)\%\,(\d+)\]\;\s*VDD_Min\=\[(\d+)\.(\d+)\%\,(\d+)\]/i) |
			($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Processor\]\s*System_State\=\[(\d+)(\.\d+)?\,/i))
		{
			my $armUtilityValue = -9999;
			
			# For Post-Innsbruck
			if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW RPM\]\s*XO_Shutdown\=\[(\d+)\.(\d+)\%\,(\d+)\]\;\s*VDD_Min\=\[(\d+)\.(\d+)\%\,(\d+)\]/i)
			{
				my $xoShutdownValue = $8 . "." . $9;
				$armUtilityValue = $11 . "." . $12;
				$armUtilityValue = sprintf ($roundingFactor, 100 - $armUtilityValue - $xoShutdownValue);
			}
			# For Pre-Innsbruck
			elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Processor\]\s*System_State\=\[(\d+)(\.\d+)?\,/i)
			{
				my $tempValue = $8 . $9;
				$armUtilityValue = sprintf ($roundingFactor, 100 - $tempValue);
			}
			
			$armUtilityValue = sprintf("%.0f", $armUtilityValue);
			$armUtilityValue = floor($armUtilityValue);
			$currentARMUtilityValue = $armUtilityValue;
			
			# Add this when we get the peripherals value
			#addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "ARMUtility=" . $armUtilityValue . ";ARMUtilityDuration=" . $ARMUtilityDurationTracking, "YES");
		}
		elsif(($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW APPS\]\s*.*CXO_Shutdown\=\[(\d+)\.(\d+)\%\,(\d+)\]\;/i) |
			($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Processor\]\s*System_State\=\[(\d+)(\.\d+)?\,/i))
		{
			$currentAPPSXOShutdownValue = -9999;
				
			# For Post-Innsbruck
			if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW APPS\]\s*.*CXO_Shutdown\=\[(\d+)\.(\d+)\%\,(\d+)\]\;/i)
			{
				my $xoShutdownValue = $8 . "." . $9;
				$currentAPPSXOShutdownValue = sprintf ($roundingFactor, 100 - $xoShutdownValue);
			}
			# For Pre-Innsbruck
			elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Processor\]\s*System_State\=\[(\d+)(\.\d+)?\,/i)
			{
				#my $tempValue = $8 . $9;
				#$armUtilityValue = sprintf ($roundingFactor, 100 - $tempValue);
				$currentAPPSXOShutdownValue = 0; # NEED TO UPDATE
			}
			
			$currentAPPSXOShutdownValue = sprintf("%.0f", $currentAPPSXOShutdownValue);
			$currentAPPSXOShutdownValue = floor($currentAPPSXOShutdownValue);
		}
		elsif(($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Peripherals\]\s*USB\=\[\d+(\.\d+)?,\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*SPI\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*UART\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*GPS\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*GPS\_DPO\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\];/i) |
			($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Peripherals\]\s*GPS\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*USB\=\[\d+(\.\d+)?,(\d+)(\.\d+)?\%\]\;\s*SPI\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*UART\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;/i))
		{
			my $peripheralsValue = -9999;
			my $usbValue = 0;
			my $spiValue = 0;
			my $uartValue = 0;
			my $gpsValue = 0;
			my $gpsDOValue = 0;
			
			# For Post-Innsbruck
			if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Peripherals\]\s*USB\=\[\d+(\.\d+)?,\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*SPI\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*UART\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*GPS\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*GPS\_DPO\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\];/i)
			{
				$usbValue =   $10 . $11;
				$spiValue =   $13 . $14;
				$uartValue =  $16 . $17;
				$gpsValue =   $19 . $20;
				$gpsDOValue = $22 . $23;
				
				$peripheralsValue = $usbValue;
				my @tempArr = ( $spiValue, $uartValue, $gpsValue, $gpsDOValue );
				foreach(@tempArr)
				{
					if($_ > $peripheralsValue)
					{
						$peripheralsValue = $_;
					}
				}
			}
			# For Pre-Innsbruck
			elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Peripherals\]\s*GPS\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*USB\=\[\d+(\.\d+)?,(\d+)(\.\d+)?\%\]\;\s*SPI\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;\s*UART\=\[\d+(\.\d+)?\,(\d+)(\.\d+)?\%\]\;/i)
			{
				$gpsValue =   $9 . $10;
				$usbValue =   $12 . $13;
				$spiValue =   $15 . $16;
				$uartValue =  $18 . $19;
				
				$peripheralsValue = $usbValue;
				my @tempArr = ( $spiValue, $uartValue, $gpsValue );
				foreach(@tempArr)
				{
					if($_ > $peripheralsValue)
					{
						$peripheralsValue = $_;
					}
				}
			}
			
			$peripheralsValue = sprintf("%.0f", $peripheralsValue);
			$peripheralsValue = floor($peripheralsValue);
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "ARMUtility=" . $currentARMUtilityValue . ";ARMUtilityDuration=" . $ARMUtilityDurationTracking . ";APPSValue=" . $currentAPPSXOShutdownValue . ";PERIPHERALSValue=" . $peripheralsValue, "YES");
			
			$currentAPPSXOShutdownValue = -9999;
			$currentARMUtilityValue = -9999;
		}
		elsif(($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW MPSS\]\s*CXO_Shutdown\=\[(\d+)\.(\d+)\%\,(\d+)\]\;/i) |
			($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Processor\]\s*System_State\=\[(\d+)(\.\d+)?\,/i))
		{
			my $mpssUtilityValue = -9999;
			
			# For Post-Innsbruck
			if($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW MPSS\]\s*CXO_Shutdown\=\[(\d+)\.(\d+)\%\,(\d+)\]\;/i)
			{
				my $xoShutdownValue = $8 . "." . $9;
				$mpssUtilityValue = sprintf ($roundingFactor, 100 - $xoShutdownValue);
			}
			# For Pre-Innsbruck
			elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*\[BB HW Processor\]\s*System_State\=\[(\d+)(\.\d+)?\,/i)
			{
				#my $tempValue = $8 . $9;
				#$armUtilityValue = sprintf ($roundingFactor, 100 - $tempValue);
			}
			
			$mpssUtilityValue = sprintf("%.0f", $mpssUtilityValue);
			$mpssUtilityValue = floor($mpssUtilityValue);
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "MPSSUtility=" . $mpssUtilityValue . ";MPSSUtilityDuration=" . $ARMUtilityDurationTracking, "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Battery\]\s*level\=(\d+)\.(\d+)%/i)
		{
			my $batteryValue = $8 . "." . $9;
			$batteryValue = sprintf ("%0.2f", $batteryValue);
			
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "BatteryStatus=" . $batteryValue, "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Display\]\s*.*active\=yes\;/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "DisplayStatus=Active", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Display\]\s*.*active\=no\;/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "DisplayStatus=Inactive", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Telephony\]\s*.*call_status\=Inactive/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "VoiceCallStatus=Inactive", "YES");
		}
		elsif(($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Telephony\]\s*.*call_status\=Active/i) |
				($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Telephony\]\s*.*call_status\=Sending/i) |
				($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Telephony\]\s*.*call_status\=Ringing/i))
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "VoiceCallStatus=Active", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Sleep\]\s*event\=did_sleep\;/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "APSleepStatus=sleep", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Wake\]\s*reason\=(.*)\;/i)
		{
			my $reason = $8;
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "APSleepStatus=awake;reason=" . $reason, "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[BB Event\]\s*EventCode\=EVENT_WCDMA_RRC_STATE\;\s*prevState\=(.*);\s*currState\=(.*)\s*rate/i)
		{
			my $currentBBWCDMAConnectedState = "YES";
			if(defined($9))
			{
				if($9 =~ m/Disconnected/i)
				{
					$currentBBWCDMAConnectedState = "NO";
				}
			}
			
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "WcdmaConnectedState=" . $currentBBWCDMAConnectedState, "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Assertion\]\s*.*state\=created\;\s*process\=mediaserverd\;.*name\=com.apple.audio.VAD Aggregate Device UID/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "audioAssertionHeld=YES", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Assertion\]\s*.*state\=released\;\s*process\=mediaserverd\;.*name\=com.apple.audio.VAD Aggregate Device UID/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "audioAssertionHeld=NO", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Assertion\]\s*.*state\=(created|held)\;\s*process\=wifid\;.*name\=ap1/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "PersonalWiFiHotspot=YES", "YES");
		}
		elsif($line =~ m/(\d+)\/(\d+)\/(\d+)\s*(\d+)\:(\d+)\:(\d+)(\.\d+)?\s*.*\[Assertion\]\s*.*state\=released\;\s*process\=wifid\;.*name\=ap1/i)
		{
			addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "PersonalWiFiHotspot=NO", "YES");
		}
	}
	addHTValue(\%ht_ForValuesOfCurrentLogFile, $currentEpochTime, "LOG_END_TIME", "YES");
	
	#printTheHT(\%ht_ForValuesOfCurrentLogFile);
	#====================================================
	# **** Calculate ARM Utility and BDPH Bin Values ****
	#====================================================
	calculateARMUtilityAndBDPHAndPrintToFile(\%ht_ForValuesOfCurrentLogFile, \%ht_Current_Log_KPIs, $CSV_RESULT_ARM_UTILITY_VALUES, $CSV_RESULT_MPSS_UTILITY_VALUES, $CSV_RESULT_BatteryLevel_VALUES, $CSV_RESULT_KPIS,
							$CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD, $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD, $P3_Threshold_Min);
	
	#========================================================
	# **** Add the curent log KPI values into cumulative ****
	#========================================================
	foreach(@HeaderIndices)
	{
		$ht_Cumulative_KPIs{$_} = $ht_Cumulative_KPIs{$_} + $ht_Current_Log_KPIs{$_};
		if($DEBUG_MODE == 1){
		print "$_ >> $ht_Current_Log_KPIs{$_} \n"; }
	}
	# Print Current Log KPIs to Result File
	printKPIsToFile($CSV_RESULT_KPIS, $file, \@HeaderIndices, \%ht_Current_Log_KPIs);
	
	print $CSV_RESULT_ARM_UTILITY_VALUES "ENDOFFILE\n";
	print $CSV_RESULT_MPSS_UTILITY_VALUES "ENDOFFILE\n";
	print $CSV_RESULT_BatteryLevel_VALUES "ENDOFFILE\n";
	print $CSV_RESULT_ARM_UTILITY_VALUES "\n\n";
	print $CSV_RESULT_MPSS_UTILITY_VALUES "\n\n";
	print $CSV_RESULT_BatteryLevel_VALUES "\n\n";
}

# Print Cumulative KPIs to Result File
printKPIsToFile($CSV_RESULT_KPIS, "Cumulative", \@HeaderIndices, \%ht_Cumulative_KPIs);

close $CSV_RESULT_ARM_UTILITY_VALUES;
close $CSV_RESULT_MPSS_UTILITY_VALUES;
close $CSV_RESULT_BatteryLevel_VALUES;
close $CSV_RESULT_KPIS;
close $CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD;
close $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD;

#========================================================
# **** PDF/CDF Variables ****
#========================================================
my $idx_For_ht_PDF = 0;

# Define Cumulative PDF Files
my %ht_Cumulative_ARMUtility_PDF   				= ();		$ht_Cumulative_ARMUtility_PDF{File_Name} 			= "Cumulative";
my %ht_Cumulative_ARMUtility_Filtered_PDF   	= ();		$ht_Cumulative_ARMUtility_Filtered_PDF{File_Name} 	= "Cumulative";
my %ht_Cumulative_MPSSUtility_PDF   			= ();		$ht_Cumulative_MPSSUtility_PDF{File_Name} 			= "Cumulative";
my %ht_Cumulative_MPSSUtility_Filtered_PDF   	= ();		$ht_Cumulative_MPSSUtility_Filtered_PDF{File_Name} 	= "Cumulative";
my %ht_Cumulative_BDPH_PDF   					= ();		$ht_Cumulative_BDPH_PDF{File_Name} 					= "Cumulative";
my %ht_Cumulative_BDPH_Filtered_PDF   			= ();		$ht_Cumulative_BDPH_Filtered_PDF{File_Name} 		= "Cumulative";

# Define HT to hold Refs of HTs
my %ht_ARMUtility_PDF_HashTables 				= ();		#  HT To Hold Refs to all ARM Utility Hash Tables
my %ht_ARMUtility_Filtered_PDF_HashTables 		= ();		#  HT To Hold Refs to all ARM Utility Hash Tables
my %ht_MPSSUtility_PDF_HashTables 				= ();		#  HT To Hold Refs to all MPSS Utility Hash Tables
my %ht_MPSSUtility_Filtered_PDF_HashTables 		= ();		#  HT To Hold Refs to all MPSS Utility Hash Tables
my %ht_BDPH_PDF_HashTables 						= ();		#  HT To Hold Refs to all BDPH Hash Tables
my %ht_BDPH_Filtered_PDF_HashTables 			= ();		#  HT To Hold Refs to all BDPH Hash Tables

# Assign the ref for cumulative HT
$ht_ARMUtility_PDF_HashTables{$idx_For_ht_PDF} 				= \%ht_Cumulative_ARMUtility_PDF;
$ht_ARMUtility_Filtered_PDF_HashTables{$idx_For_ht_PDF} 	= \%ht_Cumulative_ARMUtility_Filtered_PDF;
$ht_MPSSUtility_PDF_HashTables{$idx_For_ht_PDF} 			= \%ht_Cumulative_MPSSUtility_PDF;
$ht_MPSSUtility_Filtered_PDF_HashTables{$idx_For_ht_PDF} 	= \%ht_Cumulative_MPSSUtility_Filtered_PDF;
$ht_BDPH_PDF_HashTables{$idx_For_ht_PDF} 					= \%ht_Cumulative_BDPH_PDF;
$ht_BDPH_Filtered_PDF_HashTables{$idx_For_ht_PDF} 			= \%ht_Cumulative_BDPH_Filtered_PDF;

$idx_For_ht_PDF++;

my $ref_ht_Current_Log_ARMUtility_PDF;
my $ref_ht_Current_Log_ARMUtility_wNoUserActivity_PDF;
my $ref_ht_Current_Log_MPSSUtility_PDF;
my $ref_ht_Current_Log_MPSSUtility_wNoUserActivity_PDF;
my $ref_ht_Current_Log_BDPH_PDF;
my $ref_ht_Current_Log_BDPH_Filtered_PDF;

#========================================================
# Min, Max and Step Sizes
#========================================================
my $minBin_ARMUtility = 0;
my $maxBin_ARMUtility = 100;
my $stepSize_ARMUtility = 1;

my $minBin_ARMUtility_Filtered = 0;
my $maxBin_ARMUtility_Filtered = 100;
my $stepSize_ARMUtility_Filtered = 1;

my $minBin_MPSSUtility = 0;
my $maxBin_MPSSUtility = 100;
my $stepSize_MPSSUtility = 1;

my $minBin_MPSSUtility_Filtered = 0;
my $maxBin_MPSSUtility_Filtered = 100;
my $stepSize_MPSSUtility_Filtered = 1;


my $minBin_BDPH = 0;
my $maxBin_BDPH = 20;
my $stepSize_BDPH = 0.5;

my $minBin_BDPH_Filtered = 0;
my $maxBin_BDPH_Filtered = 20;
my $stepSize_BDPH_Filtered = 0.5;

#========================================================
# **** Get PDF Distribution bins for ARM Activity ****
#========================================================
if($DEBUG_MODE == 1) { print "Get HT Bins for ARM Utility \n"; }
fillHTBinsFromFilePerLog($armUtilityValuesFile, "4", $minBin_ARMUtility, $maxBin_ARMUtility, $stepSize_ARMUtility, $roundingFactor, 
						 \%ht_Cumulative_ARMUtility_PDF, \%ht_ARMUtility_PDF_HashTables, $idx_For_ht_PDF);
if($DEBUG_MODE == 1) { print "Get HT Bins for ARM Utility Filtered \n"; }
fillHTBinsFromFilePerLog($armUtilityValuesFile, "5", $minBin_ARMUtility_Filtered, $maxBin_ARMUtility_Filtered, $stepSize_ARMUtility_Filtered, $roundingFactor, 
						 \%ht_Cumulative_ARMUtility_Filtered_PDF, \%ht_ARMUtility_Filtered_PDF_HashTables, $idx_For_ht_PDF);

#========================================================
# **** Get PDF Distribution bins for MPSS Activity ****
#========================================================
if($DEBUG_MODE == 1) { print "Get HT Bins for MPSS Utility \n"; }
fillHTBinsFromFilePerLog($mpssUtilityValuesFile, "4", $minBin_MPSSUtility, $maxBin_MPSSUtility, $stepSize_MPSSUtility, $roundingFactor, 
						 \%ht_Cumulative_MPSSUtility_PDF, \%ht_MPSSUtility_PDF_HashTables, $idx_For_ht_PDF);
if($DEBUG_MODE == 1) { print "Get HT Bins for MPSS Utility Filtered \n"; }
fillHTBinsFromFilePerLog($mpssUtilityValuesFile, "5", $minBin_MPSSUtility_Filtered, $maxBin_MPSSUtility_Filtered, $stepSize_MPSSUtility_Filtered, $roundingFactor, 
						 \%ht_Cumulative_MPSSUtility_Filtered_PDF, \%ht_MPSSUtility_Filtered_PDF_HashTables, $idx_For_ht_PDF);

#========================================================
# **** Get PDF Distribution bins for BDPH ****
#========================================================
if($DEBUG_MODE == 1) { print "Get HT Bins for BDPH \n"; }
fillHTBinsFromFilePerLog($BatteryLevelValuesFile, "5", $minBin_BDPH, $maxBin_BDPH, $stepSize_BDPH, $roundingFactor, 
						 \%ht_Cumulative_BDPH_PDF, \%ht_BDPH_PDF_HashTables, $idx_For_ht_PDF);
if($DEBUG_MODE == 1) { print "Get HT Bins for BDPH Filtered \n"; }
fillHTBinsFromFilePerLog($BatteryLevelValuesFile, "6", $minBin_BDPH_Filtered, $maxBin_BDPH_Filtered, $stepSize_BDPH_Filtered, $roundingFactor, 
						 \%ht_Cumulative_BDPH_Filtered_PDF, \%ht_BDPH_Filtered_PDF_HashTables, $idx_For_ht_PDF);


#============================================================
# **** Print the CDF and PDF for all Logs and Cumulative ****
#============================================================
if($minBin_ARMUtility_Filtered <= $maxBin_ARMUtility_Filtered)
{
	printPDFCDFHeader($CSV_RESULT_PDF_CDF, "ARM Utility Filtered PDF", "FileName", $minBin_ARMUtility_Filtered, $maxBin_ARMUtility_Filtered, $stepSize_ARMUtility_Filtered);
	printPDF($CSV_RESULT_PDF_CDF, \%ht_ARMUtility_Filtered_PDF_HashTables, $minBin_ARMUtility_Filtered, $maxBin_ARMUtility_Filtered, $stepSize_ARMUtility_Filtered, "ARM Utility Filtered PDF");
}

if($minBin_ARMUtility <= $maxBin_ARMUtility)
{
	printPDFCDFHeader($CSV_RESULT_PDF_CDF, "ARM Utility PDF", "FileName", $minBin_ARMUtility, $maxBin_ARMUtility, $stepSize_ARMUtility);
	printPDF($CSV_RESULT_PDF_CDF, \%ht_ARMUtility_PDF_HashTables, $minBin_ARMUtility, $maxBin_ARMUtility, $stepSize_ARMUtility, "ARM Utility PDF");
}

if($minBin_MPSSUtility_Filtered <= $maxBin_MPSSUtility_Filtered)
{
	printPDFCDFHeader($CSV_RESULT_PDF_CDF, "MPSS Utility Filtered PDF", "FileName", $minBin_MPSSUtility_Filtered, $maxBin_MPSSUtility_Filtered, $stepSize_MPSSUtility_Filtered);
	printPDF($CSV_RESULT_PDF_CDF, \%ht_MPSSUtility_Filtered_PDF_HashTables, $minBin_MPSSUtility_Filtered, $maxBin_MPSSUtility_Filtered, $stepSize_MPSSUtility_Filtered, "MPSS Utility Filtered PDF");
}

if($minBin_MPSSUtility <= $maxBin_MPSSUtility)
{
	printPDFCDFHeader($CSV_RESULT_PDF_CDF, "MPSS Utility PDF", "FileName", $minBin_MPSSUtility, $maxBin_MPSSUtility, $stepSize_MPSSUtility);
	printPDF($CSV_RESULT_PDF_CDF, \%ht_MPSSUtility_PDF_HashTables, $minBin_MPSSUtility, $maxBin_MPSSUtility, $stepSize_MPSSUtility, "MPSS Utility PDF");
}

if($minBin_BDPH_Filtered <= $maxBin_BDPH_Filtered)
{
	printPDFCDFHeader($CSV_RESULT_PDF_CDF, "BDPH Filtered PDF", "FileName", $minBin_BDPH_Filtered, $maxBin_BDPH_Filtered, $stepSize_BDPH_Filtered);
	printPDF($CSV_RESULT_PDF_CDF, \%ht_BDPH_Filtered_PDF_HashTables, $minBin_BDPH_Filtered, $maxBin_BDPH_Filtered, $stepSize_BDPH_Filtered, "BDPH Filtered PDF");
}

if($minBin_BDPH <= $maxBin_BDPH)
{
	printPDFCDFHeader($CSV_RESULT_PDF_CDF, "BDPH PDF", "FileName", $minBin_BDPH, $maxBin_BDPH, $stepSize_BDPH);
	printPDF($CSV_RESULT_PDF_CDF, \%ht_BDPH_PDF_HashTables, $minBin_BDPH, $maxBin_BDPH, $stepSize_BDPH, "BDPH PDF");
}

close $CSV_RESULT_PDF_CDF;

#============================================================================
# PRINT THE CRITERIA RESULT AT THE END OF PROCESSING
#============================================================================
print "============================================================================\n";
my $criteriaMet = "YES";
$criteriaResult = "";

my $criteriaResultForARMUtility   = "ARM Activity: Criteria Met";
my $criteriaResultForBatteryDrain = "BDPH : Criteria Met";
if($scriptMode =~ m/FocusedTestMode/i)
{
	print "Calculating Result for Mode : Focused Test Mode\n";
	
	my ($currARMCriteriaMet, $currARMCriteriaResult) = 
					getCriteriaMetOrNotResult(\%ht_ARMUtility_PDF_HashTables, $minBin_ARMUtility, $maxBin_ARMUtility, $stepSize_ARMUtility, $roundingFactor, $ARM_Activity_Max_PDF_Bucket);
	$criteriaResultForARMUtility = "ARM Activity: " . $currARMCriteriaResult;
	
	my ($currBDPHCriteriaMet, $currBDPHCriteriaResult) = 
					getCriteriaMetOrNotResult(\%ht_BDPH_PDF_HashTables, $minBin_BDPH, $maxBin_BDPH, $stepSize_BDPH, $roundingFactor, $Battery_Drain_Max_PDF_Bucket);
	$criteriaResultForBatteryDrain = "BDPH: " . $currBDPHCriteriaMet;
	
	if(($currARMCriteriaMet =~ m/NO/i) | ($criteriaResultForBatteryDrain =~ m/NO/i))
	{
		$criteriaMet = "NO";
	}
	
	if($criteriaMet eq "YES")
	{
		$criteriaResult = $criteriaResultForARMUtility . "; " . $criteriaResultForBatteryDrain . "; Don't file any radar";
	}
	else
	{
		$criteriaResult = $criteriaResultForARMUtility . "; " . $criteriaResultForBatteryDrain . "; File radar with BB n Power Logs" ;
	}
}
elsif($scriptMode =~ m/EndUserMode/i)
{	
	print "Calculating Result for Mode : End User Mode\n";
	
	#useThresholds
	my ($currARMCriteriaMet, $Priority) = ("NOT CALCULATED", "NONE");
	
	#if($useThresholds =~ m/BBON/i)
	#{
	#	($currARMCriteriaMet, $Priority) = getCriteriaMetOrNotResultNew(\%ht_MPSSUtility_Filtered_PDF_HashTables, $minBin_MPSSUtility_Filtered, $maxBin_MPSSUtility_Filtered, $stepSize_MPSSUtility_Filtered, $roundingFactor,
	#						$P1_Threshold, $P2_Threshold_Min, $P2_Threshold_Max, $P3_Threshold_Min, $P3_Threshold_Max, $CDFPercentToLookFor);
	#}  # Removed as ARM will be used from now on v3.3
	
	#if($useThresholds =~ m/BBOFF/i)
	#{
		($currARMCriteriaMet, $Priority) = getCriteriaMetOrNotResultNew(\%ht_ARMUtility_Filtered_PDF_HashTables, $minBin_ARMUtility_Filtered, $maxBin_ARMUtility_Filtered, $stepSize_ARMUtility_Filtered, $roundingFactor, 
							$P1_Threshold, $P2_Threshold_Min, $P2_Threshold_Max, $P3_Threshold_Min, $P3_Threshold_Max, $CDFPercentToLookFor);
	#}
	
	$criteriaMet = $currARMCriteriaMet;
	
	if($criteriaMet eq "YES")
	{
		$criteriaResult = "No Issue Found, Don't file any radar";
	}
	else
	{
		$criteriaResult = "Found issue, Please file radar with logs; Priority=" . $Priority . "; Keyword=BBPower";
	}
}

print "============================================================================\n";
print "CRITERIA RESULT: $criteriaResult \n";
print "============================================================================\n\n";

print "*********End of Processing************\n";
#============================================================================
#==================== END OF MAIN ===========================================
#============================================================================
#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Get Criteria Met/Not Result
#================================================================
sub getCriteriaMetOrNotResultNew{
	my ($ref_PDF_HT, $minBin, $maxBin, $stepSize, $roundingFactor, 
				$P1_Threshold, $P2_Threshold_Min, $P2_Threshold_Max, $P3_Threshold_Min, $P3_Threshold_Max, $CDFPercentToLookFor) = @_;
	
	my $criteriaMet = "YES";
	my $priority = "NONE";
	my $valueAtWhichWeHitCDFValue = -999;
	
	for my $key1 ( sort {$b<=>$a} keys %$ref_PDF_HT ) 
	{
		if($$ref_PDF_HT{$key1}{File_Name} =~ m/Cumulative/i)
		{
			my $totalCount = 0;
			
			# Get the Total count
			for(my $k = $minBin; $k <= $maxBin; $k = $k + $stepSize)
			{
				$k = sprintf($roundingFactor, $k);
				if(defined($$ref_PDF_HT{$key1}{$k}))
				{
					$totalCount = $totalCount + $$ref_PDF_HT{$key1}{$k};
				}
			}
			print "Total Count = $totalCount \n";
			
			my $cumulativeCount = 0;
			for(my $k = $minBin; $k <= $maxBin; $k = $k + $stepSize)
			{
				$k = sprintf($roundingFactor, $k);
				if(defined($$ref_PDF_HT{$key1}{$k}))
				{
					$cumulativeCount = $cumulativeCount + $$ref_PDF_HT{$key1}{$k};
				}
				
				my $cdfPercent = 0;
				if($totalCount > 0)
				{
					$cdfPercent = sprintf("%0.2f", ($cumulativeCount / $totalCount) * 100);
				}
				print "Value = $k >> CDF %age = $cdfPercent \n";
				
				if($valueAtWhichWeHitCDFValue < 0)
				{
					if($cdfPercent >= $CDFPercentToLookFor)
					{
						$valueAtWhichWeHitCDFValue = $k;
						print "Value at which CDF Percent of $CDFPercentToLookFor was hit = $k \n";
					}
				}
				
				if($k >= 100)
				{
					if(defined($$ref_PDF_HT{$key1}{$k}))
					{
						print "P1 Bin Value = $k >> Count = $$ref_PDF_HT{$key1}{$k} ; Total Count = $totalCount\n";
						if($$ref_PDF_HT{$key1}{$k} > 0)
						{
							$criteriaMet = "NO";
							$priority = "P1";
							last;
						}
					}
				}
			}
			last;
		}
	}
	
	if($priority ne "P1")
	{
		if($valueAtWhichWeHitCDFValue >= $P1_Threshold)
		{
			$priority = "P1";
			$criteriaMet = "NO";
		}
		elsif($valueAtWhichWeHitCDFValue >= $P2_Threshold_Min && $valueAtWhichWeHitCDFValue < $P2_Threshold_Max)
		{
			$priority = "P2";
			$criteriaMet = "NO";
		}
		elsif($valueAtWhichWeHitCDFValue > $P3_Threshold_Min && $valueAtWhichWeHitCDFValue < $P3_Threshold_Max)
		{
			$priority = "P3";
			$criteriaMet = "NO";
		}
	}
	
	return($criteriaMet, $priority);
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Get Criteria Met/Not Result
#================================================================
sub getCriteriaMetOrNotResult{
	my ($ref_PDF_HT, $minBin, $maxBin, $stepSize, $roundingFactor, $criteriaPDFBucket) = @_;
	
	my $criteriaMet = "YES";
	my $criteriaResult = "Criteria Met";
	
	for my $key1 ( sort {$b<=>$a} keys %$ref_PDF_HT ) 
	{
		if($$ref_PDF_HT{$key1}{File_Name} =~ m/Cumulative/i)
		{
			for(my $k = $maxBin; $k >= $minBin; $k = $k - $stepSize)
			{
				$k = sprintf($roundingFactor, $k);
				if($k > $criteriaPDFBucket)
				{
					if(defined($$ref_PDF_HT{$key1}{$k}))
					{
						print "Bin Value = $k >> $$ref_PDF_HT{$key1}{$k} \n";
						if($$ref_PDF_HT{$key1}{$k} > 0)
						{
							$criteriaResult = "Criteria NOT Met";
							$criteriaMet = "NO";
							last;
						}
					}
				}
			}
			last;
		}
	}
	
	return($criteriaMet, $criteriaResult);
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Get User Activity Status
#================================================================
sub fillHTBinsFromFilePerLog{
	my($inputFileName, $valuePosition, $minBin, $maxBin, $stepSize, $roundingFactor, $ref_ForCumulativeHT, $ref_For_Overall_PDF_HT, $idx_For_ht_PDF ) = @_;
	
	my $ref_ForNewHT;
	open (my $CSV, "<$inputFileName");

	my $line = <$CSV>;  # Read the Header
	while($line = <$CSV>)
	{
		my @values = split('\,', $line);
		#print "$line \n";
		
		$values[0] =~ s/^\s+//;
		$values[0] =~ s/\s+$//;
		if($line =~ m/ENDOFFILE/i)
		{
			$$ref_For_Overall_PDF_HT{$idx_For_ht_PDF} = $ref_ForNewHT;
			$idx_For_ht_PDF++;
		}	
		elsif(length($values[0]) > 0)
		{
			# Create New HT and assign File Name and Zero-out the values
			($ref_ForNewHT) = createNewHT();
			$$ref_ForNewHT{File_Name} = $values[0];
			
			fillTheHTWithZeroes($ref_ForNewHT, $minBin, $maxBin, $stepSize, $roundingFactor);
		}
		
		if(@values >= $valuePosition + 1)
		{
			if(length($values[$valuePosition]) > 0)
			{
				$values[$valuePosition] =~ s/^\s+//;
				$values[$valuePosition] =~ s/\s+$//;
	
				if($values[$valuePosition] !~ m/NA/i)
				{
					my $bin = sprintf ("%.0f", $values[$valuePosition] / $stepSize);
					$bin = sprintf ($roundingFactor, $minBin + ($stepSize * $bin));
					
					if($bin >$maxBin)
					{
						if($DEBUG_MODE == 1){
							print "Current Bin: $bin changed to $maxBin for Value $values[$valuePosition]\n"; }
						$bin = sprintf ($roundingFactor, $maxBin);  # Put any values that are more than Max Bin in Max bin
					}
					
					$$ref_ForNewHT{$bin}++;
					$$ref_ForCumulativeHT{$bin}++;
					
					if($DEBUG_MODE == 1){
						print "Bin: $bin >> $$ref_ForNewHT{$bin} for Value: $values[$valuePosition]\n"; }
				}
			}
		}
	}
	close $CSV;
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Get User Activity Status
#================================================================
sub calculateARMUtilityAndBDPHAndPrintToFile{
	my($ref_ht, $ref_ht_KPIs, $CSV_RESULT_ARM_UTILITY_VALUES, $CSV_RESULT_MPSS_UTILITY_VALUES, $CSV_RESULT_BatteryLevel_VALUES, $CSV_RESULT_KPIS,
				$CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD, $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD, $P3_Threshold_Min) = @_;
	
	my %ht = %$ref_ht;
	#my %ht_KPIs = %$ref_ht_KPIs;
	
	my $userActivityStatus = "";
	
	# ARM Activity Variables
	my $normalizedARMActivityValueForNormalCase = 0;
	my $normalizedARMActivityValueForFilteredCase = 0;
	my $elapsedDurationForARMActivityForNormalCase = 0;
	my $elapsedDurationForARMActivityForFilteredCase = 0;
	my $isFirstValueOfARMActivityForNormalCase = "NO";
	my $isFirstValueOfARMActivityForFilteredCase = "NO";
	my $isConsecutiveARMUtilityValueAboveThreshold = "NO";
	
	# MPSS Activity Variables
	my $normalizedMPSSActivityValueForNormalCase = 0;
	my $normalizedMPSSActivityValueForFilteredCase = 0;
	my $elapsedDurationForMPSSActivityForNormalCase = 0;
	my $elapsedDurationForMPSSActivityForFilteredCase = 0;
	my $isFirstValueOfMPSSActivityForNormalCase = "NO";
	my $isFirstValueOfMPSSActivityForFilteredCase = "NO";
	my $isConsecutiveMPSSUtilityValueAboveThreshold = "NO";
	
	# BDPH Variables
	my $startBatteryValueForNormalBDPHCase = -999;
	my $startBatteryValueForFilteredBDPHCase = -999;
	my $startTimeForBDPHForNormalCase = -999;
	my $startTimeForBDPHForFilteredCase = -999;
	my $previousBatteryLevel = -999;
	my $previousBatteryTimestamp = -999;
	
	my %ht_ToStoreIncludeExcludeList = ();
	$ht_ToStoreIncludeExcludeList{"DISPLAY_IS_ON"} = "DONT_KNOW";
	$ht_ToStoreIncludeExcludeList{"VOICE_CALL_IS_UP"} = "DONT_KNOW";
	$ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} = "DONT_KNOW";  # Not being Used
	$ht_ToStoreIncludeExcludeList{"IS_AUDIO_ASSERTION_HELD"} = "DONT_KNOW";
	$ht_ToStoreIncludeExcludeList{"IS_PERSONAL_WIFI_HOTSPOT_ASSERTION_HELD"} = "DONT_KNOW";
	
	my %ht_ToStoreStatusesAndTimeStamps = ();
	$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"} 					= "DONT_KNOW";
	$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"} 	= "DONT_KNOW";
	$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW"} 	= "DONT_KNOW";
	$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS"} 		= "DONT_KNOW";
	$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON"} 			= "DONT_KNOW";
	
	$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE--StartTimeStamp"} 					= -999;
	$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS--StartTimeStamp"} 	= -999;
	$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW--StartTimeStamp"} 	= -999;
	$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS--StartTimeStamp"} 		= -999;
	$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON--StartTimeStamp"} 			= -999;

	for my $key1 ( sort {$a<=>$b} keys %ht ) 
	{
		if($DEBUG_MODE == 1){
		print "Timestamp: $key1 >> $ht{$key1} \n"; }
		
		my $standardDateTime = scalar(localtime($key1));
		if($key1 =~ m/(\d+).(\d+)/i)
		{
			$standardDateTime = $standardDateTime . " (" . $2 . "msec)";
		}
		
		#=========================
		# Get User Active Status
		#=========================
		$userActivityStatus = getUserActivityStatus(\%ht_ToStoreIncludeExcludeList);
		if($userActivityStatus =~ m/USERActive/)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "DurationOfUserUsingTheDevice", "DurationOfUserNotUsingTheDevice");
			$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW"}  = "YES";
			
			# RESET the Values for ARM Activity and BDPH
			$normalizedARMActivityValueForFilteredCase = 0;
			$elapsedDurationForARMActivityForFilteredCase = 0;
			$isFirstValueOfARMActivityForFilteredCase = "YES";
			
			$normalizedMPSSActivityValueForFilteredCase = 0;
			$elapsedDurationForMPSSActivityForFilteredCase = 0;
			$isFirstValueOfMPSSActivityForFilteredCase = "YES";
			
			$startBatteryValueForFilteredBDPHCase = -999;
			$startTimeForBDPHForFilteredCase = -999;
		}
		else
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "DurationOfUserUsingTheDevice", "DurationOfUserNotUsingTheDevice");
			$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW"}  = "NO";
		}
		
		#===========================================
		# Deciders for User using the device or not
		#===========================================
		#if($ht{$key1} =~ m/BATTERY_CHARGING_ACTIVE/i)
		#{
		#	if($ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} !~ m/YES/i)
		#	{
		#		print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, BATTERY_CHARGING_ACTIVE\n";
		#		print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, BATTERY_CHARGING_ACTIVE\n";
		#		print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, BATTERY_CHARGING_ACTIVE\n";
		#	}
		#	$ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} = "YES";
		#	
		#	# RESET the Values for ARM Activity
		#	$isFirstValueOfARMActivityForNormalCase = "YES";
		#	$normalizedARMActivityValueForNormalCase = 0;
		#	$elapsedDurationForARMActivityForNormalCase = 0;
		#	
		#	$isFirstValueOfMPSSActivityForNormalCase = "YES";
		#	$normalizedMPSSActivityValueForNormalCase = 0;
		#	$elapsedDurationForMPSSActivityForNormalCase = 0;
		#	
		#	$startBatteryValueForNormalBDPHCase = -999;
		#	$startTimeForBDPHForNormalCase = -999;
		#}
		#elsif($ht{$key1} =~ m/BATTERY_CHARGING_INACTIVE/i)
		#{
		#	if($ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} !~ m/NO/i)
		#	{
		#		print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, BATTERY_CHARGING_INACTIVE\n";
		#		print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, BATTERY_CHARGING_INACTIVE\n";
		#		print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, BATTERY_CHARGING_INACTIVE\n";
		#	}
		#	$ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} = "NO";
		#}
		if($ht{$key1} =~ m/DisplayStatus\=Active/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "DisplayOnDuration", "DisplayOffDuration", "DisplayUnknownDuration");
			$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON"}  = "YES";

			if($ht_ToStoreIncludeExcludeList{"DISPLAY_IS_ON"} !~ m/YES/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, DISPLAY_IS_ON\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, DISPLAY_IS_ON\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, DISPLAY_IS_ON\n";
			}
			$ht_ToStoreIncludeExcludeList{"DISPLAY_IS_ON"} = "YES";
		}
		elsif($ht{$key1} =~ m/DisplayStatus\=Inactive/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "DisplayOnDuration", "DisplayOffDuration", "DisplayUnknownDuration");
			$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON"}  = "NO";
			
			if($ht_ToStoreIncludeExcludeList{"DISPLAY_IS_ON"} !~ m/NO/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, DISPLAY_IS_OFF\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, DISPLAY_IS_OFF\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, DISPLAY_IS_OFF\n";
			}
			$ht_ToStoreIncludeExcludeList{"DISPLAY_IS_ON"} = "NO";
		}
		elsif($ht{$key1} =~ m/VoiceCallStatus\=Active/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS"}, \$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "WCDMAVoiceCallDuration");
			$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS"} = "YES";
			
			if($ht_ToStoreIncludeExcludeList{"VOICE_CALL_IS_UP"} !~ m/YES/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, VOICE_CALL_IS_ACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, VOICE_CALL_IS_ACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, VOICE_CALL_IS_ACTIVE\n";
			}
			$ht_ToStoreIncludeExcludeList{"VOICE_CALL_IS_UP"} = "YES";
		}
		elsif($ht{$key1} =~ m/VoiceCallStatus\=Inactive/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS"}, \$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "WCDMAVoiceCallDuration");
			$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS"} = "NO";
			
			if($ht_ToStoreIncludeExcludeList{"VOICE_CALL_IS_UP"} !~ m/NO/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, VOICE_CALL_IS_INACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, VOICE_CALL_IS_INACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, VOICE_CALL_IS_INACTIVE\n";
			}
			$ht_ToStoreIncludeExcludeList{"VOICE_CALL_IS_UP"} = "NO";
		}
		elsif($ht{$key1} =~ m/audioAssertionHeld\=YES/i)
		{
			if($ht_ToStoreIncludeExcludeList{"IS_AUDIO_ASSERTION_HELD"} !~ m/YES/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, AUDIO_IS_ACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, AUDIO_IS_ACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, AUDIO_IS_ACTIVE\n";
			}
			$ht_ToStoreIncludeExcludeList{"IS_AUDIO_ASSERTION_HELD"} = "YES";
		}
		elsif($ht{$key1} =~ m/audioAssertionHeld\=NO/i)
		{
			if($ht_ToStoreIncludeExcludeList{"IS_AUDIO_ASSERTION_HELD"} !~ m/NO/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, AUDIO_IS_INACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, AUDIO_IS_INACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, AUDIO_IS_INACTIVE\n";
			}
			$ht_ToStoreIncludeExcludeList{"IS_AUDIO_ASSERTION_HELD"} = "NO";
		}
		elsif($ht{$key1} =~ m/PersonalWiFiHotspot\=YES/i)
		{
			if($ht_ToStoreIncludeExcludeList{"IS_PERSONAL_WIFI_HOTSPOT_ASSERTION_HELD"} !~ m/YES/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, WIFI_HOTSPOT_IS_ACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, WIFI_HOTSPOT_IS_ACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, WIFI_HOTSPOT_IS_ACTIVE\n";
			}
			$ht_ToStoreIncludeExcludeList{"IS_PERSONAL_WIFI_HOTSPOT_ASSERTION_HELD"} = "YES";
		}
		elsif($ht{$key1} =~ m/PersonalWiFiHotspot\=NO/i)
		{
			if($ht_ToStoreIncludeExcludeList{"IS_PERSONAL_WIFI_HOTSPOT_ASSERTION_HELD"} !~ m/NO/i)
			{
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, WIFI_HOTSPOT_IS_INACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, WIFI_HOTSPOT_IS_INACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, WIFI_HOTSPOT_IS_INACTIVE\n";
			}
			$ht_ToStoreIncludeExcludeList{"IS_PERSONAL_WIFI_HOTSPOT_ASSERTION_HELD"} = "NO";
		}
		
		#====================================
		# Used for Duration Calculation Only
		#====================================
		elsif($ht{$key1} =~ m/APSleepStatus\=awake;reason\=(.*)/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "APAwakeDuration", "APSleepDuration", "APUnknownDuration");

			if($ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"} !~ m/YES/i)
			{
				if($PRINT_DURATION_PRINTS == 1){
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, AP_IS_AWAKE $1\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, AP_IS_AWAKE $1\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, AP_IS_AWAKE $1\n"; }
			}
			$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"} = "YES";
		}
		elsif($ht{$key1} =~ m/APSleepStatus\=sleep/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "APAwakeDuration", "APSleepDuration", "APUnknownDuration");

			if($ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"} !~ m/NO/i)
			{
				if($PRINT_DURATION_PRINTS == 1){
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, AP_IS_SLEEP\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, AP_IS_SLEEP\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, AP_IS_SLEEP\n"; }
			}
			$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"} = "NO";
		}
		elsif($ht{$key1} =~ m/WcdmaConnectedState\=YES/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"}, \$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "BBWCDMAConnectedModeDuration", "BBWCDMANOTConnectedModeDuration", "BBWCDMAUnknownModeDuration");

			if($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"} !~ m/YES/i)
			{
				if($PRINT_DURATION_PRINTS == 1){
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, BB_WCDMA_CONNECTED_MODE_ACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, BB_WCDMA_CONNECTED_MODE_ACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, BB_WCDMA_CONNECTED_MODE_ACTIVE\n"; }
			}
			$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"} 	= "YES";
		}
		elsif($ht{$key1} =~ m/WcdmaConnectedState\=NO/i)
		{
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"}, \$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "BBWCDMAConnectedModeDuration", "BBWCDMANOTConnectedModeDuration", "BBWCDMAUnknownModeDuration");

			if($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"} !~ m/NO/i)
			{
				if($PRINT_DURATION_PRINTS == 1){
				print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, BB_WCDMA_CONNECTED_MODE_INACTIVE\n";
				print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, BB_WCDMA_CONNECTED_MODE_INACTIVE\n";
				print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, BB_WCDMA_CONNECTED_MODE_INACTIVE\n"; }
			}
			$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"} 	= "NO";
		}
		elsif($ht{$key1} =~ m/LOG_START_TIME/i)
		{
			$$ref_ht_KPIs{TotalLogDuration} = 0;
			$ht_ToStoreStatusesAndTimeStamps{"LOG--StartTimeStamp"} = $key1;
		}
		elsif($ht{$key1} =~ m/LOG_END_TIME/i)
		{
			$$ref_ht_KPIs{TotalLogDuration} = $key1 - $ht_ToStoreStatusesAndTimeStamps{"LOG--StartTimeStamp"};
			if($DEBUG_MODE == 1){
			print "Total Log Duration $$ref_ht_KPIs{TotalLogDuration} = $key1 - $ht_ToStoreStatusesAndTimeStamps{\"LOG--StartTimeStamp\"} \n"; }
			
			# Do End of Log Calculation
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_DEVICE_DISPLAY_ON--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "DisplayOnDuration", "DisplayOffDuration", "DisplayUnknownDuration");
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_AP_AWAKE--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "APAwakeDuration", "APSleepDuration", "APUnknownDuration");
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS"}, \$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_CONNECTED_MODE_STATUS--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "BBWCDMAConnectedModeDuration", "BBWCDMANOTConnectedModeDuration", "BBWCDMAUnknownModeDuration");
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS"}, \$ht_ToStoreStatusesAndTimeStamps{"BB_WCDMA_VOICE_CALL_STATUS--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "WCDMAVoiceCallDuration");
			calculateDurationBasedonGivenInput($ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW"}, \$ht_ToStoreStatusesAndTimeStamps{"IS_USER_USING_THE_DEVICE_NOW--StartTimeStamp"}, $key1, 
													$ref_ht_KPIs, "DurationOfUserUsingTheDevice", "DurationOfUserNotUsingTheDevice");
			
			last;
		}
		
		#====================================
		# Actual KPIs for PDF/CDF
		#====================================
		elsif($ht{$key1} =~ m/ARMUtility\=(.*);ARMUtilityDuration\=(.*);APPSValue\=(.*);PERIPHERALSValue\=(.*)/i)
		{
			my $currentARMActivityValue = $1;
			my $currentARMActivityDuration = $2;
			my $currentAPPSValue = $3;
			my $currentPeripheralsValue = $4;
			
			my $ARMActivityValueNormal = "NA";
			my $ARMActivityValueFiltered = "NA";
			
			#------------------------------------------------------------------
			# Normal ARM Activity Values for all except while battery charging
			#------------------------------------------------------------------
			if($ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} !~ m/YES/i)
			{
				if($isFirstValueOfARMActivityForNormalCase =~ m/YES/i)
				{
					$isFirstValueOfARMActivityForNormalCase = "NO";
				}
				else
				{
					if($currentARMActivityDuration > 0)
					{
						$elapsedDurationForARMActivityForNormalCase = $elapsedDurationForARMActivityForNormalCase + $currentARMActivityDuration;
						$normalizedARMActivityValueForNormalCase = $normalizedARMActivityValueForNormalCase + ($currentARMActivityDuration * $currentARMActivityValue);
					}
					
					if($elapsedDurationForARMActivityForNormalCase >= $userDefinedDurationForARMActivityBining)
					{
						$ARMActivityValueNormal = sprintf ("%0.2f", $normalizedARMActivityValueForNormalCase / $elapsedDurationForARMActivityForNormalCase);
					
						$elapsedDurationForARMActivityForNormalCase = 0;
						$normalizedARMActivityValueForNormalCase = 0;
						
						if($ARMActivityValueNormal < 0)
						{
							$ARMActivityValueNormal = "NA-ive";
						}
					}
				}
			}
			
			#------------------------------------------------------------------
			# Filtered ARM Activity values
			#------------------------------------------------------------------
			if($userActivityStatus =~ m/IDLE/i)
			{
				if($isFirstValueOfARMActivityForFilteredCase =~ m/YES/i)
				{
					$isFirstValueOfARMActivityForFilteredCase = "NO";
					$isConsecutiveARMUtilityValueAboveThreshold = "NO";
				}
				else
				{
					my $ignoreThisARMActivityValue = "NO";
					if(($currentAPPSValue >  ($P3_Threshold_Min - 10)) | ($currentPeripheralsValue > ($P3_Threshold_Min - 10)))
					{
						$ignoreThisARMActivityValue = "YES";
					}
					
					if(($currentARMActivityDuration > 0) && ($ignoreThisARMActivityValue eq "NO"))
					{
						$elapsedDurationForARMActivityForFilteredCase = $elapsedDurationForARMActivityForFilteredCase + $currentARMActivityDuration;
						$normalizedARMActivityValueForFilteredCase = $normalizedARMActivityValueForFilteredCase + ($currentARMActivityDuration * $currentARMActivityValue);
					}
					
					if($ignoreThisARMActivityValue eq "YES")
					{
						$elapsedDurationForARMActivityForFilteredCase = 0;
						$normalizedARMActivityValueForFilteredCase = 0;
						
						$isConsecutiveARMUtilityValueAboveThreshold = "NO";
						$ARMActivityValueFiltered = "NA-IGNORE";
					}
					
					if($elapsedDurationForARMActivityForFilteredCase >= $userDefinedDurationForARMActivityBining_Filtered)
					{
						$ARMActivityValueFiltered = sprintf ("%0.2f", $normalizedARMActivityValueForFilteredCase / $elapsedDurationForARMActivityForFilteredCase);
					
						$elapsedDurationForARMActivityForFilteredCase = 0;
						$normalizedARMActivityValueForFilteredCase = 0;
						
						if($ARMActivityValueFiltered < 0)
						{
							$ARMActivityValueFiltered = "NA-ive";
						}
						else
						{
							if($ARMActivityValueFiltered > $P3_Threshold_Min)
							{
								print $CSV_RESULT_ARM_UTILITY_VALUES_ABOVE_THRESHOLD ",$standardDateTime, $currentARMActivityDuration, $ARMActivityValueFiltered, $isConsecutiveARMUtilityValueAboveThreshold\n";
								$isConsecutiveARMUtilityValueAboveThreshold = "YES";
							}
							else
							{
								$isConsecutiveARMUtilityValueAboveThreshold = "NO";
							}
						}
					}
				}
			}
		
			print $CSV_RESULT_ARM_UTILITY_VALUES ",$standardDateTime, $currentARMActivityValue, $currentARMActivityDuration, $ARMActivityValueNormal, $ARMActivityValueFiltered\n";
		}
		#====================================
		# Actual KPIs for PDF/CDF
		#====================================
		elsif($ht{$key1} =~ m/MPSSUtility\=(.*);MPSSUtilityDuration\=(.*)/i)
		{
			my $currentMPSSActivityValue = $1;
			my $currentMPSSActivityDuration = $2;
			
			my $MPSSActivityValueNormal = "NA";
			my $MPSSActivityValueFiltered = "NA";
			
			#------------------------------------------------------------------
			# Normal MPSS Activity Values for all except while battery charging
			#------------------------------------------------------------------
			if($ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} !~ m/YES/i)
			{
				if($isFirstValueOfMPSSActivityForNormalCase =~ m/YES/i)
				{
					$isFirstValueOfMPSSActivityForNormalCase = "NO";
				}
				else
				{
					if($currentMPSSActivityDuration > 0)
					{
						$elapsedDurationForMPSSActivityForNormalCase = $elapsedDurationForMPSSActivityForNormalCase + $currentMPSSActivityDuration;
						$normalizedMPSSActivityValueForNormalCase = $normalizedMPSSActivityValueForNormalCase + ($currentMPSSActivityDuration * $currentMPSSActivityValue);
					}
					
					if($elapsedDurationForMPSSActivityForNormalCase >= $userDefinedDurationForMPSSActivityBining)
					{
						$MPSSActivityValueNormal = sprintf ("%0.2f", $normalizedMPSSActivityValueForNormalCase / $elapsedDurationForMPSSActivityForNormalCase);
					
						$elapsedDurationForMPSSActivityForNormalCase = 0;
						$normalizedMPSSActivityValueForNormalCase = 0;
						
						if($MPSSActivityValueNormal < 0)
						{
							$MPSSActivityValueNormal = "NA-ive";
						}
					}
				}
			}
			
			#------------------------------------------------------------------
			# Filtered MPSS Activity values
			#------------------------------------------------------------------
			if($userActivityStatus =~ m/IDLE/i)
			{
				if($isFirstValueOfMPSSActivityForFilteredCase =~ m/YES/i)
				{
					$isFirstValueOfMPSSActivityForFilteredCase = "NO";
					$isConsecutiveMPSSUtilityValueAboveThreshold = "NO";
				}
				else
				{
					if($currentMPSSActivityDuration > 0)
					{
						$elapsedDurationForMPSSActivityForFilteredCase = $elapsedDurationForMPSSActivityForFilteredCase + $currentMPSSActivityDuration;
						$normalizedMPSSActivityValueForFilteredCase = $normalizedMPSSActivityValueForFilteredCase + ($currentMPSSActivityDuration * $currentMPSSActivityValue);
					}
					
					if($elapsedDurationForMPSSActivityForFilteredCase >= $userDefinedDurationForMPSSActivityBining_Filtered)
					{
						$MPSSActivityValueFiltered = sprintf ("%0.2f", $normalizedMPSSActivityValueForFilteredCase / $elapsedDurationForMPSSActivityForFilteredCase);
					
						$elapsedDurationForMPSSActivityForFilteredCase = 0;
						$normalizedMPSSActivityValueForFilteredCase = 0;
						
						if($MPSSActivityValueFiltered < 0)
						{
							$MPSSActivityValueFiltered = "NA-ive";
						}
						else
						{
						
							if($MPSSActivityValueFiltered > $P3_Threshold_Min)
							{
								print $CSV_RESULT_MPSS_UTILITY_VALUES_ABOVE_THRESHOLD ",$standardDateTime, $currentMPSSActivityDuration, $MPSSActivityValueFiltered, $isConsecutiveMPSSUtilityValueAboveThreshold\n";
								$isConsecutiveMPSSUtilityValueAboveThreshold = "YES";
							}
							else
							{
								$isConsecutiveMPSSUtilityValueAboveThreshold = "NO";
							}
						}
					}
				}
			}
		
			print $CSV_RESULT_MPSS_UTILITY_VALUES ",$standardDateTime, $currentMPSSActivityValue, $currentMPSSActivityDuration, $MPSSActivityValueNormal, $MPSSActivityValueFiltered\n";
		}
		elsif($ht{$key1} =~ m/BatteryStatus\=(.*)/i)
		{
			my $currentBatteryLevel = sprintf ("%0.2f", $1);
			my $BDPHValueNormal = "NA";
			my $BDPHValueFiltered = "NA";
			
			my $batteryDrainBetweenPrints = 0;
			my $batteryDrainTimeDifference = 0;
			if($previousBatteryLevel < 0)
			{
				$previousBatteryLevel = $currentBatteryLevel;
				$previousBatteryTimestamp = $key1;
			}
			else
			{
				$batteryDrainBetweenPrints = sprintf ("%0.2f", $previousBatteryLevel - $currentBatteryLevel);
				$batteryDrainTimeDifference = sprintf ("%0.3f", $key1 - $previousBatteryTimestamp);
				$previousBatteryLevel = $currentBatteryLevel;
				$previousBatteryTimestamp = $key1;
			}
			
			#------------------------------------------------------------------
			# Normal BDPH Values for all except while battery charging
			#------------------------------------------------------------------
			if($ht_ToStoreIncludeExcludeList{"IS_BATTERY_CHARGING_ACTIVE"} !~ m/YES/i)
			{
				if($startBatteryValueForNormalBDPHCase < 0)
				{
					$startTimeForBDPHForNormalCase = $key1;
					$startBatteryValueForNormalBDPHCase = $currentBatteryLevel;
				}
				else
				{
					my $timeDiff = $key1 - $startTimeForBDPHForNormalCase;
					if($timeDiff >= $userDefinedDurationForBatteryLevelBining)
					{
						$BDPHValueNormal = sprintf ("%0.6f", ($startBatteryValueForNormalBDPHCase - $currentBatteryLevel)/$timeDiff * 3600);
						
						$startTimeForBDPHForNormalCase = $key1;
						$startBatteryValueForNormalBDPHCase = $currentBatteryLevel;
						
						if($BDPHValueNormal < 0)
						{
							$BDPHValueNormal = "NA-ive";
						}
					}
				}
			}
			
			#------------------------------------------------------------------
			# Filtered BDPH values
			#------------------------------------------------------------------
			if($userActivityStatus =~ m/IDLE/i)
			{
				if($startBatteryValueForFilteredBDPHCase < 0)
				{
					$startTimeForBDPHForFilteredCase = $key1;
					$startBatteryValueForFilteredBDPHCase = $currentBatteryLevel;
				}
				else
				{
					my $timeDiff = $key1 - $startTimeForBDPHForFilteredCase;
					if($timeDiff >= $userDefinedDurationForBatteryLevelBining_Filtered)
					{
						$BDPHValueFiltered = sprintf ("%0.6f", ($startBatteryValueForFilteredBDPHCase - $currentBatteryLevel)/$timeDiff * 3600);
						
						$startTimeForBDPHForFilteredCase = $key1;
						$startBatteryValueForFilteredBDPHCase = $currentBatteryLevel;
						
						if($BDPHValueFiltered < 0)
						{
							$BDPHValueFiltered = "NA-ive";
						}
					}
				}
			}
			
			print $CSV_RESULT_BatteryLevel_VALUES ",$standardDateTime, $currentBatteryLevel, $batteryDrainTimeDifference, $batteryDrainBetweenPrints, $BDPHValueNormal, $BDPHValueFiltered\n";
		}
	}
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Print KPIs to File
#================================================================
sub printKPIsToFile{
	my($CSV, $fileName, $ref_HeaderIndices, $ref_KPIs_HT) = @_;

	my @HeaderIndices = @$ref_HeaderIndices;
	my $printLine = $fileName;
	foreach(@HeaderIndices)
	{
		$_ =~ s/^\s+//;
		$_ =~ s/\s+$//;
		if((!defined($$ref_KPIs_HT{$_})))
		{
			$$ref_KPIs_HT{$_} = 0;
		}
		
		$printLine = $printLine . " , " . $$ref_KPIs_HT{$_};
	}
	print $CSV "$printLine \n";
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Sub-routines to calculate durations
# Status: YES, NO, anything else
#================================================================
sub calculateDurationBasedonGivenInput{
	my($status, $ref_startTime, $endTime, 
		$ref_ht_KPIs, $ht_key_ifYES, $ht_key_ifNO, $ht_key_ifUNKNOWN) = @_;
		
	my $timeDiff = 0;
	if($$ref_startTime > 0)
	{
		$timeDiff = sprintf ("%0.2f", $endTime - $$ref_startTime);
		
		if($timeDiff > 0)
		{
			if($status eq "YES")
			{
				if(defined($ht_key_ifYES))
				{
					if(!defined($$ref_ht_KPIs{$ht_key_ifYES}))
					{
						$$ref_ht_KPIs{$ht_key_ifYES} = 0;
					}
					
					$$ref_ht_KPIs{$ht_key_ifYES} = $$ref_ht_KPIs{$ht_key_ifYES} + $timeDiff;
					if($DEBUG_MODE == 1){
					print "Yes Status: $$ref_ht_KPIs{$ht_key_ifYES} = $$ref_ht_KPIs{$ht_key_ifYES} + $timeDiff \n"; }
				}
			}
			elsif($status eq "NO")
			{
				if(defined($ht_key_ifNO))
				{
					if(!defined($$ref_ht_KPIs{$ht_key_ifNO}))
					{
						$$ref_ht_KPIs{$ht_key_ifNO} = 0;
					}
					
					$$ref_ht_KPIs{$ht_key_ifNO} = $$ref_ht_KPIs{$ht_key_ifNO} + $timeDiff;
					if($DEBUG_MODE == 1){
					print "No Status: $$ref_ht_KPIs{$ht_key_ifNO} = $$ref_ht_KPIs{$ht_key_ifNO} + $timeDiff \n"; }
				}
			}
			else
			{
				if(defined($ht_key_ifUNKNOWN))
				{
					if(!defined($$ref_ht_KPIs{$ht_key_ifUNKNOWN}))
					{
						$$ref_ht_KPIs{$ht_key_ifUNKNOWN} = 0;
					}
					
					$$ref_ht_KPIs{$ht_key_ifUNKNOWN} = $$ref_ht_KPIs{$ht_key_ifUNKNOWN} + $timeDiff;
					if($DEBUG_MODE == 1){
					print "Unknown Status: $$ref_ht_KPIs{$ht_key_ifUNKNOWN} = $$ref_ht_KPIs{$ht_key_ifUNKNOWN} + $timeDiff \n"; }
				}
			}
		}
	}
	if($DEBUG_MODE == 1){
	print "Status: $status, StartTime: $$ref_startTime, EndTime: $endTime \n"; }
	
	$$ref_startTime = $endTime;
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Print the HT
#================================================================
sub printTheHT{
	my($ref_ht) = @_;
	
	#=============================================
	# **** Print the HT for the Current Log ****
	#=============================================
	for my $key1 ( sort {$a<=>$b} keys %$ref_ht ) 
	{
		print "Timestamp: $key1 >> $$ref_ht{$key1} \n";
	}
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Get User Activity Status
#================================================================
sub getUserActivityStatus{
	my($ref_ht_ToStoreIncludeExcludeList) = @_;
	my $userActivityStatus = "IDLE";
	
	#print "User Activity Status:";
	for my $key1 ( sort {$b<=>$a} keys %$ref_ht_ToStoreIncludeExcludeList ) 
	{
		#print "$key1 >> $$ref_ht_ToStoreIncludeExcludeList{$key1};";
		if($$ref_ht_ToStoreIncludeExcludeList{$key1} eq "YES")
		{
			$userActivityStatus = "USERActive";
			last;
		}
	}
	#print"\n";
	
	#print "Status :: $userActivityStatus \n";
	return $userActivityStatus;
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Create new HT
#================================================================
sub createNewHT{
	my %ht   = ();
	
	return (\%ht);
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input:
# Return: 
#
# Function: Fill HT with zeroes
#================================================================
sub fillTheHTWithZeroes{
	my ($ref_ht, $minValue, $maxValue, $stepSize, 
		$roundingFactor) = @_;

	# Fill the PDF Hash File bin values with zero
	if($minValue > $maxValue)
	{
		my $temp = $minValue;
		$minValue = $maxValue;
		$maxValue = $temp;
	}
	
	if($stepSize < 0)
	{
		$stepSize = $stepSize * -1;
	}
	
	
	if($stepSize != 0)
	{
		my $i = $minValue;
		for(; $i <= $maxValue;)
		{
			$$ref_ht{$i} = 0;
			#print "$i \n";
			$i = sprintf ($roundingFactor, $i + $stepSize);
		}
	}
}

#================================================================
# Number of Inputs: 2
# Number of Return: 2
# Input: HT, Key, Value
# Return: 
#
# Function: Add Value to HT,
# Since Key is Time, if already exists, add "1" at the end
#================================================================
sub addHTValue{
	my ($ht_ref, $key_timeStamp, $value, $isTimeInMillisecs) = @_;

	my @key_temp = split(':', $key_timeStamp);
	my $timeStamp = "";
	my $timeStamp_1 = "";
	
	if(defined($isTimeInMillisecs) && ($isTimeInMillisecs =~ m/YES/i | $isTimeInMillisecs =~ m/TRUE/i))
	{
		$timeStamp = $key_timeStamp;
	}
	else
	{
		$timeStamp = (($key_temp[0] * 60 * 60) + ($key_temp[1] * 60) + $key_temp[2]) * 1000;
	}
	$timeStamp_1 = $timeStamp;
	
	my $k = 1;
	checkTimeStamp:
	if (exists $$ht_ref{$timeStamp_1}) 
	{
		$timeStamp_1 = $timeStamp + ($k * 0.0001);
		$k++;
		goto checkTimeStamp;
		
		print "DEBUG >> TimeStamp exists in HT \n";
	}
	
	$$ht_ref{$timeStamp_1} = $value;
	#print "DEBUG >> TimeStamp $timeStamp_1 >> $value \n";
}

#================================================================
# Number of Inputs: 4
# Number of Return: 0
# Input: FileHandle, HT_ref, MinValue, MaxValue
# Return: NONE
#
# Function: Print the PDF for all the values in a hashtable
#================================================================
sub printPDF{
	my ($FileHandle, $ht_ref, $MinValue, $MaxValue, $stepSize, $name) = @_;
	
	#Print the PDF Counts
	for my $key1 ( sort {$b<=>$a} keys %$ht_ref ) 
	{
		my $printLine = $$ht_ref{$key1}{File_Name};
		$$ht_ref{$key1}{Total} = 0;
		
		for(my $k = $MinValue; $k <= $MaxValue; $k = $k + $stepSize)
		{
			$k = sprintf($roundingFactor, $k);
			if((!defined($$ht_ref{$key1}{$k})))
			{
				$$ht_ref{$key1}{$k} = 0;
			}
			$printLine = $printLine . "," . $$ht_ref{$key1}{$k};
			$$ht_ref{$key1}{Total} = $$ht_ref{$key1}{Total} + $$ht_ref{$key1}{$k}; #calculate total
		}
		
		print $FileHandle "$printLine \n";
	}
	
	#Print the PDF %ages
	printPDFCDFHeader($FileHandle, $name . " Percentages", "FileName", $MinValue, $MaxValue, $stepSize);
	for my $key1 ( sort {$b<=>$a} keys %$ht_ref ) 
	{
		my $printLine = $$ht_ref{$key1}{File_Name};
		
		for(my $k = $MinValue; $k <= $MaxValue; $k = $k + $stepSize)
		{
			$k = sprintf($roundingFactor, $k);
			if((!defined($$ht_ref{$key1}{$k})))
			{
				$$ht_ref{$key1}{$k} = 0;
			}
			my $value = 0;
			if($$ht_ref{$key1}{Total} > 0)
			{
				$value = $$ht_ref{$key1}{$k} / $$ht_ref{$key1}{Total} * 100;
			}
			my $value1 = sprintf("%.2f", $value);
			$printLine = $printLine . "," . $value1;
		}
		
		print $FileHandle "$printLine \n";
	}
}

#================================================================
# Number of Inputs: 5
# Number of Return: 0
# Input: FileHandle, Header1, Header2, MinValue, MaxValue
# Return: NONE
#
# Function: Print the Headers for PDF/CDF
#================================================================
sub printPDFCDFHeader{
	my ($FileHandle, $Header1, $Header2, $MinValue, $MaxValue, $stepSize) = @_;
	
	print $FileHandle " \n\n";
	print $FileHandle "$Header1 \n";
	my $printLine = $Header2;
	for(my $k = $MinValue; $k <= $MaxValue; $k = $k + $stepSize)
	{
		$k = sprintf($roundingFactor, $k);
		$printLine = $printLine . "," . $k;
	}
	
	print $FileHandle "$printLine \n";
}

#================================================================
# Number of Inputs: 5
# Number of Return: 0
# Input: FileHandle, HT_ref, MinValue, MaxValue
# Return: NONE
#
# Function: Print the CDF for all the values in a hashtable
#================================================================
sub printCDF{
	my ($FileHandle, $ht_ref, $MinValue, $MaxValue, $stepSize, $name) = @_;
	
	# Print the CDF Counts
	for my $key1 ( sort {$b<=>$a} keys %$ht_ref ) 
	{
		my $printLine = $$ht_ref{$key1}{File_Name};
		$$ht_ref{$key1}{Total} = 0;
		
		my $curr_CDF_Value = 0;
		for(my $k = $MinValue; $k <= $MaxValue; $k = $k + $stepSize)
		{
			$k = sprintf($roundingFactor, $k);
			if((!defined($$ht_ref{$key1}{$k})))
			{
				$$ht_ref{$key1}{$k} = 0;
			}
			
			$curr_CDF_Value = $curr_CDF_Value + $$ht_ref{$key1}{$k};
			
			$printLine = $printLine . "," . $curr_CDF_Value;
		}
		$$ht_ref{$key1}{Total} = $curr_CDF_Value; #Get the total
		
		print $FileHandle "$printLine \n";
	}
	
	#Print the CDF %ages
	printPDFCDFHeader($FileHandle, $name . " Percentages", "FileName", $MinValue, $MaxValue, $stepSize);
	for my $key1 ( sort {$b<=>$a} keys %$ht_ref ) 
	{
		my $printLine = $$ht_ref{$key1}{File_Name};
		
		my $curr_CDF_Value = 0;
		for(my $k = $MinValue; $k <= $MaxValue; $k = $k + $stepSize)
		{
			$k = sprintf($roundingFactor, $k);
			if((!defined($$ht_ref{$key1}{$k})))
			{
				$$ht_ref{$key1}{$k} = 0;
			}
			
			$curr_CDF_Value = $curr_CDF_Value + $$ht_ref{$key1}{$k};
			
			my $value = 0;
			if($$ht_ref{$key1}{Total} > 0)
			{
				$value = $curr_CDF_Value / $$ht_ref{$key1}{Total} * 100;
			}
			my $value1 = sprintf("%.2f", $value);
			
			$printLine = $printLine . "," . $value1;
		}
		
		print $FileHandle "$printLine \n";
	}
}