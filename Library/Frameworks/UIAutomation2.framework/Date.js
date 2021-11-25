
/**
 * The built in Date object
 * @extends Date
 */

if (!Date.prototype.sameDayAs) {
        /**
         * Return true if date is of the same day as another date
         *
         * @function Array#sameDayAs
         * @param {otherDate} other date to compare value to
         * @returns {bool}
         **/
    Object.defineProperty(Date.prototype, 'sameDayAs', {
        value: function sameDayAs(otherDate) {
            return this.getDate() === otherDate.getDate() && this.getMonth() === otherDate.getMonth() && this.getFullYear() === otherDate.getFullYear();
        }
    });
}