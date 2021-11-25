// Copied from AppScriptingScripts/libs/ as a short term workaround <rdar://problem/17022799>.
// This file will not be maintained in step with the master copy at AppScriptingScripts
// There are some slight logging modifications

load("System.js");
load("UIAUtility.js");

var UIATesting = {
}

UIATesting.TEST_RESULT_PASS = 1;
UIATesting.TEST_RESULT_FAIL = 0;

// use this to add a function that needs to be executed before each test completes
UIATesting.registerPreTestHandler = function registerPreTestHandler(handler) {
	if (typeof UIATesting._preTestHandlers == 'undefined') UIATesting._preTestHandlers = new Array();
	UIATesting._preTestHandlers.push(handler);
}

// use this to add a function that needs to be executed after each test completes
UIATesting.registerPostTestHandler = function registerPostTestHandler(handler) {
	if (typeof UIATesting._postTestHandlers == 'undefined') UIATesting._postTestHandlers = new Array();
	UIATesting._postTestHandlers.push(handler);
}

/**
 *       Function: UIATesting.list 
 *           Logs the test names and descriptions for an array or hash of tests
 *   
 *  \param tests (array, object or test) - the container object of tests to list
 *   
 *  \return nothing
 **/

UIATesting.list = function list(object) {
	if (object instanceof UIATesting.Test) system.println(object.name + ": " + object._main.name + " (" + object.description + ")");
	else if (test instanceof Object) {
		for (index in object) {
			UIATesting.list(object[index]);
		}		
	}
}

/**
 *       Function: UIATesting.Task 
 *           The constructor for a task object. 
 *   
 *           UIATesting.Task is the base class for most of the classes defined in UIATesting.
 *           The class represents any executable task. The task can be executed by calling 
 *           run() or execute(). 
 *   
 *  \param main (function or object) - the function that performs the intended task, 
 *               or a dictionary object containing the main function (as the value of the 
 *               "main" key) and the object on which the function should be applied (as the 
 *               value of the "callingObject"). The dictionary value is useful when the 
 *               function should be applied to a different object (by default, the function
 *               is applied to the task object). For e.g to use the maps.search function as 
 *               the main function, the following expression should be used:
 *                   var mapsSearchTask = new UIATesting.Task({callingObject:maps, main:maps.search}, ["Boston"])
 *  \param argv (array) - the arguments to the main function
 *   
 *  \return nothing
 **/

UIATesting.Task = function(main, argv) {
	var callingObject = this;	
	if (!(arguments[0] instanceof Function)) {
		if (arguments[0].callingObject != undefined) {
			callingObject = arguments[0].callingObject;
			main = arguments[0].main;
		} else if (arguments.length == 1) {
			//this will only be used if UIATesting.createTaskSubtype is used to UIATesting.Task as parent class
			main = arguments[0].main;
			argv = arguments[0].argv;
		}
	}
	
	if (!main  || typeof main == 'undefined') {
		throw new Error("No main function specified for this task.");
	}	

	this._main = main; // implements a single iteration of a test/task
	this._callingObject = callingObject; //the calling object 
	
	this.argv = argv;
	this.setup = new Array(); // tasks that are used to setup for the iterations of a test
	this.teardown = new Array(); // tasks that is used to do post processing or cleanup after all test iterations
}

UIATesting.Task.prototype = {
	_performTasks: function _performTasks(tasks) {
		if (!(tasks instanceof Array)) return;
		
		for (index in tasks) {
			var task = tasks[index];
			if (task instanceof UIATesting.Task) task.execute();
			else if (typeof task == 'function') task.apply(this);
		}
	},
	
	execute: function execute() {
		this._performTasks(this.setup);
        if (this.argv instanceof Array) {
            // called as array
            this.testResult = this._main.apply(this._callingObject, this.argv);
        } else {
            // called as associative array (allows for keyed implementation)
            this.testResult = this._main.call(this._callingObject, this.argv);
        }
		this._performTasks(this.teardown);
//		if (typeof system != 'undefined') system.drain(); // no drain function in public functionality
	},
	
	run: function run() {
		if (typeof UIATesting._preTestHandlers == 'object') {
			for (index in UIATesting._preTestHandlers) {
				// call handler function as a method of the task object
				UIATesting._preTestHandlers[index].call(this);
			}
		}
		this.execute();
		if (typeof UIATesting._postTestHandlers == 'object') {
			for (index in UIATesting._postTestHandlers) {
				// call handler function as a method of the task object
				UIATesting._postTestHandlers[index].call(this);
			}
		}
	}
}

