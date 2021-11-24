

(function (module) {

    _defaults = function _defaults(a, b, logResult) {
        a = a || {};
        b = b || {};
        var out = {};
        for (var key in b) {
            if (b.hasOwnProperty(key)) {
                out[key] = b[key];
            }
        }
        for (var key in a) {
            if (a.hasOwnProperty(key)) {
                out[key] = a[key];
            }
        }

        if (logResult === true) UIALogger.logDebug("Properties: " + JSON.stringify(out));

        return out;
    }

    _override = function _override(a, b, logResult) {
        a = a || {};
        b = b || {};
        var out = {};
        for (var key in a) {
            if (a.hasOwnProperty(key)) {
                out[key] = a[key];
            }
        }
        for (var key in b) {
            if (b.hasOwnProperty(key)) {
                out[key] = b[key];
            }
        }

        if (logResult === true) UIALogger.logDebug("Properties: " + JSON.stringify(out));

        return out;
    }

    /**
     *  Evaluates a query and returns a informative string about the element
     *
     * @param   {object}  query - the query to be evaluated
     * @param   {object}  options - a dictionary object of optional arguments
     * @param   {string} [options.formatString='%(rect) | %(name) | %(behavior) | %(className): %(baseClassName) | %(value) | %(isVisible)%(isSelected)%(isEnabled)'] - format string
     * @param   {object}  [options.formatArgs=[]] - additional format arguments that can be used in the format string
     * @param   {boolean}  [options.asTree=false] - if true, include decendants
     * @param   {boolean}  [options.asForest=false] - if true, include all items matching query
     * @param   {number}  [options.indentWidth=0] - the indent, in spaces to add per level in a tree printout.
     * @param   {defaults}  [options.defaults=null] - a dictionary of default values to use when the properties are null
     * @param   {defaults}  [options.application=null] - the app to target
     * @param   {function} block - function block which can be used to format properties before using them in the format string
     *
     * @returns {string} a string describing the currently displayed UI
     */
    module.info = function info(query, options, block) {
        if (typeof query == 'undefined' || query == null) query = UIAQuery.application();

        options = _defaults(options, {
            formatString: '%(rect) | %(name) | %(behavior) | %(className): %(baseClassName) | %(value) | %(isVisible)%(isSelected)%(isEnabled)',
            formatArgs: [],
            asTree: false,
            asForest: false,
            indentWidth: 0,
            defaults: null,
            application: target.activeApp(),
        }, false);

        var application = options.application;

        // build a keys array from the keywords being used in the format string
        var keys = [];
        var matches = options.formatString.match(/%(\([^)]+\))/g);
        if (matches instanceof Array) {
            keys = matches.map(function (match) {
                return match.slice(2, match.length - 1);
            });
        }

        // if true, include the children key
        if (options.asTree) {keys.push('children'); }

        if (keys.indexOf('pid') != -1 || keys.indexOf('bundleID') != -1) { keys.push('uiaxElement'); }

        if (typeof block === 'undefined') {
            block = function(_info) {
                if (typeof _info.behavior === 'undefined' || (_info.behavior.length < 1)) _info.behavior = 'Element';

                var rect = _info.rect;
                if (typeof rect !== 'undefined') {
                    var x = typeof rect.x !== 'undefined' ? rect.x.toFixed(1) : '';
                    var y = typeof rect.y !== 'undefined' ? rect.y.toFixed(1) : '';
                    var width = typeof rect.width !== 'undefined' ? rect.width.toFixed(1) : '';
                    var height = typeof rect.height !== 'undefined' ? rect.height.toFixed(1) : '';
                    _info.rect = '{x:%0, y:%1}, {w:%2, h:%3}'.format(x, y, width, height);
                }

                 var hasFocus = _info.hasFocus;
                 if (typeof hasFocus !== 'undefined') {
                    _info.hasFocus = _info.hasFocus ? '<-- FOCUS' : '';
                }

                if (keys.indexOf('pid') != -1 || keys.indexOf('bundleID') != -1) {
                    _info.pid = _info.uiaxElement.pid();
                    _info.bundleID = _info.uiaxElement.bundleIDForPID(_info.pid);
                }

                for (var key in _info) {
                    if ((key.indexOf('is') == 0) && (typeof _info[key] === 'number' || typeof _info[key] === 'boolean')) {
                        _info[key] = (_info[key]) ? ' [' + key.slice(2).toLowerCase() + ']' : '';
                    }
                }
            };
        }

        var walk = function walk(node, depth) {
            var _info = {};
            for (var keyIndex = 0; keyIndex < keys.length; keyIndex++) {
                var key = keys[keyIndex];
                var value = node[key];
                if ((typeof value == 'undefined' || value == null) && options.defaults) {
                    value = options.defaults[keys[keyIndex]];
                }
                _info[key] = value;
            }

            block(_info);

            var indentTotalWidth = depth * options.indentWidth;
            var prefix = depth.toString();
            prefix = prefix + ') ' + Array(3 - prefix.length).join(' ') + Array(indentTotalWidth).join(' ');

            var string = options.formatString.format.apply(prefix + options.formatString, options.formatArgs.concat(_info));

            if (options.asTree) {
                var children = node.children;
                if (children instanceof Array) {
                    for (var index in children) {
                        var child = children[index];
                        string += '\n' + walk(child, depth + 1);
                    }
                }
            }
            return string;
        };

        var _node, _nodes, _result = [];
        if (options.asForest) {
            _nodes = application.inspectAll(query, {keys: keys});
        } else {
            _nodes = (_node = application.inspect(query, {keys: keys})) ? [_node] : [];
        }
        for (var nodeIndex = 0; nodeIndex < _nodes.length; ++nodeIndex) {
            _result.push(walk(_nodes[nodeIndex], 0));
        }
        return _result.join('\n\n');
    }

    /**
     *  Same as info but sets asTree to true and uses an alternate formatString
     *
     * @param   {object}  query - the query to be evaluated
     * @param   {object}  options - a dictionary object of optional arguments
     * @param   {string} [options.formatString='%(behavior): %(name) %(rect)'] - format string
     * @param   {boolean}  [options.asTree=true] - if true, include decendants
     * @param   {function} block - function block which can be used to format properties before using them in the format string
     */
    module.tree = function tree(query, options, block) {
        options = _defaults(options, {
            formatString: '%(behavior): %(name) %(rect) %(hasFocus)',
            formatArgs: [],
            indentWidth: 2,
            asTree: true,
        }, false);

        return info(query, options, block);
    }

    /**
     *  Gets the tree for the application (calls tree)
     *
     * @param   {object}  query - the query to be evaluated
     * @param   {object}  options - a dictionary object of optional arguments
     * @param   {string} [options.formatString='%(behavior): %(name) %(rect)'] - format string
     * @param   {boolean}  [options.asTree=true] - if true, include decendants
     * @param   {function} block - function block which can be used to format properties before using them in the format string
     */
     UIAApp.prototype.tree = function tree(query, options, block) {
         options = _defaults(options, {
             formatString: '%(behavior): %(name) %(rect) %(hasFocus)',
             formatArgs: [],
             indentWidth: 2,
             asTree: true,
             }, false);

         options.application = this;
         return module.tree(query, options, block);
     }

    /**
     *  Same as info but sets asTree and asForest to true and uses an alternate formatString
     *
     * @param   {object}  query - the query to be evaluated
     * @param   {object}  options - a dictionary object of optional arguments
     * @param   {string} [options.formatString='%(behavior): %(name) %(rect)'] - format string
     * @param   {boolean}  [options.asTree=true] - if true, include decendants
     * @param   {boolean}  [options.asForest=true] - if true, include all matches
     * @param   {function} block - function block which can be used to format properties before using them in the format string
     */
    module.forest = function forest(query, options, block) {
        options = _defaults(options, {
            formatString: '%(behavior): %(name) %(rect)',
            formatArgs: [],
            indentWidth: 2,
            asTree: true,
            asForest: true,
        }, false);

        return info(query, options, block);
    }

    /**
     *  Same as info but uses an alternate formatString
     *
     * @param   {object}  query - the query to be evaluated
     * @param   {object}  options - a dictionary object of optional arguments
     * @param   {boolean} [options.formatString='%(className): %(baseClassName) [label: %(label) %(identifier)]'] - format string
     * @param   {function} block - function block which can be used to format properties before using them in the format string
     */
    module.axinfo = function axinfo(query, options, block) {
        options = _defaults(options, {
            formatString: '%(className): %(baseClassName) [label: %(label) | identifier: %(identifier)]',
            formatArgs: [],
        }, false);

        return info(query, options, block);
    }

    /**
     *  Same as axinfo but sets asTree to true
     *
     * @param   {object}  query - the query to be evaluated
     * @param   {object}  options - a dictionary object of optional arguments
     * @param   {boolean} [options.formatString='%(behavior): %(name) %(rect)'] - format string
     * @param   {boolean}  [options.asTree=true] - if true, include decendants
     * @param   {function} block - function block which can be used to format properties before using them in the format string
     */
    module.axtree = function axtree(query, options, block) {
        options = _defaults(options, {
            formatString: '%(className): %(baseClassName) [label: %(label) | identifier: %(identifier) | pid: %(pid) | bundleID: %(bundleID)]',
            indentWidth: 2,
        }, false);
        options.asTree = true;

        return axinfo(query, options, block);
    }

     /**
      *  Gets the axtree for the application (calls axtree)
      *
      * @param   {object}  query - the query to be evaluated
      * @param   {object}  options - a dictionary object of optional arguments
      * @param   {string} [options.formatString='%(behavior): %(name) %(rect)'] - format string
      * @param   {boolean}  [options.asTree=true] - if true, include decendants
      * @param   {function} block - function block which can be used to format properties before using them in the format string
      */
     UIAApp.prototype.axtree = function axtree(query, options, block) {
        options = _defaults(options, {
             formatString: '%(className): %(baseClassName) [label: %(label) | identifier: %(identifier) | pid: %(pid) | bundleID: %(bundleID)]',
             indentWidth: 2,
        }, false);

        options.application = this;
        return module.axtree(query, options, block);
     }

    module.locCheck = function locCheck(query, options, block) {
        if (typeof query == 'undefined' || query == null) query = UIAQuery.application();

        options = _defaults(options, {
            keys: ['label', 'controllerTitle'],
        }, false);

        var keys = options.keys;
        var moreKeys = [];
        for (var key in keys) {
            moreKeys.push(keys[key]);
            moreKeys.push(keys[key]+'_locString');
        }
        moreKeys.push('children');
        moreKeys.push('name');
        moreKeys.push('identifier');

        var info = UIATarget.localTarget().activeApp().inspect(query, {keys:moreKeys});

        var stringCount = 0;
        var locCount = 0;
        var idCount = 0;

        if (typeof block === 'undefined') {
            block = function(info) {
                var ret = '';
                var pad = Array(100).join(' ');
                for (var index in keys) {
                    var key = keys[index];
                    var string = info[key];
                    if (!string || string.length < 1) continue;

                    var loc = info[key+'_locString'];

                    if (string && string.length > 0) stringCount++;
                    if (loc && loc.length > 0) {
                        locCount++;
                    }

                    if (loc && loc.length > 0) {
                        loc = '<-- ' + loc;
                    } else {
                        var identifier = info['identifier'];
                        if (identifier && identifier.length > 0) {
                            loc = 'ID: %0'.format(identifier);
                            idCount++;
                        } else {
                            loc = '';
                        }
                    }

                    if (string.length > 39) string = string.slice(0, 36) + '...';
                    ret += '%0  %1  %2\n'.format((key + ':' + pad).slice(0, 19), (string+pad).slice(0, 39), loc);
                }
                return ret;
            };
        }

        var walk = function walk(node, depth) {
            var string = block(node);

            var children = node.children;
            if (children instanceof Array) {
                for (var index in children) {
                    var child = children[index];
                    string += walk(child, depth + 1);
                }
            }

            return string;
        };

        var pairsStr = walk(info, 0);

        var summary = 'Found %0 strings with %1 reverse localizations. %2%'.format(stringCount, locCount, ((locCount/stringCount)*100).toPrecision(3));
        var summary2 = '(%0 of the strings without reverse localizations had identifiers. %1%)'.format(idCount, (((locCount+idCount)/stringCount)*100).toPrecision(3));

        return '\n' + summary + '\n' + summary2 + '\n\n' + pairsStr;
    }

}(this));
