
/**
 * The built in array object
 * @extends Array
 */

if (!Array.prototype.contains) {
    Object.defineProperty(Array.prototype, 'contains', {
        /**
         * Return true if array contains value otherwise false
         *
         * @function Array#contains
         * @param {any} value to look for in array
         * @returns {bool}
         **/
        value: function contains(x) {
            return this.indexOf(x) !== -1;
        },
    });
}


if (!Array.prototype.unique) {
    Object.defineProperty(Array.prototype, 'unique', {
        /**
         * Removes any duplicates from an array.
         *
         * @function Array#unique
         * @param {arr} array to remove any duplicate values on
         * @returns {arr} array with only unique values
         **/
        value: function unique() {
            var seen = {};
            return this.reduce(
                function(acc, element) {
                    if (typeof seen[element] === 'undefined') {
                        acc.push(element);
                        seen[element] = true;
                    }
                    return acc;
                },
                []
            );
        }
    });
}