/**
 *       Function: UIATesting.createTaskSubtype
 *           A convenience function for creating subclass of UIATesting.Task (and 
 *           its subclasses)
 *           
 *  \param properties (object) - an dictionary object containing the key/value pairs that 
 *               will be associated with all the instances of the class
 *  \param parent (array) - the parent class. If no value is specified, UIATesting.Task
 *               is used.
 *  \param Example:
 *           UIATesting.createTaskSubtype({main:settings.setWiFi}, UIATesting.Task)
 *           will create a subclass with the main function set to settings.setWiFi. 
 *   
 *  \return A constructor function for a subclass of the specified parent type
 **/
UIATesting.createTaskSubtype = function createTaskSubtype(properties, parent) {
	if (!parent) parent = UIATesting.Task;
	var _tempClass = function() {
		for (var key in properties)
			this[key] = properties[key];
	}
	_tempClass.prototype.__proto__ = new parent(properties);
	
	return _tempClass;
}

/**
 *       Function: UIATesting.Test 
 *           The constructor for a test object. 
 *   
 *           UIATesting.Test is a subclass of a UITesting.Task class. The class represents 
 *           an executable test. The test can be run by calling run() or execute() on the 
 *           object. The test result is stored in the testResult property of the object. 
 *   
 *  \param name (string) - an identifier for the test
 *  \param argv (array) - the arguments to the main function
 *  \param main (function) - the function that performs the intended test
 *  \param description (string) - a description of the test
 *   
 *  \return UIATesting.Test object
 **/
UIATesting.Test = function(name, argv, main, description) {
	
	//this will only be used if UIATesting.createTaskSubtype is used to UIATesting.Test as parent class
	if (arguments.length == 1 && arguments[0] instanceof Object) {
		var properties = arguments[0];
		name = properties.name;
		description = properties.description;
		main = properties.main;
		argv = properties.argv;
	}
	
	if (!name || typeof name == 'undefined') {
		throw new Error("No name specified for this test.");
	}
	
	UIATesting.Task.apply(this, [main, argv]);
	this.name = name;
	this.description = (null == description) ? "" : description;

	this.cleanup = new Array(); // tasks that are used to cleanup between iterations of the test
}

UIATesting.Test.prototype = {
	_executeIteration: function _executeIteration() {
		try {
            if (this.argv instanceof Array) {
                // called as array
                this.testResult = this._main.apply(this, this.argv);
            } else {
                // called as associative array (allows for keyed implementation)
                this.testResult = this._main.call(this, this.argv);
            }
			if (typeof this._cleanup != 'undefined' && this._cleanup instanceof UIATesting.Task) 
			{
				UIATesting._performTasks(this._cleanup);
			}
		}		
		catch (e) {
			this._onException(e);
		}
	},
	
	execute: function execute() {
		if (typeof this.currentRun == 'undefined') this.currentRun = 0;
		if (typeof this.numberOfRuns == 'undefined') this.numberOfRuns = 1;

		this.testError = "";

		this.startTime = new Date();
		
		try {
			this._performTasks(this.setup);
		} catch(e) {
			this._onException(e, {prefixString:"Failed test setup"});
			this._report();
			return ;
		}

		for (; this.currentRun < this.numberOfRuns; this.currentRun++)
		{
			startMessageOptions = {message:this.name, testName:this.name};
			if (this._main) startMessageOptions.testMainFunctionName = this._main.name;
			UIALogger.logStart("Test Function: " + this.name);
			this._executeIteration();
			if (this.currentRun == (this.numberOfRuns-1)) {
				try {
					this._performTasks(this.teardown);
				} catch(e) {
					this._onException(e, {prefixString:"Failed test teardown"});
				}
			}
			this._report();
		}
//		if (typeof system != 'undefined') system.drain(); // no drain function in public functionality
	},
	
	_onException: function onException(e, options) {
		var prefixString = "Uncaught exception";
		if (options && options.prefixString) prefixString = options.prefixString;
		
		var errorString = "(" + prefixString + ": '" + ((typeof e.message != 'undefined') ? e.message : String(e)) + "')";
		e.message = errorString;
		if (this.testError == 'undefined' || this.testError == "") this.testError = e;
		this.testResult = UIATesting.TEST_RESULT_FAIL;
	},

	_report: function report() {
		var resultInfo = {testDescription:this.description, testError: this.testError, testName: this.name, 
			testIteration: this.currentRun, testStartTime:this.startTime};
		if (this._main) resultInfo.testMainFunctionName = this._main.name;
		if (this.testResult == UIATesting.TEST_RESULT_FAIL) {
			if (this.testError && typeof this.testError == "string") UIALogger.logError(this.testError);
			resultInfo.type = UIALogger.UIA_LOG_TYPE_FAIL;
			resultInfo.message = "Test Function: " + this.name + " ('" + ((typeof this.testError.message != 'undefined') ? this.testError.message : this.testError) + "')";
			resultInfo.testError = this.testError;
			UIALogger.logFail(resultInfo.message);
		} else {
			resultInfo.message = "Test Function: " + this.name;
			UIALogger.logPass(resultInfo.message);
		}	
	}
}

