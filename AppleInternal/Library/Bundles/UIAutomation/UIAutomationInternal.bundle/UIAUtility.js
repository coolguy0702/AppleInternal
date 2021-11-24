// Copied from AppScriptingScripts/libs/ as a short term workaround <rdar://problem/17022799>.
// This file will not be maintained in step with the master copy at AppScriptingScripts

load("System.js");

/**
 * @file UIAUtility.js
 * This file contains general utility functions and objects
 *
 * @defgroup utility UIAUtility
 * @brief This module contains general the utility functions and objects
 *
 * @{
 */

function UIAUtility() {}

/**
 *	Returns a shuffled index array. i.e. an array of length n
 *	where the ith index of the array contains a number from 0 to n-1
 *   
 *  @tparam integer n - the length of the array
 *   
 *  @treturn array The shuffled index array
 **/
UIAUtility.randomIndexArray = function randomIndexArray(n) {
    var oldArray = new Array();
    for (var i=0; i<n; i++) oldArray.push(i);
	
    var randomArray = new Array();
    while (oldArray.length > 0) {
        var x = system.randomInteger(0, oldArray.length-1);
        randomArray.push(oldArray[x]);
		oldArray.splice(x,1);
    }
	
    return randomArray;
}

/**
 *	Returns a radom item from the items array
 *   
 *  @tparam array items - an array of items to pull from
 *   
 *  @treturn object The random item from the items array
 **/
UIAUtility.randomFromArray = function randomFromArray(items) {
	if (!items || (items.length == 0)) {
		UIALogger.logError("Requires an array.")
		return null;
	}
	var count = items.length - 1;
	var index = system.randomInteger(0, count);
	return items[index];
}

/**
 *	Parses input parameters of the form {"key1:value1",
 *	"key2:value2", "key1:value3"}.  Note that the function does an exact
 *	comparison, but the case of the letters don't matter.
 *   
 *  @tparam string key - key that you are looking for
 *  @tparam array array - array of data that the function is parsing
 *  @tparam number numValuesExpected - number of values that are expected.  If 1 
 *		specified, returns only the first value found (not in an array).
 *		If greater than one specified, returns an array.
 *   
 *  @treturn array The array of data that matches the input key.  
 *		i.e. if you passed in "key1", the function would return {"value1", "value3"}. 
 *		If numValuesExpected is one, the function returns a string/integer/whatever that is not in an array.
 **/
UIAUtility.valuesForKey = function valuesForKey(inputKey, array, numValuesExpected) {
	if (!array || (array.length < 1)) {
		UIALogger.logMessage("Array for key '" + inputKey + "' is empty.");
		return null;
	}
	var returnArray = new Array();
	
	for (var i=0; i < array.length; i++) {
		if (typeof array[i] == 'string') {
			var colonIndex = array[i].indexOf(":");
			if ((colonIndex > 0) && (colonIndex < (array[i].length - 1))) {
				var key = array[i].substring(0, colonIndex);
				if (key.toLowerCase() == inputKey.toLowerCase()) {
					var value = array[i].substr(colonIndex + 1);
					if (numValuesExpected == 1) {
						UIALogger.logMessage("Returning '" + value + "' for key '" + key + "'.  Only one value expected."); 
						return value;
					}
					returnArray.push(value);
					UIALogger.logMessage("Pushing '" + value + "' for key '" + key + "'.");
					if (returnArray.length >= numValuesExpected) {
						return returnArray;
					}
				}
			}
		}
	}
	if (returnArray.length < 1) 
		return null;
	else
		return returnArray;
}

UIAUtility.stringToBoolean = function stringToBoolean(string) {
    if ( !string ) {
        return null
    }

    if (typeof string == 'boolean') {
        return string
    }    
    
    switch(string.toLowerCase()){
        case "true": case "yes": case "1": return true;
        case "false": case "no": case "0": case null: return false;
        default: return Boolean(string);
    }
    return true
}

UIAUtility.isPadlike = function isPadlike() {
    return (UIATarget.localTarget().model() == 'iPad');
}

// This is for checking if two Date (or UIADate) objects are equal
// date1 (Date object) - The first date to check
// date2 (Date object) - The second date to check
// marge (number) - The seconds the dates are allowed to be off to still eval to equal
UIAUtility.areDatesEqual = function areDatesEqual(date1, date2, margin) {
    margin = (margin ? margin : 0);
    var date1Time = date1.getTime();
    var date2Time = date2.getTime();
    return (Math.abs(date1Time - date2Time) <= (margin * 1000));
}

// This is for getting two Date objects for the daylight saving days
// of a particular year
// year (string) - Year in YYYY format for DST day (only between 2007 and 2099 valid)
// return (array) - Array of two Date objects for the DST days of given year
UIAUtility.getDSTDatesForYear = function getDSTDatesForYear(year) {
    // Set DST start to 2AM 2nd Sunday of March
    var dst_start = new Date(year, 2, 1, 2, 0, 0, 0);
    
    // Get to the second sunday
    if ((dst_start.getDay() != 0)) {
        dst_start.setDate(dst_start.getDate() + (7 - dst_start.getDay()));
    }
    dst_start.setDate(dst_start.getDate() + 7);
    
    // Set DST end to 2AM 1st Sunday of November
    var dst_end = new Date(year, 10, 1, 2, 0, 0, 0);
    // Need to be on first Sunday
    if (dst_end.getDay() != 0) {
        dst_end.setDate(dst_end.getDate() + (7 - dst_end.getDay()));
    }
    
    return [dst_start, dst_end];
}

function UIADate() {
	this.time = system.run("/bin/date \"+%s\"", 10).stdout.split('\n')[0];
}

UIADate.yearType = "Y";
UIADate.monthType = "m";
UIADate.dateType = "d";
UIADate.hourType = "H";
UIADate.minutesType = "M";
UIADate.secondsType = "S";
UIADate.dayType = "w";
UIADate.weekdays = {
	Sun : 0,
	Mon : 1,
	Tue : 2,
	Wed : 3,
	Thu : 4,
	Fri : 5,
	Sat : 6
}


