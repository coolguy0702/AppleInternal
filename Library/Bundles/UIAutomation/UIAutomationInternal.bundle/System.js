// Copied from AppScriptingScripts/libs/ as a short term workaround <rdar://problem/17022799>.
// This file will not be maintained in step with the master copy at AppScriptingScripts

// Compatibility support for legacy AS System functionality which existed in earlier versions of scripter.
// Such functionliaty never existed in Instruments and will eventuallly get removed from scripter too.

// The functions in this file should be considered deprecated and should not be used in any new scripts.
// There are UIA alternatives for most things (primarily under UIATarget) which should be used instead.

// Create a System constructor if scripter hasn't generated one
if (typeof System == 'undefined') {eval("function System() {}")}

if (typeof System.prototype.println == 'undefined') {
    System.prototype.println = function println(msg) {
        return UIALogger.logMessage(msg);
    }
}

System.prototype.isOnSimulator = function isOnSimulator() {
    return (UIATarget.localTarget().model().match("Simulator") != null);
}

System.prototype.isOnHardware = function isOnSimulator() {
    return (UIATarget.localTarget().model().match("Simulator") == null);
}

System.prototype.getBuild = function getBuild() {
    return UIATarget.localTarget().systemBuild();
}

System.prototype.getTopDisplayID = function getTopDisplayID() {
    return UIATarget.localTarget().frontMostApp().bundleID();
}

System.prototype.sleep = function sleep(seconds) {
    UIATarget.localTarget().delay(seconds);
}

// DEPRECATED:  Use UIATarget.localTarget().mobileGestaltQuery(<key>) in place of this
System.prototype.queryLockdown = function queryLockdown(domain, key) {
    if (this.isOnSimulator()) {
        return null;
    } else {
        if (!domain) domain = "NULL";
        var lockdownCommand = "/usr/local/bin/lockdown_query get " + domain + " " + key;
        var result = this.run(lockdownCommand, 5);
        var value = result.stderr.replace("\n", "");

        return value;
    }
}	

if (typeof UIATarget.localTarget().hasCapability != 'undefined') {
    System.prototype.hasCapability = function hasCapability(capability) {
        return UIATarget.localTarget().hasCapability(capability);
    }
}

if (typeof UIATarget.localTarget().isLocked != 'undefined') {
    System.prototype.isScreenLocked = function isScreenLocked() {
        return UIATarget.localTarget().isLocked();
    }
}

// replaces the system.run implementation of Scripter/System.m, Scripter/ShellCommand.m
// with a performTaskWithPathArgumentsTimeout implementation.  For backward compatability
// this implementation attempts to recreate the original command parsing.
if (typeof UIATarget.localTarget().performTaskWithPathArgumentsTimeout != 'undefined') {
    System.prototype.run = function run(command, timeout) {
        if (typeof timeout == 'undefined') {
			UIALogger.logWarning("A timeout was not specified so the call will use Number.MAX_VALUE.");
            timeout = Number.MAX_VALUE;
        }
        var components = [];
        
        var startingIndex = 0;
        
        while (startingIndex < command.length) {
            var argumentRange = {location:startingIndex, length:(command.length - startingIndex)};
            var searchRange = {location:(argumentRange.location + 1), length:(argumentRange.length - 1)};
            var matchLocation = -1;

            if (command.charAt(startingIndex) == '"') {
                // if the first character in the search range is a double quote, the argument length should be up until the next quote
                argumentRange.location++; argumentRange.length--; // don't include the open quote
                matchLocation = command.substr(searchRange.location, searchRange.length).indexOf("\"");
            } else if (command.charAt(startingIndex) == '\'') {
                // if the first character in the search range is a single quote, the argument length should be up until the next quote
                argumentRange.location++; argumentRange.length--;// don't include the open quote
                matchLocation = command.substr(searchRange.location, searchRange.length).indexOf("'");
            } else {
                // if the first character in the search range is not a quote, the argument length should be up until the next space
                matchLocation = command.substr(searchRange.location, searchRange.length).search(/\s/);
            }

            if (matchLocation != -1) {
                argumentRange.length = searchRange.location + matchLocation - argumentRange.location;
                components.push(command.substr(argumentRange.location, argumentRange.length));
            } else {
                components.push(command.substr(argumentRange.location, argumentRange.length));
                break;
            }

            // start the next argument at the next non-whitespace
            searchRange.location = searchRange.location + matchLocation + 1;
            searchRange.length = command.length - searchRange.location;
            matchLocation = command.substr(searchRange.location, searchRange.length).search(/\S/);  // non whitespace
            startingIndex = (matchLocation != -1) ? searchRange.location + matchLocation : command.length;
        }
        
        var path = components.shift();
        var arguments = components;
        var result = UIATarget.localTarget().performTaskWithPathArgumentsTimeout(path, arguments, timeout);
        
        return result;
    }
}

	System.prototype.deviceClass = UIATarget.localTarget().mobileGestaltQuery("DeviceClass");
	System.prototype.deviceType = UIATarget.localTarget().mobileGestaltQuery("HWModelStr");
	System.prototype.uniqueDeviceID = UIATarget.localTarget().mobileGestaltQuery("UniqueDeviceID");
	System.prototype.deviceName = UIATarget.localTarget().mobileGestaltQuery("DeviceName");
	System.prototype.serialNumber = UIATarget.localTarget().mobileGestaltQuery("SerialNumber");
	System.prototype.buildVersion = UIATarget.localTarget().mobileGestaltQuery("BuildVersion");
	System.prototype.firmwareVersion = UIATarget.localTarget().mobileGestaltQuery("FirmwareVersion");
	System.prototype.basebandVersion = (typeof UIATarget.localTarget().hasCapability != 'undefined' && UIATarget.localTarget().hasCapability('any-telephony')) ? UIATarget.localTarget().mobileGestaltQuery("BasebandFirmwareVersion") : null;