UIATesting.Test.prototype.__proto__ = UIATesting.Task.prototype;

/**
 *       Function: UIATesting.MultiTest 
 *           The constructor for a multi-test object. 
 *   
 *           UIATesting.MultiTest is a subclass of a UITesting.Test class. A multi-test 
 *           object represents a collection of tests that are run as one test i.e. 
 *           executing the multi-test runs the tests in the collection one-by-one, and the 
 *           multi-test passes if all the tests pass, and it fails if any of the tests 
 *           fail. 
 *   
 *  \param name (string) - an identifier for the multi test
 *  \param tests (array of UIATesting.Test objects) - the collection of tests
 *  \param description (string) - a description of the multi test
 *   
 *  \return UIATesting.Test object
 **/
UIATesting.MultiTest = function(name, tests, description) {
	
	//this will only be used if UIATesting.createTaskSubtype is used to UIATesting.MultiTest as parent class
	if (arguments.length == 1 && arguments[0] instanceof Object) {
		var properties = arguments[0];
		name = properties.name;
		description = properties.description;
		tests = properties.tests;
	}
	
	if (!tests || !(tests instanceof Array)) {
		throw new Error("No tests specified for multi test.");
	}
	
	if (!name || typeof name == 'undefined') {
		throw new Error("No name specified for this test.");
	}
	this.name = name;
	this.tests = tests;
	this.description = (null == this.description) ? "" : description;
	this.setup = new Array();
	this.teardown = new Array();
}

UIATesting.MultiTest.prototype = {
	_executeIteration: function _executeIteration() {
		UIALogger.logStart(this.name);
		try {
			for (index in this.tests) {				
				var test = this.tests[index];
				test.execute();
				this.testResult = test.testResult;
				if (this.testResult == UIATesting.TEST_RESULT_FAIL) {
					this.testError = test.testError;
					break;
				}
			}
		}
		
		catch (e) {
			this._onException(e);
		}
	}	
}

UIATesting.MultiTest.prototype.__proto__ = UIATesting.Test.prototype;

/**
 *       Function: UIATesting.TestDependency 
 *           The constructor for a test dependency object. 
 *   
 *           UIATesting.TestDependency is a subclass of a UITesting.Task class. A test 
 *           dependency object can be used to check if dependencies are satisfied during 
 *           setup process of a test/task. Calling execute() on the test dependency object 
 *           will return true or false based on whether the dependency condition was 
 *           satisfied or not. 
 *   
 *  \param main (function) - a function that returns true or false based on whether the 
 *               dependency condition was satisfied or not. 
 *  \param options (object) - a dictionary object of optional arguments
 *   
 *  \param Optional Paramters:
 *           failureMessage (string) - a failure message that will be used to create the 
 *               error object if the dependency condition was not satisfied
 *   
 *  \return UIATesting.TestDependency object
 **/