UIADate.prototype._run = function _run(cmd) {
	var tzPrefix = (this.timeZone) ? "/usr/bin/env TZ=" + this.timeZone + " " : "";
	var runcmd = tzPrefix + "/bin/date -j " + cmd + "";
	//UIALogger.logDebug(runcmd);
	return system.run(runcmd, 10).stdout.split('\n')[0];
}

UIADate.prototype._get = function _get(type) {
	return parseInt(this._run("-f \"%s\" " + this.time + " \"+%" + type+ "\""),10);
}

UIADate.prototype._set = function _set(type, value) {
	this.time = this._run("-v \"" + value + type + "\" -f \"%s\" " + this.time + " \"+%s\"");
}

UIADate.prototype.getDate = function getDate() {
	return this._get(UIADate.dateType);
}

UIADate.prototype.getDay = function getDay() {
	return this._get(UIADate.dayType);
}

UIADate.prototype.getFullYear = function getFullYear() {
	return this._get(UIADate.yearType);
}

UIADate.prototype.getHours = function getHours() {
	return this._get(UIADate.hourType);
}

UIADate.prototype.getMinutes = function getMinutes() {
	return this._get(UIADate.minutesType);
}

UIADate.prototype.getMonth = function getMonth() {
	return this._get(UIADate.monthType)-1;
}

UIADate.prototype.getSeconds = function getSeconds() {
	return this._get(UIADate.secondsType);
}

UIADate.prototype.getTime = function getTime() {
	return this.time*1000;
}

UIADate.prototype.setDate = function setDate(date) {
	this._set(UIADate.dateType, date);
}

UIADate.prototype.setDay = function setDay(day) {
	this._set(UIADate.dayType, day);
}

UIADate.prototype.setFullYear = function setFullYear(year) {
	this._set("y", year);
}

UIADate.prototype.setHours = function setHours(hours) {
	this._set(UIADate.hourType, hours);
}

UIADate.prototype.setMinutes = function setMinutes(minutes) {
	this._set(UIADate.minutesType, minutes);
}

UIADate.prototype.setMonth = function setMonth(month) {
	if (month.toString().charAt(0) == "+" || month.toString().charAt(0) == "-")
		this._set(UIADate.monthType, month);
	else
		this._set(UIADate.monthType, (parseInt(month)+1).toString());
}

UIADate.prototype.setSeconds = function setSeconds(seconds) {
	this._set(UIADate.secondsType, seconds);
}

UIADate.prototype.setTime = function setTime(time) {
	this.time = Math.round(time/1000);
}

UIADate.prototype.toString = function toString() {
	return this._run("-f \"%s\" " + this.time);
}
/**
 *       Function: setWithOptions
 *           Set the date object to the specified time 
 *   
 *  \param options (object) - a hash of optional parameters
 *   
 *  \param Optional parameters:
 *           year (string) - a number in the format [YY]YY to specify the year. If no value 
 *               is specified, the current year value is used. Adding a "+" or "-" prefix 
 *               will add or subtract the specified value from the current value. 
 *           month (string) - a number in the format [M]M to specify the month. If no value 
 *               is specified, the current month value is used. Adding a "+" or "-" prefix 
 *               will add or subtract the specified value from the current value. 
 *           date (string) - a number in the format [D]D to specify the date. If no value
 *               is specified, the current date value is used. Adding a "+" or "-" prefix 
 *               will add or subtract the specified value from the current value. 
 *           hours (string) - a number in the format [H]H to specify the hour. If no value 
 *               is specified, the current hour value is used. Adding a "+" or "-" prefix 
 *               will add or subtract the specified value from the current value. 
 *           minutes (string) - a number in the format [M]M to specify the minutes. If 
 *               no value is specified, the current minutes value is used. Adding a "+" or 
 *               "-" prefix will add or subtract the specified value from the current value. 
 *           seconds (string) - a number in the format [S]S to specify the seconds. If no 
 *               value is specified, the current seconds value is used. Adding a "+" or "-" 
 *               prefix will add or subtract the specified value from the current value. 
 *           dateString (string) - a string in the format YYYY:MM:DD:HH:MM:SS that will be 
 *               parsed to obtain the year, month, date, hour and minute values. Adding a 
 *               "+" or "-" prefix to any of the values will add or subtract the specified 
 *               value from the current value. 
 *           timeZone (string) 
 *   
 *  \return None
 **/
UIADate.prototype.setWithOptions = function setWithOptions(options) {
	if (!options) options = new Object();
	if (options.timeZone) this.timeZone = options.timeZone;
	
	if (options.dateString) {
		var timeArray = options.dateString.split(':');
		options.year = timeArray[0];
		options.month = timeArray[1];
		options.date = timeArray[2];
		options.hours = timeArray[3];
		options.minutes = timeArray[4];
		options.seconds = timeArray[5];
	}
	
	if (options.year != undefined && options.year !== "") this.setFullYear(options.year);
	if (options.month != undefined && options.month !== "") {
		if (options.month.charAt(0) != "+" && options.month.charAt(0) != "-")
			this.setMonth((options.month-1).toString()); //mapping the actual month value to the value JS expects
		else
			this.setMonth(options.month);
	}
	if (options.date != undefined && options.date !== "") this.setDate(options.date);
	if (options.hours != undefined && options.hours !== "") this.setHours(options.hours);
	if (options.minutes != undefined && options.minutes !== "") this.setMinutes(options.minutes);
	if (options.seconds != undefined && options.seconds !== "") this.setSeconds(options.seconds);
}

UIADate.prototype.getDateString = function getDateString() {
	var resultString = "";
	resultString = this.getFullYear();
	resultString += ":" + ((this.getAdjustedMonth() < 10) ? "0" + this.getAdjustedMonth() : this.getAdjustedMonth());
	resultString += ":" + ((this.getDate() < 10) ? "0" + this.getDate() : this.getDate());
	resultString += ":" + ((this.getHours() < 10) ? "0" + this.getHours() : this.getHours());
	resultString += ":" + ((this.getMinutes() < 10) ? "0" + this.getMinutes() : this.getMinutes());
	resultString += ":" + ((this.getSeconds() < 10) ? "0" + this.getSeconds() : this.getSeconds());
	return (resultString);
}

