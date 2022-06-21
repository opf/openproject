let params = arguments;

// Target element to drag & drop to
let target = params[0];

// name of the hidden file input field
// must exist on the page, create if needed.
let name = params[1];

let position = params[2];

// We might want to drag the file over something, then wait a bit and drag it elsewhere
let stopover = params[3];

function dropOnTarget(dataTransfer) {
  // Look up the selector
  if (typeof target === 'string') {
    target = document.querySelector(target);
  }

  // We need coordinates to drop to the element
  let box = target.getBoundingClientRect();
  let targetX;
  let targetY;

  switch (position) {
    case 'center':
      targetX = box.left + (box.width / 2);
      targetY = box.top + (box.height / 2);
      break;
    case 'bottom':
      targetX = box.left + (box.width / 2);
      targetY = box.bottom - 1;
      break;
    default:
      throw new Error("Wrong position " + position);
  }

  ['dragenter', 'dragover', 'drop'].forEach(function (type) {
    let event = new MouseEvent(type, { clientX: targetX, clientY: targetY });

    // Override the constructor to the DragEvent class
    Object.setPrototypeOf(event, null);
    event.dataTransfer = dataTransfer;
    Object.setPrototypeOf(event, DragEvent.prototype);

    console.log("Dispatching event %O", event);
    target.dispatchEvent(event);
  });
}

let input = jQuery('<input>')
    .attr('id', name)
    .attr('name', name)
    .attr('type', 'file')
    .attr('style', 'position:fixed;left:0;bottom:0;z-index:10000')
    .appendTo(document.body)
    .on('change', function(event) {
      input.remove();
      event.stopPropagation();

      let dataTransfer = {
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

      // If we have a stopover, do that first and then get the target
      if (stopover) {
        // We need coordinates to drop to the element
        let stopbox = stopover.getBoundingClientRect();
        let stopX;
        let stopY;

        stopX = stopbox.left + (stopbox.width / 2);
        stopY = stopbox.top + (stopbox.height / 2);

        ['dragenter', 'dragover'].forEach(function (type) {
          let event = new MouseEvent(type, { clientX: stopX, clientY: stopY });

          // Override the constructor to the DragEvent class
          Object.setPrototypeOf(event, null);
          event.dataTransfer = dataTransfer;
          Object.setPrototypeOf(event, DragEvent.prototype);

          console.log("Dispatching event %O", event);
          stopover.dispatchEvent(event);
        });

        setTimeout(() => dropOnTarget(dataTransfer), 2000);
      } else {
        dropOnTarget(dataTransfer);
      }

    });