UIATesting.TestDependency = function (main, options) {
	
	if (arguments.length == 1 && arguments[0] instanceof Object) {
		var properties = arguments[0];
		main = properties.main;
		options = properties.options;
	}
	
	this._main = main;
	if (options == undefined) options = new Object();
	
	if (options.failureMessage) {
		this.failureMessage = options.failureMessage;
	}
}
UIATesting.TestDependency.prototype = {	
	execute: function execute() {
		var result = this._main();
		var errorMessage = this.failureMessage;
		if (errorMessage == undefined) errorMessage = "Failed Dependency Condition";
		if (result == false) throw new Error(errorMessage);
//		if (typeof system != 'undefined') system.drain();  // no drain function in public functionality
	}
}

UIATesting.TestDependency.prototype.__proto__ = UIATesting.Task.prototype;

/**
 *       Function: UIATesting.TestCollection 
 *           The constructor for a test collection object. 
 *   
 *           UIATesting.TestCollection is a subclass of a UITesting.Task class. A test 
 *           collection object represents a collection of tests. Calling execute() on the 
 *           test collection object runs the tests in the collection one at a time. 
 *   
 *  \param name (string) - an identifier for the collection
 *   
 *  \return UIATesting.TestCollection object
 **/
UIATesting.TestCollection = function(name) {
	if (arguments.length == 1 && arguments[0] instanceof Object) {
		var properties = arguments[0];
		name = properties.name;
	}
	this.name = name;
	
	this.setup = new Array();
	this.teardown = new Array();
}
UIATesting.TestCollection.prototype = {	
	_performTasks: function _performTasks(tasks) {
		if (!(tasks instanceof Array)) return;
		
		for (index in tasks) {
			var task = tasks[index];
			try {
				if (task instanceof UIATesting.Task) task.execute();
				else if (typeof task == 'function') task();
			} catch(e) {
				UIALogger.logError("Failed to perform task: " + e);
			}
		}
	},
	execute: function execute() {
		this._performTasks(this.setup);
		
		for (var key in this) {
			if (this[key] instanceof UIATesting.Task) 
				this[key].run();
		}
		
		this._performTasks(this.teardown);
	}
}
UIATesting.TestCollection.prototype.__proto__ = UIATesting.Task.prototype;

var UIAFileManagement = {
}

/**
 *       Function: UIAFileManagement.escapePath 
 *           Escape space characters in path names
 *   
 *  \param path (string) - a path name to be used to create files or directories
 *   
 *  \return UNIX safe path
 **/

UIAFileManagement.escapePath = function escapePath(path) {
	var finalPath = path.replace(' ', '/ ');
	return finalPath;
}

/**
 *       Function: UIAFileManagement.makeSafePath
 *           Escape space characters in path names
 *   
 *  \param path (string) - a path name to be used to create files or directories
 *   
 *  \return UNIX safe path
 **/

UIAFileManagement.makeSafePath = function makeSafePath(path) {
	var finalPath = path.replace(' ', '/ ');
	return finalPath;
}


/**
 *       Function: UIAFileManagement.makeDirectory 
 *           Creates the given directory on the system.
 *   
 *  \param directory (string) - full path to the directory that needs to be created.
 *   
 *  \return None
 **/
UIAFileManagement.makeDirectory = function makeDirectory(directory) {
	directory = UIAFileManagement.makeSafePath(directory);
	system.run("/sbin/mount -uw /", 5);
	var mkdirCmd = "/bin/mkdir " + directory;
	system.run(mkdirCmd, 5);
}

/**
 *       Function: UIAFileManagement.removeFile
 *           Removes a file.
 *   
 *  \param filepath (string) - full path to the file that is to be removed.
 *   
 *  \return None
 **/
UIAFileManagement.removeFile = function removeFile(filepath) {
	var removeReportCMD = "/bin/rm -rf " + UIAFileManagement.makeSafePath(filepath);
	system.run(removeReportCMD, 5);
}