UIADate.dateWithDateString = function dateWithDateString(dateString) {
	var result =  (new UIADate());
	result.setWithOptions({dateString:dateString});
	return result;
}
UIADate.dateWithDateStringInTimeZone = function dateWithDateStringInTimeZone(dateString, tz) {
	var result =  (new UIADate());
	result.setWithOptions({timeZone:tz, dateString:dateString});
	return result;
}

UIADate.prototype.getAdjustedMonth = function getAdjustedMonth() {
	return this.getMonth()+1;
}

/**
 *       Function: consolidateArray 
 *           Takes each item in the array, and, if it is next
 *           to the same item, collapses them.  (For example, 
 *           ["John", "John", "Mary", "Joe", "John"]) would be collapsed into 
 *           ["John (2)", "Mary", "Joe", "John"]
 *   
 *  \param inputArray - the array to be consolidated.
 *  \param collapseString - if this is present, the first John in the example above
 *               becomes "John (2 <collapseString>)" (optional)
 *   
 *  \return A consolidated array if the object passed in exists, null if it does not
 **/
UIAUtility.consolidateArray = function consolidateArray(inputArray, collapseString) {
	var last = "";
	var timesSeen = 1;
	var returnArray = new Array();
	
	if ((!inputArray) || (inputArray.length < 1)) {
		return null;
	}
	if (!collapseString)  	collapseString = "";
	else 	collapseString = " " + collapseString;
	
	for (var i=0; i<inputArray.length; i++) {
		if (last == inputArray[i]) {
			timesSeen++;
		}
		else if (timesSeen > 1) {
			returnArray.push(last + " (" + timesSeen + collapseString + ")");
			timesSeen = 1;
		}
		else {
			if (last != "") {
				returnArray.push(last);
			}
		}
		last = inputArray[i];
	}
	if (timesSeen > 1) {
		returnArray.push(last + " (" + timesSeen + collapseString + ")");
	}
	else {
		returnArray.push(last);
	}
	
	return returnArray;
}

/**
 *  Prints out some network stats for diagnostic purposes.
 *   
 *  @tparam None
 *   
 *  @treturn boolean - true if pings are not timing out
 **/
UIAUtility.getNetworkInfo = function getNetworkInfo() {
	var returnValue = 1;

	//ping test
	UIAUtility.logToolOutput("/sbin/ping -c 10 17.202.32.1", 60); // internal network -- will timeout if we're not on an internal network
	var pingResult = UIAUtility.logToolOutput("/sbin/ping -c 10 www.google.com", 60);  // external network -- base return value on this.
	if (pingResult.indexOf("Request timeout") >= 0) {
		returnValue = 0;
	}
	
	//ifconfig
	UIAUtility.logToolOutput("/sbin/ifconfig en0", 30);
	
	// wifi
	UIAUtility.logToolOutput("/usr/local/bin/wifitool --currentnet",10);
	UIAUtility.logToolOutput("/usr/local/bin/apple80211 -rssi", 10);
	
	return returnValue;
}

/**
 *	Reads the appStress plist to get an array of tools to run
 *   
 *  @tparam string domain - domain to read the utility commands from
 *  @tparam string key - key the utility commands are stored under
 *   
 *  @treturn boolean true if all of the commands execute successfully false if any 
 *		of the commands fail to execute properly, or there are no commands to execute
 **/
UIAUtility.runUtilities = function runUtilities(domain, key) {
	if (!domain) domain = "com.apple.AppStress";
	if (!key) key = "utilities";
	
	var utilities = system.getDefault(domain, "utilities");
	var output = "";
	var result = true;
	
	//if the default plist doesn't have any utilities or if the plist doesn't exist, return
	if (!utilities)
		return false;
	
	//go throught he commands and execute them
	for (var i=0; i < utilities.length; i++) {
		output = "";
		try {
			output = UIAUtility.logToolOutput(utilities[i], 10);
		}
		catch(err) {
			system.println("Error, could not execute the following command: " + utilities[i]);
			result = false;
		}
		//no output means the command didn't execute
		if (output == "") {
			system.println("Error, could not execute the following command: " + utilities[i]);
			result = false;
		};
		system.println("");
	};
	
	return result;
}

/**
 *  Runs a system command and logs the output to standard out.
 *   
 *  @tparam string command - the command to be executed
 *  @tparam integer timeout - max number of seconds to wait for the command to be executed (optional)
 *  @tparam string searchString - only print out lines that match the searchstring. (optional -- if
 *               not specified, we will print out all lines)
 *   
 *  @treturn Output if command succeeded, error string if command failed.
 **/
UIAUtility.logToolOutput = function logToolOutput(command, timeout, searchString) {
	var defaultTimeout = 300.0;
	if (timeout == 'undefined' || !timeout) {
		system.println("timeout undefined, using default: " + defaultTimeout);
		timeout = defaultTimeout;
	}
	timeout = parseFloat(timeout);
	
	var result;
	system.println("Running command: " + command);
	try {
		result = system.run(command, timeout);
	} catch(error) {
		return error;
	}
	if (!result) return "system.run failed to run command '" + command + "'.";
	
	var output = result.stdout;
	var error = result.stderr;
	var total_output = "";
	if (output) {
		total_output = total_output + output; 
		if (searchString){
			var outputList = total_output.split("\n"); 
			for (var i=0; i<outputList.length; i++) {
				var matchList = outputList[i].match(searchString);
				if (matchList != null) {
					system.println(outputList[i]);
				}
			}
		}
		else {
			system.println(output);
		}
	}
	if (error) {
		total_output = total_output + error;
		system.println(error);
	}
	return total_output;
}