/**
 *       System.hasWiFiCapability - check to see if this device supports the WiFi capability specified
 *   
 *       Arguments:
 *           (string) - capability - current valid options are "Aband" or "N" or "WAPI"
 *   
 *  \return Returns: true / false
 **/
	System.prototype.hasWiFiCapability = function hasWiFiCapability(capability) {
		// sanity check
		if (typeof capability != "string") {
			UIALogger.logError("WiFi feature identifier must be of type string: 'Aband', 'N', or 'WAPI'.");
			return false;
		}

		var target = UIATarget.localTarget();

		var isSupported = false;
		
		// if no capability was specified just return the value of the target wifi capability
		if (typeof capability == "undefined") return this.hasCapability('wifi');

		if (capability.toLowerCase() == "aband") {
			UIALogger.logMessage("Device type is: "+ this.deviceType);
			isSupported = !this.deviceType.match(/M68.*|N82.*|N88.*|N90.*|N92.*|N94.*|N45.*|N72.*|N18.*|N81.*/);
		} else if (capability.toLowerCase() == "n") {
			var result = this.run("/usr/local/bin/wl nmode");
			UIALogger.logMessage("Device type is: "+ this.deviceType);
			isSupported = !this.deviceType.match(/M68.*|N82.*|N88.*|N45.*|N72.*|N18.*/) && result.stdout.match(/1/);
		} else if (capability.toLowerCase() == "wapi") {
			var result = UIATarget.localTarget().mobileGestaltQuery("RegionInfo");
			UIALogger.logMessage("Device RegionInfo is: "+ result)
			isSupported = result.match(/CH\/A/)
		} else {
			UIALogger.logError("WiFi feature identifier '" + capability + "' is not valid.");
			return false;
		}

		if (isSupported) {
			UIALogger.logMessage("WiFi '" + capability + "' supported.");
			return true;
		}

		UIALogger.logMessage("WiFi '" + capability + "' not supported.");
		return false;
	}
	
/**
 *       systemPingTest - Check WiFi/3G Internet Connection using ping.
 *
 *       Arguments:
 *        ping_destination (string) - ping destination: URL or IP address;
 *               (optional-- default is www.google.com)
 *
 *       Return:
 *        1 if test succeeds, 0 if it fails.
 **/
System.prototype.pingTest = function systemPingTest(ping_destination)
{
	if(!ping_destination){
		ping_destination = "www.google.com"
	}

	var success = false;
	var searchString = "round-trip"
	for (var j=0; j<3; j=j+1) {
		output = UIAUtility.logToolOutput("/sbin/ping -t 5 " + ping_destination, 10);

		var total_output = "";
		if (output) {
			total_output = total_output + output;
			var outputList = total_output.split("\n");
			for (var i=0; i<outputList.length; i++) {
				var matchList = outputList[i].match(searchString);
					if (matchList != null) {
						//system.println(outputList[i]);
						UIALogger.logMessage("ping " + ping_destination + " pass")
						success = true;
						break;
					}

				}
		}
		if (!success){
			UIALogger.logMessage("ping " + ping_destination + " fail, try again")
		}
		else {
			break;
		}
		system.sleep(1);
	}
	if (!success) {
		var testError = "We tried to ping " + ping_destination + ", but failed";
		UIALogger.logError(testError);
		return 0;
	}

	return 1;
}

/**
 *       runPictureFrame - Locks the device, taps the picture frame button, 
 *           and lets the picture frame run for the specified amount of time. Please 
 *           note that this test only runs on iPads.
 *   
 *       Arguments:
 *           timeToShowPictureFrame (integer) - number of seconds to let the picture 
 *               frame run (optional).  If not entered, we wait for 5 seconds.
 *           passcode (string) - passcode to use. (optional)
 *   
 *       Return:
 *        throws an error if if it cannot run picture frame.
 **/
System.prototype.runPictureFrame = function runPictureFrame(timeToShowPictureFrame, passcode) {
    var target = UIATarget.localTarget();

    if (target.model() != 'iPad') {
        throw new Error("This should only run on iPads");
    }
    
    if (!timeToShowPictureFrame) timeToShowPictureFrame = 5;

    target.lock();
    target.unlockWithOptions({picture:true});

    if (!target.frontMostApp().mainWindow().elements()["Slideshow photo"].isValid()) {
        target.unlockWithOptions({passcode:passcode});
        throw new Error("Tapped the slideshow button, but no photo came up");
    }

    UIALogger.logMessage("Successfully verified that transition into photo frame was done. Now, sleeping for " + timeToShowPictureFrame + " seconds.");

    target.delay(timeToShowPictureFrame);
    target.clickMenu();

    try {
        target.frontMostApp().mainWindow().elements()["LockBar"].buttons()["Picture frame"].tap();
    } catch (e) {
        throw new Error("Failed to tap the slideshow button to turn it off. " + e);
    }

    if (!target.unlockWithOptions({passcode:passcode})) {
        throw new Error("Could not unlock after playing the slideshow");
    }

    return;
}

// generate a system global
try {
if (typeof system == 'undefined') system = new System();	
} catch (e) {
	UIALogger.logMessage("Couldn't create the system object. This is expected if you're running from the Instrument.");
}
