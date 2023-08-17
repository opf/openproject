let params = arguments;

// Target element to drag & drop to
let target = params[0];

// name of the hidden file input field
// must exist on the page, create if needed.
let name = params[1];

let position = params[2];

// We might want to drag the file over something, then wait a bit and drag it elsewhere
let stopovers;

if (params[3] === null) {
  stopovers = [];
} else if (Array.isArray(params[3])) {
  stopovers = params[3];
} else {
  stopovers = [params[3]];
}

// Cancel the drop event
let cancelDrop = params[4];

// Delay drag leave to allow the work package tabs to become active on dragover event
let delayDragleave = params[5];

function buildDragEvent(type, targetX, targetY, dataTransfer) {
  let event = new MouseEvent(type, { clientX: targetX, clientY: targetY, bubbles: true });

  // Override the constructor to the DragEvent class
  Object.setPrototypeOf(event, null);
  event.dataTransfer = dataTransfer;
  Object.setPrototypeOf(event, DragEvent.prototype);
  return event;
}

function dropOnStopover(stopover, dataTransfer) {
  // Look up the selector
  if (typeof stopover === 'string') {
    stopover = document.querySelector(stopover);
  }

  // We need coordinates to drop to the element
  let stopbox = stopover.getBoundingClientRect();
  let stopX;
  let stopY;

  stopX = stopbox.left + (stopbox.width / 2);
  stopY = stopbox.top + (stopbox.height / 2);

  // Fire multiple drag events, to better simulate the mouse movement.
  let eventTypes = ['dragenter', 'dragover', 'dragleave']

  if (cancelDrop) {
    // Firing a second 'dragleave' means the drag and drop is canceled.
    eventTypes.push('dragleave');
  }

  eventTypes.forEach(function (type) {
    let event = buildDragEvent(type, stopX, stopY, dataTransfer);
    if (delayDragleave && type === 'dragleave') {
      setTimeout(() => {
        console.log("Dispatching event %O", event);
        stopover.dispatchEvent(event);
      }, 500);
    } else {
      console.log("Dispatching event %O", event);
      stopover.dispatchEvent(event);
    }
  });
}

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
    let event = buildDragEvent(type, targetX, targetY, dataTransfer);
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

      // If we have stopovers, do those first and then get the target
      if (stopovers.length > 0) {
        stopovers.forEach((stopover) => dropOnStopover(stopover, dataTransfer));

        setTimeout(() => {
          if (!cancelDrop) {
            // After we left the stopover DOM elements, the target element should remain visible.
            // If it's not visible, we raise an error.
            if (target.offsetParent === null) {
              throw new Error("Cannot drop the file on an invisible target");
            };
            dropOnTarget(dataTransfer);
          }
        }, 2000);
      } else {
        dropOnTarget(dataTransfer);
      }
    });