/**
 *	Returns the total number of seconds that have passed since Jan 1, 1970
**/
UIAUtility.getCurrentTimeInSeconds = function getCurrentTimeInSeconds() {
	var d = new Date();
	var tis = d.getTime() / 1000;
	return tis;
}

/**
 *	Takes in number of seconds and returns an Hour Minutes Seconds formatted string
**/
UIAUtility.getFormattedTime = function getFormattedTime(time) {
	var hours = 0;
	var minutes = 0;
	var seconds = 0;
	
	var hours = Math.floor(time / 3600);
	var minutesTmp = (time - (hours * 3600)) / 60;
	if (minutesTmp >= 1) {
		var minutes = Math.floor((time - (hours * 3600)) / 60);
	}
	var seconds = (time - (hours * 3600) - (minutes * 60));
	
	var theResult = "" + hours + " Hour(s), " + minutes + " Minute(s), " + seconds.toFixed(2) + " Second(s).";
	return theResult;
}

/**
 *	Creates an object with properties that match the options passed in as arguments
 *   
 *  @tparam array args - the list of arguments (if undefined the script arguments, ARGV, will be used)
 *   
 *  @treturn object 
 **/
function Options(args)
{
	if (!args) args = ARGV;
	if (!args.length) return;
	
	for (var index = 0; index < args.length; index) {
		if (args[index].match("^-")) {
			
			if (args[index].match("^--")) {
				var property = args[index++].replace(/^-*/, "");					
			} else {
				// set each option in the string of options that follows a '-'
				for (var cIndex = 1; cIndex < args[index].length; cIndex++) {
					var property = args[index].charAt(cIndex);
					this[property] = true;
				}
				index++;
			}
			
			// set the last simple option '-' or a long named option that follow '--'
			var vals = new Array();
			while ((index < args.length) && (!args[index].match("^-"))) {
				vals.push(args[index]);
				index++;
			}
			switch (vals.length) {
				case 0:	// when no arguments follow the option name
					this[property] = true;
					break;
				case 1: // when a single argument follow the option name
					this[property] = vals[0];
					break;
				default: // when multiple arguments follow the option name
					this[property] = vals;
			}
		} else {
			index++;
		}
	}
}


/**
 *	Function for parsing track position values
 *   
 *  @tparam string trackPositionValue - Value of the current playback information, including 
 *                                       elapsed playback time and total playback time
 *   
 *  @treturn object An object with 2 properties: 
 *		elapsedTimeInfo - hash with seconds, minutes and hours of the current playback time                                
 *		totalTimeInfo - hash with seconds, minutes and hours of total track playback time
 **/
UIAUtility.processTrackPositionValue = function processTrackPositionValue(trackPositionValue) {
	
	var trackPositionInfo = new Object();
	
	if (trackPositionValue.indexOf(' of ') < 0) {
		throw new Error("Track position value not in expected format: " + trackPositionValue);
	}
	
	var elapsedTimeInfo = {seconds:0, minutes:0, hours:0};
	var timeElapsedArr = trackPositionValue.split(' of ')[0].split(':');
	if (timeElapsedArr.length < 1) throw new Error("Elapsed time value is not in the expected format");
	
	elapsedTimeInfo.seconds = parseInt(timeElapsedArr[timeElapsedArr.length-1]);
	if (timeElapsedArr.length > 2) elapsedTimeInfo.minutes = parseInt(timeElapsedArr[timeElapsedArr.length-2]); //minutes
	if (timeElapsedArr.length > 3) elapsedTimeInfo.hours = parseInt(timeElapsedArr[timeElapsedArr.length-3]); //hours
	
	var totalTimeInfo = {seconds:0, minutes:0, hours:0};
	var totalTimeArr = trackPositionValue.split(' of ')[1].split(':');
	if (totalTimeArr.length < 1) throw new Error("Total time value is not in the expected format");
	
	totalTimeInfo.seconds = parseInt(totalTimeArr[totalTimeArr.length-1]); //seconds
	if (totalTimeArr.length > 2) totalTimeInfo.minutes = parseInt(totalTimeArr[totalTimeArr.length-2]); //minutes
	if (totalTimeArr.length > 3) totalTimeInfo.hours = parseInt(totalTimeArr[totalTimeArr.length-3]); //hours

	trackPositionInfo.elapsedTimeInfo = elapsedTimeInfo;
	trackPositionInfo.totalTimeInfo = totalTimeInfo;
	
	return trackPositionInfo;
} // processTrackPositionValue

/**
 *  Parses the table value and returns the first visible index,
 *  last visible index, and number of cells in the table.
 *   
 *  @tparam tableValue (string) - the value of the table (generally obtained by calling
 *               value() on UIATableView object)
 *   
 *  @treturn An object with 3 properties: 
 *               firstVisibleIndex - the index of the first visible table cell                                
 *               lastVisibleIndex - the index of the last visible table cell
 *               noOfElements - the total number of elements in the table (not necessarily cells)
 *   
 *       Usage: e.g. for a table value of "rows 1 to 3 of 5", {firstVisibleIndex:1, 
 *           lastVisibleIndex:3, noOfCells:5} will be returned
 *   
 **/
UIAUtility.tableInfoFromValue = function tableInfoFromValue(tableValue) {
	var tableInfo = {firstVisibleIndex:0, lastVisibleIndex:0, noOfElements:0};
	
	if (tableValue == null) return tableInfo;
	
	if (tableValue.indexOf("of") < 0) 
		throw new Error("Table value '" + tableValue + "' not in expected format");
	var splitArr = tableValue.split(' ');
	
	if (splitArr.length == 6) {
		tableInfo.firstVisibleIndex = parseInt(splitArr[1]);
		UIALogger.logDebug("firstVisibleIndex=" + tableInfo.firstVisibleIndex);
		
		tableInfo.lastVisibleIndex = parseInt(splitArr[3]);
		UIALogger.logDebug("lastVisibleIndex=" + tableInfo.lastVisibleIndex);
		
		tableInfo.noOfElements = parseInt(splitArr[5]);
		UIALogger.logDebug("noOfElements=" + tableInfo.noOfElements);
	} else {
		tableInfo.firstVisibleIndex = parseInt(splitArr[1]);
		UIALogger.logDebug("firstVisibleIndex=" + tableInfo.firstVisibleIndex);
		
		tableInfo.lastVisibleIndex = parseInt(splitArr[1]);
		UIALogger.logDebug("lastVisibleIndex=" + tableInfo.lastVisibleIndex);
		
		tableInfo.noOfElements = parseInt(splitArr[3]);
		UIALogger.logDebug("noOfElements=" + tableInfo.noOfElements);
	}
	
	return tableInfo;
}