/**
 *       Function: UIAFileManagement.removeDirectory 
 *           Removed the given directory on the system.
 *   
 *  \param directory (string) - full path to the directory that needs to be created.
 *   
 *  \return None
 **/
UIAFileManagement.removeDirectory = function removeDirectory(directory) {
	directory = UIAFileManagement.makeSafePath(directory);
	system.run("/sbin/mount -uw /", 5);
	var rmCmd = "/bin/rm -Rf " + directory;
	system.run(rmCmd, 5);
}

var UIATestingUtilities = {
}

/**
 *       Function: UIATestingUtilities.crashLogPathsFromSysLog
 *           Performs a query for crash logs on syslog
 *   
 *  \param elapsedTimeToCheck (number) - how many millisec of the syslog output to check
 *   
 *  \return An array of paths to any crashlogs that have been reported.  If path
 *  \return cannot be identified, it will send the crash message.  In the case of 
 *  \return baseband crashes, it just sends "Baseband: <reason>"
 **/
UIATestingUtilities.crashLogPathsFromSysLog = function crashLogPathsFromSysLog(elapsedTimeToCheck) {
	var crashLogList = new Array();
	var basebandLogList = new Array();
	var basebandCrashSearchString = "CSI state dump requested";
	
	// Log the baseband crashes--reason for the crash should be after the basebandCrashSearchString (above)
	// was: "/usr/bin/syslog -k Sender DumpBasebandCrash -k Time ge -" 	
	var basebandOutput = UIAUtility.logToolOutput("/usr/bin/syslog -k Sender CommCenter -k Level Nle 5 -k Time ge -" + Math.floor(elapsedTimeToCheck/1000), 60);	
	if (basebandOutput) {
		var basebandLogList = basebandOutput.split("\n"); 
		for (var i=0; i<basebandLogList.length; i++) {
			system.println("BasebandLogList[" + i + "] = " + basebandLogList[i]);
			var startIndex = basebandLogList[i].indexOf(basebandCrashSearchString);
			if (startIndex < 0) {
				continue; // does not contain crash info
			}
			else {
				var reasonIndex = startIndex + basebandCrashSearchString.length + 2;
				var reason = basebandLogList[i].slice(reasonIndex);
				crashLogList.push("Baseband: " + reason);
			}
		}
	}
	
	// Add the non-Baseband crashes (found by ReportCrash) to the array
	var logOutput;
	logOutput = UIAUtility.logToolOutput("/usr/bin/syslog -k Sender ReportCrash -k Level Nle 3 -k Time ge -" + Math.floor(elapsedTimeToCheck/1000), 60);
	if (logOutput != "") {
		var crashLogPrefix = "Saved crashreport to ";
		var newCrashList = logOutput.split("\n");
		if (newCrashList.length > 40) {
			// We had a whole, whole bunch of "crashes" which probably means we're actually putting the 
			// 	whole crash log inline.  (This can happen if we max out the number of crashes we can have--i.e. 100)
			//  In this case, we'll just print the first line and then exit.
			crashLogList.push("Too much output to report.  Probably have max number of crashes -- first line is: " + newCrashList[0]);
		}
		else {
			for (var i = 0; i < newCrashList.length; i++) {
				if (newCrashList[i] == "") continue;  // skip empty lines
				if (newCrashList[i].indexOf("--- last message repeated") > -1) {
					// Do not report these, because they seem to be wrong...
					continue;
				}
				var startIndex = newCrashList[i].indexOf(crashLogPrefix);
				if (startIndex == -1) {
					// non-standard crash report -- put it in the array
					crashLogList.push(newCrashList[i]);
				}
				else if (newCrashList[i].indexOf("LowMemory-") > -1) {
					// Low memory warning--don't do anything with these "crashes" 
				}
				else {
					// standard crash report -- put just the path in the array
					newCrashList[i] = newCrashList[i].substring(startIndex + crashLogPrefix.length);
					var endIndex = newCrashList[i].indexOf(" ");
					newCrashList[i] = newCrashList[i].substring(0, endIndex);
					crashLogList.push(newCrashList[i]);  // push the modified crash on the list.
				}
			}
		}
	}
	
	return crashLogList;

}
