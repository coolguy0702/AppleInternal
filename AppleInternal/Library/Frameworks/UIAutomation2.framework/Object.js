
/**
 * The built in Object object
 * @extends Object
 */

if (!Object.prototype.origin) {
    Object.defineProperty(Object.prototype, 'origin', {
        /**
         * Return an object containing x and y if the object has x and y fields
         *
         * @function Object#origin
         * @returns object
        **/
        get: function() {
            if (this.hasOwnProperty('x') && this.hasOwnProperty('y')) {
                UIALogger.logWarning('The origin property is deprecated and may be removed in the future - use x and y directly');
                return {x: this.x, y: this.y};
            }
        },
    });
}

if (!Object.prototype.size) {
    Object.defineProperty(Object.prototype, 'size', {
        /**
         * Return an object containing width and height if the object has width and height fields
         *
         * @function Object#size
         * @returns object
         **/
        get: function() {
            if (this.hasOwnProperty('width') && this.hasOwnProperty('height')) {
                UIALogger.logWarning('The size property is deprecated and may be removed in the future - use width and height directly');
                return {width: this.width, height: this.height};
            }
        },
    });
}