/**
 *       Function: scrollWheelToValueWithOptions
 *           Function for scrolling a date (or time) picker wheel.  
 *   
 *  \param pickerWheel (UIAPickerWheel) -  Picker wheel to scroll
 *  \param wheelValue (string|UIAPredicateString) - value of the wheel to scroll to.
 *                       To make this method more flexible when searching for a value in
 *                       a picker wheel, a string or UIAPredicateString may be used.  
 *                       To use a UIAPredicateString, create an instance of a UIAPredicateString
 *                       and pass it to the scrollWheelToValueWithOptions method. 
 *                       For Example:
 *                       UIAUtility.scrollWheelToValueWithOptions(w1,new UIAPredicateString("value beginswith '101'"));
 *                       
 *  \param 
 *  \param Optional:    
 *           maxDrags (int) - maximum number of drags to perform. (Defaults to 100)
 *           direction (int) -  direction to scroll. (Defaults to scrolling down)
 *                           1: scroll (drag) the wheel down 
 *                           0: scroll (drag) the wheel up
 *           useSleep (int) - Use system.run("/bin/sleep 1") instead of the delay(1) between scroll 
 *                           drags.  This is a special case and should ONLY used when 
 *                           setting the system date and time via the Settings UI.  Defaults to 0 (false)
 *   
 *  \return None
 *  \return 
 *  \throws An error if the value was not found
 **/
UIAUtility.scrollWheelToValueWithOptions = function scrollWheelToValueWithOptions(pickerWheel, wheelValue, options) {

	if ( !options ) options = new Object();
	var maxDrags = ( typeof options.maxDrags != 'undefined' ) ? options.maxDrags : 100;
	var direction = ( typeof options.direction != 'undefined' ) ? options.direction : 1;
	var useSleep = ( typeof options.useSleep != 'undefined' ) ? options.useSleep : 0;
	var currentDrag = 0;
	var isPredicate = (wheelValue instanceof UIAPredicateString);
	var value = (isPredicate) ? "pickerWheel.withPredicate(\"" + wheelValue.predicateString + "\").isValid()" : "pickerWheel.withValueForKey(\"" + wheelValue + "\", 'value').isValid()";

	
	UIALogger.logMessage("Scrolling picker wheel to " + wheelValue);
	UIALogger.logDebug("Value: " + value);
    
    var values =pickerWheel.values();
    if (values instanceof Array && values.length > 0) {
        try {
            pickerWheel.selectValue(wheelValue);
        } catch (error) {
            UIALogger.logError("Failed to selectValue: " + error);
        }
    }

	if (!eval(value)) {
        UIATarget.localTarget().pushTimeout(0);
        try {
            while (!eval(value) && (currentDrag < maxDrags)) {
                UIALogger.logMessage("currentValue: "+ pickerWheel.value());
                
                if (!direction){ 
                    pickerWheel.dragInsideWithOptions({startOffset:{x:"0.5", y:"0.45"}, endOffset:{x:"0.5", y:"0.55"}});
                } else {
                    pickerWheel.dragInsideWithOptions({startOffset:{x:"0.5", y:"0.55"}, endOffset:{x:"0.5", y:"0.45"}});
                }
                //Give the wheel a second to settle before checking the value (sometimes it snaps back to a previous value)
                //Changed to system command since using delay() was incompatible with changing system time via UI
                if (useSleep) system.run("/bin/sleep 0.5");
                else UIATarget.localTarget().delay(0.5);
                
                currentDrag++;
            }
        }  finally {
            UIATarget.localTarget().popTimeout();
        }
    }
    
	if (!eval(value)) {
		var errorString = (isPredicate) ? "Did not find value specified by predicate " + wheelValue.predicateString : "Did not find " + wheelValue + " while scrolling picker wheel";
		throw new Error(errorString);
	}

	UIALogger.logMessage("Found " + pickerWheel.value());
		
} //end scrollDatePickerWheel

/**
 *       Function: sortByLocation
 *           This function sorts the UIAElement objects passed in (by location) 
 *           and returns back a newly sorted list of elements.
 *   
 *  \param arr (UIAElementArray or Array) - the elements that need to be sorted
 *               
 *  \return The sorted elements.
 **/
UIAUtility.sortByLocation = function(arr) {
	if (arr instanceof UIAElementArray) arr = arr.toArray();
	return arr.sort(UIAUtility.compareByLocation);
}

/**
 *       Function: compareByLocation
 *           This function compares 2 UIAElements
 *   
 *  \param elem1 (UIAElement) - the first element you're comparing
 *  \param elem2 (UIAElement) - the second element you're comparing
 *               
 *  \return -1 if app1 is closer to the upper left corner
 *  \return 1 if app2 is closer to the upper left corner
 *  \return The closeness is first determined by the y distance, 
 *  \return and in case they are the same then the x distance is used.
 **/
UIAUtility.compareByLocation = function elementLocationComparison(elem1, elem2) {
	var smaller = 0;
	
	var deltaX1 = Math.abs(elem1.rect().origin.x);
	var deltaX2 = Math.abs(elem2.rect().origin.x);
	var deltaY1 = Math.abs(elem1.rect().origin.y);
	var deltaY2 = Math.abs(elem2.rect().origin.y);
	
	if (deltaX1 <= deltaX2) {
		//elem1 is closer (or equidistant) to the point horizontally than elem2
		if (deltaY1 > deltaY2) 
			smaller = 1; //elem2 is closer to the point vertically than elem1
		else
			smaller = -1; //elem1 is closer (or equidistant) to the point vertically than elem2
	}
	else {
		//elem2 is closer to the point horizontally than elem1
		if (deltaY1 >= deltaY2)
			smaller = 1; //elem2 is closer (or equidistant) to the point vertically than elem1
		else
			smaller = -1; //elem1 is closer to the point vertically than elem2
	}
	
	return smaller;
}

