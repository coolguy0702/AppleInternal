
/**
 * The built in string object
 * @extends String
 */

if (!String.prototype.format) {
    Object.defineProperty(String.prototype, 'format', {
        /**
         * Returns a new string replacing specific occurrences of '%' prefixed identifiers with argument data.
         *
         * - occurrences of "%%" replaced with '%'
         * - occurrences of "%<n>" with arguments[n]
         * - occurrences of "%(<key>)" with arguments[length-1][key]
         *
         * @function String#format
         * @returns {string} the reformatted string
         */
        value: function format() {
            var argv = arguments;
            var argc = argv.length;

            var last = argv[argc - 1];
            var kwargs = (argc && typeof last === 'object') ? last : null;

            return this.replace(/%([%]|[\d]+|\([^)]+\))/g, function(match) {
                var string = "";

                if (match === "%%") {
                    string = "%";
                } else if (match[1] === '(') {
                    if (!kwargs) {
                        throw new UIAError("Format key used without providing keyed arguments");
                    }

                    var key = match.slice(2, match.length - 1);
                    string = kwargs[key];
                } else {
                    var index = parseInt(match.slice(1, match.length));
                    if (isNaN(index)) {
                        string = match;
                    } else if (index < argc) {
                        string = argv[index];
                    } else {
                        throw new UIAError("Format index '" + index + "' out of range.");
                    }
                }

                if (typeof string === 'undefined') string = "";
                if (typeof string === 'object' && string instanceof Date) string = string.toISOString();
                if (typeof string !== 'string') string = JSON.stringify(string);

                return string;
            });
        },
    });
}

if (!String.prototype.contains) {
    Object.defineProperty(String.prototype, 'contains', {
        /**
         * Return true if string contains substring otherwise false
         *
         * @function String#contains
         * @param {string} string to look for in the string
         * @returns {bool}
         **/
        value: function contains(x) {
            return this.indexOf(x) !== -1;
        },
    });
}

if (!String.prototype.beginsWith) {
    Object.defineProperty(String.prototype, 'beginsWith', {
        /**
         * Return true if string starts with parameter otherwise false
         *
         * @function String#beginsWith
         * @param {string} string to look for in the string
         * @returns {bool}
         **/
        value: function beginsWith(s) {
            return this.slice(0, s.length) === s;
        },
    });
}

if (!String.prototype.startsWith) {
    Object.defineProperty(String.prototype, 'startsWith', {
        /**
         * Return true if string starts with parameter otherwise false
         *
         * @function String#beginsWith
         * @param {string} string to look for in the string
         * @returns {bool}
         **/
        value: String.prototype.beginsWith,
    });
}

if (!String.prototype.endsWith) {
    Object.defineProperty(String.prototype, 'endsWith', {
        /**
         * Return true if string ends with parameter otherwise false
         *
         * @function String#endsWith
         * @param {string} string to look for in the string
         * @returns {bool}
         **/
        value: function endsWith(s) {
            return this.slice(-s.length) === s;
        },
    });
}
