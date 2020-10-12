var params = arguments;

// Target element to drag & drop to
var target = params[0];

// name of the hidden file input field
// must exist on the page, create if needed.
var name = params[1];

// We need coordinates to drop to the element
var box = target.getBoundingClientRect();
var targetX = box.left + (box.width / 2);
var targetY = box.top + (box.height / 2);

var input = jQuery('<input>')
    .attr('id', name)
    .attr('name', name)
    .attr('type', 'file')
    .attr('style', 'position:fixed;left:0;bottom:0;z-index:10000')
    .appendTo(document.body)
    .on('change', function(event) {
      input.remove();
      event.stopPropagation();

      var dataTransfer = {
        constructor   : DataTransfer,
        effectAllowed : 'all',
        dropEffect    : 'none',
        types         : [ 'Files' ],
        files         : input[0].files,
        setData       : function setData(){},
        getData       : function getData(){},
        clearData     : function clearData(){},
        setDragImage  : function setDragImage(){}
      };

      ['dragenter', 'dragover', 'drop'].forEach(function (type) {
        var event = new MouseEvent(type, { clientX: targetX, clientY: targetY });


        // Override the constructor to the DragEvent class
        Object.setPrototypeOf(event, null);
        event.dataTransfer = dataTransfer;
        Object.setPrototypeOf(event, DragEvent.prototype);

        console.log("Dispatching event %O", event);
        target.dispatchEvent(event);
      });
    });