/**
 *       Function: addVerificationStringForSiriTimeConfusion
 *           This function parses the arguments for the Siri test, searching for a "ambiguousHourRange" argument. If it finds it, it parses the string to check the time constraints during which Siri might behave differently, and adds the provided verification string to the list of acceptable speech identifiers.
 *  \param verificationStringArray (array) - list of verificationStrings to add the new one too.
 *  \param arguments (array) - list of arguments passed to the Siri test
 *
 *  \return true if we find the "ambiguousHourRange" argument. False otherwise
 *
 **/
UIAUtility.addVerificationStringForSiriTimeConfusion =
function addVerificationStringForSiriTimeConfusion(verificationStringArray, arguments) {
	
	var date = new Date();
	
	// Get the current hour, ranging (0-23). ex: if the time is 3:40PM the value would be 15
	var currentHour = date.getHours();

	UIALogger.logMessage("Current hour in which test is running: " + currentHour);
	
	// Check for a provided "ambiguousHourRange" argument. If this argument is provided then we suspect Siri might be confused about what we mean by "today", "tomorrow" or a certain time.
	// Here are a couple of examples:
	// Example A: We're giving a command that involves performing some action tomorrow. The term "tomorrow" confuses Siri whenever the test is running past midnight, so it asks for clarification whether we meant tomorrow as in "today" since it's past midnight or the next day. This clarification is in the form of asking the user to pick a date.
	
	// Example B: We ask Siri about an event time (reminder, calendar appointment, etc..) that is around the time we ask that question. Ex: At 6:05pm we ask Siri if we have any meetings, while we have one at 6pm. In this case, Siri currently ignores the 6pm meeting (since it's in the past as far as it's concerned) and checks for meetings later.

	// For both of these cases we have no choice but to acknowledge the response and pass the test. The argument defined in the ptest should be in the format "ambiguousHourRange:[fromTime]-[toTime],[verificationStringToHaveTheTestAcceptIncaseOfDateConfusion]".
	
	// So for example, if we have a device with a meeting scheduled at 6pm, and have a test that asks Siri if we have any meetings but that test might run between midnight and 4am, the following argument should be passed: ambiguousHourRange:0-4,Common#disambiguateRelativeDateInWitchingHour.
	// This will have our test check if we're running between 12am and 4am. If we are then add the verification string to our list of passing strings and count this as a pass.
	
	for (var i=1; i < arguments.length; i++) {
		
		// If we find a string matching "ambiguousHourRange", then start parsing the string to get the time windows and verification string out of it.
		// DISCLAIMER: this assumes the string matches the format we expect
		if (arguments[i].indexOf("ambiguousHourRange:") >= 0) {
			UIALogger.logMessage("Found 'ambiguousHourRange' in args. Parsing value for time window and verification string");
			var splittingIndex = arguments[i].indexOf(":");
			
			// Get the string to parse values out of.
			// Ex: argumentValueToSplit would be 0-4,Common#disambiguateRelativeDateInWitchingHour
			var argumentValueToSplit = arguments[i].substr(splittingIndex + 1);
			
			// Value of timeWindowString would be 0-4
			var timeWindowString = argumentValueToSplit.substr(0, argumentValueToSplit.indexOf(","))
			UIALogger.logMessage("Time string to parse: " + timeWindowString);
			
			
			var timeFrom = timeWindowString.substr(0, timeWindowString.indexOf("-"));
			UIALogger.logMessage("Hour window start: " + timeFrom);
			var timeTo = timeWindowString.substr(timeWindowString.indexOf("-") + 1);
				
			UIALogger.logMessage("Hour window end: " + timeTo);
			
			// Value of disambiguationVerficationString would be Common#disambiguateRelativeDateInWitchingHour
			var disambiguationVerficationString = argumentValueToSplit.substr(argumentValueToSplit.indexOf(",") + 1);
			
			if (currentHour >= timeFrom && currentHour <= timeTo) {
				UIALogger.logWarning("The test is running in a time window where Siri might be confused about time. Adding " + disambiguationVerficationString + " to verfication strings. The test now might pass even though Siri doesn't full perform the action requested!");
			
				if (!verificationStringArray) {
					
					verificationStringArray = new Array();
				}
				
				verificationStringArray.push(disambiguationVerficationString);
				return true;
			}
		}
	}
	
	return false;
}

/**
 *       Function: _roundMinutes( minutes ) - round minutes to nearest 5 minutes to use when scrolling through
 *                                       minutes picker when adding an event start and end time in mobile calendar
 *                                   
 *   
 *  \param minutes ( integer ) - minutes to scroll the picker
 *   
 *  \return ( String ) - value from 00-55 in 5 minute increments
 **/
UIAUtility.roundMinutes = function _roundMinutes( minutes ) {
		var roundedMinutes = ( minutes % 5 >= 3 ) ? minutes + ( 5 - ( minutes % 5 ) ) : minutes - ( minutes % 5 ) ;
		if ( roundedMinutes < 10 ) roundedMinutes = "0" + roundedMinutes;
		if ( roundedMinutes > 55 ) roundedMinutes = '00';
		return roundedMinutes;
}

/**
 *       Function: _convertHours( hour ) - convert hour in 0-23 format returned from Date object to 1-12 to use 
 *                                   when scrolling through the hour picker when adding an event start 
 *                                   and end time in mobile calendar
 *   
 *  \param hour ( integer )
 *   
 *  \return ( integer ) - value from 1-12
 **/
UIAUtility.convertHours = function _convertHours( hour ) {
	
		return ( hour % 12 ) ? hour % 12 : 12;
	
}

