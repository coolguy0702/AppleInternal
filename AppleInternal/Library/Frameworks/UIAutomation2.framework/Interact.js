#!/usr/local/bin/scripter2 -VerboseOptions Unexpected -f

var target = UIATarget.localTarget();

load("Help.js");

function usage() {
	println("usage: Interact.js <keyword> [<argument> ...]");
	println("'interact' allows direct manipulation and queries of the current view\n");
	println("Optional flags to interact:");
	println("\nView information keywords:");
	println("   info [\"<query string>\"] [\"<format string>\"] print out UIA element info.");
	println("   tree [\"<query string>\"] [\"<format string>\"] print out UIA element info (indented).");
	println("   axinfo [\"<query string>\"] [\"<format string>\"] print out AX UI element info using full AX tree.");
	println("   axtree [\"<query string>\"] [\"<format string>\"] print out AX UI element info using full AX tree (indented).");
	println("      <format string> options (UIA elements only):");
	println("         %label        - element heirarchy level");
	println("         %name         - element name");
	println("         %class        - element UIAElement class");
	println("         %value        - element value");
	println("         %rect         - element rect coord");
	println("      <format string> options (UIA and AX UI element):");
	println("         %class        - kAXElementTypeAttribute (UIView or AXAccessibilityElement class)");
	println("         %label        - kAXLabelAttribute");
	println("         %value        - kAXValueAttribute");
	println("         %identifier   - kAXIdentifierAttribute");
	println("         %hint         - kAXHintAttribute");
	println("         %isVisible    - kAXIsVisibleAttribute");
	println("         %url          - kAXURLAttribute");
	println("      <query string> see UIAutomation documentation");
	println("\nView manipulation keywords:");
	println("   tap <query>\t\t\t\ttap the element returned by <query>");
	println("   tap <x>,<y>\t\t\t\ttap at the specified location using the format \"x,y\"");
	println("   drag <x1>,<y1>,<x2>,<y2>\t\tdrag from location x1,y1 to x2,y2");
	println("   flick <x1>,<y1>,<x2>,<y2>\t\tflick from location x1,y1 to x2,y2");
	println("   type <string>\t\t\ttype <string> using the keyboard");
	println("   menu\t\t\t\t\tclick the menu button");
	println("   lock \t\t\t\tlock the device if it is not already locked");
	println("   unlock \t\t\t\tunlock the device if it is not already unlocked");
	println("\nMore other:");
    println("   launch <bundleid>\t launches the App with given bundle ID if not active");
    println("   screenshot <name>\t capture a screenshot");
}

function queryForArgument(arg) {
    if (typeof arg != 'undefined') {
        return (arg.indexOf('UIAQuery') == 0) ? eval(arg) : arg;
    } else {
        return UIAQuery.application();
    }
}

function optionsForArguments(args) {
    var options = {};
    var formatString = args.shift();
    if (formatString) options.formatString = formatString;

    return options;
}

function commandForKeyword(keyword) {
    var command;

	switch (keyword) {
		case 'info':
            var query = queryForArgument(ARGV.shift());
            var options = optionsForArguments(ARGV);

            command = function() {
                return info(query, options);
            }
            break;
		case 'axinfo':
            var query = queryForArgument(ARGV.shift());
            var options = optionsForArguments(ARGV);

            command = function() {
                return axinfo(query, options);
            }
            break;
		case 'tree':
            var query = queryForArgument(ARGV.shift());
            var options = optionsForArguments(ARGV);

            command = function() {
                return tree(query, options);
            }
            break;
		case 'axtree':
            var query = queryForArgument(ARGV.shift());
            var options = optionsForArguments(ARGV);

            command = function() {
                return axtree(query, options);
            }
            break;
		case 'type':
			var text = ARGV.shift().replace(/\n/g, "\\n");
			command = function() {
                target.activeApp().typeString(text);
            }
            break;
		case 'menu':
		case 'home':
			command = function () {
                target.clickMenu();
            }
            break;
		case 'lock':
			command = function () {
                target.systemApp().lock();
            }
            break;
		case 'unlock':
			command = function () {
                target.systemApp().unlock();
            }
            break;
		case 'help':
            var arg1 = ARGV.shift();
            command = function() {
                return help(eval(arg1));
            }
            break;
		case 'launch':
			command = function() {
                app = target.appWithBundleID(ARGV.shift());
                app.launch();
            };
            break;
		case 'screenshot':
			command = function() {
                target.captureScreenWithName(ARGV.shift());
            }
            break;
		case '--help':
		case '-h':
			command = usage;
            break;
		default:
            var func = app[keyword];
            help(func);
            if (typeof func === 'function') {
                func = func.bind(app);
                command = function() {
                    func.apply(app, ARGV)
                }
            }
	}

    return command;
}

var ARGV = ARGV || [];
if (ARGV.length < 1) {
    usage();
} else {
    app = target.activeApp();

    while (ARGV.length > 0) {
        var keyword = ARGV.shift();
        var command = commandForKeyword(keyword);

        if (typeof command === 'function') {
            println("Command: %0".format(keyword));

            var result = command();
            if (typeof result != 'undefined') {
                println(String(result));
            }
        }
    }
}
