function pageDidLoad() {
    function scrollHandler() {
        var header = document.getElementById('main-header');
        if (!header) {
            return;
        }
        
        if (header.getBoundingClientRect().top <= 0.3) {
            header.className = "header stuck";
        } else {
            header.className = "header";
        }
    }

    var chartElements = document.getElementsByClassName('svg-chart');
    Array.prototype.forEach.call(chartElements, function(el) {
        var height = el.getAttribute('height');
        var width = el.getAttribute('width');

        el.setAttribute('aspect-ratio', parseFloat(width) / parseFloat(height));
        el.setAttribute('viewBox', '0 0 ' + width + " " + height);
        el.setAttribute('perserveAspectRatio', 'xMinYMid');
    });

    function resizeHandler() {
        Array.prototype.forEach.call(chartElements, function(el) {
            var container = el.parentElement;
            var targetWidth = container.offsetWidth;
            var targetHeight = Math.round(targetWidth / parseFloat(el.getAttribute('aspect-ratio')));

            el.setAttribute('height', targetHeight);
            el.setAttribute('width', targetWidth);
        });
    }
    
    function sortTable(table, n) {
        return function() {
            var direction = true;
            var switching = true;
            var shouldSwitch = false;
            var i = 0;
            var switchcount = 0;
            
            var rows = table.rows;
            
            while (switching) {
                switching = false;
                
                for (i = 1; i < (rows.length - 1); i++) {
                    shouldSwitch = false;
                    
                    x = rows[i].getElementsByTagName("td")[n];
                    y = rows[i + 1].getElementsByTagName("td")[n];
                    
                    x = x.innerHTML.toLowerCase();
                    y = y.innerHTML.toLowerCase();
                    
                    if (!isNaN(Number(x)) && !isNaN(Number(y))) {
                        x = Number(x);
                        y = Number(y);
                    }
                    
                    if (direction) {
                        if (x > y) {
                            shouldSwitch = true;
                            break;
                        }
                    } else {
                        if (x < y) {
                            shouldSwitch = true;
                            break;
                        }
                    }
                }
                
                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
                    switchcount++;
                } else {
                    if (switchcount == 0 && direction) {
                        direction = false;
                        switching = true;
                    }
                }
            }
            
            var header = rows[0].getElementsByTagName("th");
            for (i = 0; i < header.length; i++) {
                if (i == n) {
                    if (direction) {
                        header[i].className = "sorting ascend";
                    } else {
                        header[i].className = "sorting descend";
                    }
                } else {
                    header[i].className = "";
                }
            }
            
        };
    }
    
    var tableElements = document.getElementsByTagName('table');
    Array.prototype.forEach.call(tableElements, function(el) {
        if (!el.className.includes("sortable")) {
            return;
        }
        
        var header = el.getElementsByTagName("thead")[0].getElementsByTagName("tr")[0];
        var headerElements = header.getElementsByTagName("th");
        Array.prototype.forEach.call(headerElements, function(headerItem, i) {
            headerItem.onclick = sortTable(el, i);
        });
                                 
        sortTable(el, 0)();
    });

    window.addEventListener('scroll', scrollHandler);
    window.addEventListener('resize', resizeHandler);

    scrollHandler();
    resizeHandler();
}