/**
 *       Fucntion: convertMonth
 *           Utility function that takes a month represented by integer,
 *			 and returns the string equivalent.
 *
 *	\param month (number): Month number - usually caller passes in the returned value from date.getMonth()
 *  \return  string
 **/
UIAUtility._convertMonth = function _convertMonth( month ) {
    var months = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];
    return months[ month ];
}

/**
 *       Fucntion: convertMonth
 *           Utility function that takes a month represented by integer,
 *			 and returns the string (long version) equivalent.
 *
 *	\param month (number): Month number - usually caller passes in the returned value from date.getMonth()
 *  \return  string
 **/
UIAUtility.convertMonthFull = function _convertMonth( month ) {
    var months = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];
    return months[ month ];
}

/**
 *       Function: selectDateUsingPicker
 *           This function selects a date/time on the specified UIAPicker element. 
 *			 This can be called by any test that needs to choose a date/time using a picker 
 *			 (ex: Choosing a date when creating a new Calendar event, or Reminder).
 *   
 *  \param date (UIADate) - date to choose in the picker
 *  \param pickerUIElement (UIAPicker) - Picker element containing wheels for months, days, hours, etc..
 *	\param scrollUp			(bool) - 1: scroll up the wheel when choosing date; 0 otherwise
 *  \return escaped string
 **/
UIAUtility.selectDateUsingPicker = function selectDateUsingPicker(date, pickerUIElement, scrollUP) {
	var dateArray = [];
	var dayEnum = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
	var day;
	var today = (date instanceof UIADate) ? new UIADate() : new Date();
	
	// Setup the Day string to contain both month and day to match the choices in the picker wheel.
	// Example: "Fri Sep 28" or "Today"
	if (today.getMonth() == date.getMonth() && today.getDate() == date.getDate()) {
		day = "Today";
	} else {
		day = this._convertMonth( date.getMonth() ) + " " + date.getDate() + ", " + dayEnum[date.getDay()];
	}
	
	dateArray.push(day);
	
	//Convert the date hour value (0-23 to 1-12) and push it into our array
	var hour = this.convertHours(date.getHours());
	dateArray.push(hour);
	
	//Round the minutes to the nearest interval of 5 and push it into our array
	var min = this.roundMinutes( date.getMinutes() );
	dateArray.push(min);
	
	//Figure out what if the time is PM or AM
	if (hour > 11) dateArray.push("PM");
	else dateArray.push("AM");

	try {
		// Iterate through the Picker tables and scroll them to the correct values
		for (var i = 0; i < dateArray.length - 1; i++) {
            UIALogger.logMessage("Scrolling picker wheel to " + dateArray[i]);
			UIAUtility.scrollWheelToValueWithOptions(pickerUIElement.wheels()[i], dateArray[i], {direction:scrollUP});
		} // end for loop
		
		UIALogger.logMessage("Scrolling picker wheel to " + dateArray[i]);
		if (dateArray[i] == "AM" && pickerUIElement.wheels()[i].value() != "AM") {
			UIAUtility.scrollWheelToValueWithOptions(pickerUIElement.wheels()[i], dateArray[i], {direction:0});
		} else if (dateArray[i] == "PM" && pickerUIElement.wheels()[i].value() != "PM") {
			UIAUtility.scrollWheelToValueWithOptions(pickerUIElement.wheels()[i], dateArray[i], {direction:1});
		}
	} catch (e) {
		UIALogger.logError(e.message);
		throw new Error("Could not scroll picker wheels to select date and time");
	}
}



/**
 *  Throws exception if expression evaluates to false
 *   
 *  @tparam string expression - expression to evaluate
 *  @tparam string message - error message if thrown
 *  @tparem object info - additional info to pass to the Error constructor (used by VerboseError)
 **/
UIAUtility.assert = function assert(expression, message, info) {

    if (expression) return;
    if (!message) message = "Assert failed";
    throw new Error(message, info);
    
}

/**
 *  Throws exception if value1 is not equal to value2
 *   
 *  @tparam string value1 - one of two values to compare
 *  @tparam string value2 - the other value
 *  @tparam string message - error message if thrown
 *  @tparem object info - additional info to pass to the Error constructor (used by VerboseError)
 **/
UIAUtility.assertEqual = function assertEqual(value1, value2, message, info) {

    if (!message) message = "Assert equal failed";
    message += ": '" + value1 + "' != '" + value2 + "'";
    if (!info) info = {};
    if (typeof info.identifier == "undefined") info.identifier = "Failed equal assertion";
    this.assert(value1 == value2, message, info);
    
}

/**
 *  Throws exception if value1 is equal to value2
 *   
 *  @tparam string value1 - one of two values to compare
 *  @tparam string value2 - the other value
 *  @tparam string message - error message if thrown
 *  @tparem object info - additional info to pass to the Error constructor (used by VerboseError)
 **/
UIAUtility.assertNotEqual = function assertNotEqual(value1, value2, message, info) {

    if (!message) message = "Assert not equal failed";
    message += ": '" + value1 + "' == '" + value2 + "'";
    if (!info) info = {};
    if (typeof info.identifier == "undefined") info.identifier = "Failed not equal assertion";
    this.assert(value1 != value2, message, info);

}

/**
 *  Throws exception if element is not valid (<UIAElement>.isValid() == false)
 *  (uses isValid not checkIsValid)
 *   
 *  @tparam string element - element to check
 *  @tparam string message - error message if thrown
 *  @tparem object info - additional info to pass to the Error constructor (used by VerboseError)
 **/
UIAUtility.assertIsValid = function assertIsValid(element, message, info) {

    if (!info) info = {};
    if (typeof info.identifier == "undefined") info.identifier = "Failed element isValid assertion";

    // check to make sure type is UIAElement or UIAElementNil before attempting to check isValid
    var wrongTypeMsg = "Element is not a UIAElement or UIAElementNil";
    if (message) wrongTypeMsg = message + ": " + wrongTypeMsg;
    this.assert((element instanceof UIAElement || element instanceof UIAElementArray || element instanceof UIAElementNil), wrongTypeMsg, info);
    
    if (!message) message = "Assert isValid failed";
    // scriptingInvocationFullExpressionString hasn't always been bridged so it might not exist for older builds
    var elementInvocation = (typeof element.scriptingInvocationFullExpressionString == "function") ? element.scriptingInvocationFullExpressionString() : "element";
    message += ": '" + elementInvocation + "' not found";
    this.assert(element.isValid(), message, info);
    
}

/**
 *  Throws exception if element does not become invalid after a timeout period (<UIAElement>.waitForInvalid() == false)
 *  (uses isValid not checkIsValid)
 *   
 *  @tparam string element - element to check
 *  @tparam string message - error message if thrown
 *  @tparem object info - additional info to pass to the Error constructor (used by VerboseError)
 **/
UIAUtility.assertInvalid = function assertInvalid(element, message, info) {

    if (!info) info = {};
    if (typeof info.identifier == "undefined") info.identifier = "Failed element invalid assertion";

    // check to make sure type is UIAElement or UIAElementNil before attempting to check isValid
    var wrongTypeMsg = "Element is not a UIAElement or UIAElementNil";
    if (message) wrongTypeMsg = message + ": " + wrongTypeMsg;
    this.assert((element instanceof UIAElement || element instanceof UIAElementArray || element instanceof UIAElementNil), wrongTypeMsg, info);
    
    if (!message) message = "Assert invalid failed";
    // scriptingInvocationFullExpressionString hasn't always been bridged so it might not exist for older builds
    var elementInvocation = (typeof element.scriptingInvocationFullExpressionString == "function") ? element.scriptingInvocationFullExpressionString() : "element";
    message += ": '" + elementInvocation + "' found";
    this.assert(element.waitForInvalid(), message, info);
    
}

/**
 *  Throws exception if element is not visible (assertIsValid(<UIAElement>.withValueForKey(1, "isVisible")))
 *
 *  @tparam string element - element to check
 *  @tparam string message - error message if thrown
 *  @tparem object info - additional info to pass to the Error constructor (used by VerboseError)
 **/
UIAUtility.assertIsVisible = function assertIsVisible(element, message, info) {

    if (!info) info = {};
    if (typeof info.identifier == "undefined") info.identifier = "Failed element isVisible assertion";

    if (!message) message = "Assert isVisible failed";
    this.assertIsValid(element.withValueForKey(1, "isVisible"), message, info);
    
}


/**
 *  Escapes single and double quotes in a string.
 *
 *  @tparam string string - string to escape quotes
 *
 *  @treturn string - escaped string
 **/
UIAUtility.escapeQuotes = function escapeQuotes(string) {
    return string.replace(/([\"\'])/g, "\\$1");
}

/**
 *  Escapes double quotes in a string.
 *
 *  @tparam string string - string to escape quotes
 *
 *  @treturn string - escaped string
 **/
UIAUtility.escapeDoubleQuotes = function escapeDoubleQuotes(string) {
    return string.replace(/([\"])/g, "\\$1");
}

/**
 *  Escapes ICU regular expression characters, single and double quotes in a string.
 *
 *  @tparam string string - string to escape characters
 *
 *  @treturn string - escaped string
 **/
UIAUtility.escapeString = function escapeString(string) {
    return string.replace(/([\*\?\+\[\(\)\{\}\^\$\]\|\.\/\"\'\\])/g, "\\\\\\$1");
}

/**
 *  Recursively traverse (pre-order like) the tree, if it exists, to find an element
 *
 *  @tparam root - the root element of that tree to traverse
 *  @tparam predicateString - the predicate string used to match the target element
 *
 *  @treturn targetElement - the target element if found, or null if not
 **/
UIAUtility.findElementInTree = function findElementInTree(root, predicateString) {
    function _recursivelyFind(root, predicateString){
        if(root.elements().length =0 ){
            //UIALogger.logMessage("Root passed in has no children!");
            return root.withPredicate(predicateString).className() == 'UIAElementNil' ? null : root;
        }
        if(root.withPredicate(predicateString).className() == 'UIAElementNil'){
            var elements = root.elements();
            var found = null;
            for(var i =0;i<elements.length;i++){
                found = _recursivelyFind(elements[i],predicateString);
                if(found == null)
                    continue;
                else return found;
            }
            //reach here, found nothing
            return found = null;
        }
        else{
            //UIALogger.logMessage("The root element matches the predicate string");
            return root;
        }
    }
    if(root == null || root.className() == 'UIAElementNil'){
        UIALogger.logDebug("The passed in root is not valid!");
        return null;
    }
    UIALogger.logMessage("Try to find the element in the tree passed in using predicate string: "+predicateString);
    try{
        UIATarget.localTarget().pushTimeout(0);
        return _recursivelyFind(root,predicateString);
    }finally{
        UIATarget.localTarget().popTimeout();
    }
}


/** @} End of utility group */

UIAUtility.ElapsedTimeWaiter = function() {
    this.markTime = new Date();
}

UIAUtility.ElapsedTimeWaiter.prototype = {
    reset: function reset() {
        this.markTime = new Date();
    },

    elapsedSeconds: function elapsedSeconds() {
        return ((new Date()).valueOf() - this.markTime.valueOf())/1000;
    },

    logElapsedTime: function logElapsedTime() {
        UIALogger.logMessage(Math.floor(this.elapsedSeconds()).toString() + " seconds elapsed since mark")
    },

	delayUntilElapsedTime: function delayUntilElapsedTime(seconds) {
        if (seconds < 1) return;
        var elapsedSeconds = this.elapsedSeconds();
        var timeRemaining = seconds - elapsedSeconds;
        if (timeRemaining < 1) return;
        UIALogger.logMessage(Math.floor(elapsedSeconds).toString() + " seconds elapsed since mark.  Delaying for " + Math.floor(timeRemaining).toString() + " seconds.")
        target.delay(timeRemaining);
	}
}