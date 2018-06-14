// JavaScript: HTML5 File drop
// Author: florentbr
// source            : https://gist.github.com/florentbr/0eff8b785e85e93ecc3ce500169bd676
// param1 WebElement : Drop area element (Target of the drop)
// param2 String     : Optional - ID / Name of the temporary field (use when addressing the field without send_keys)
// param3 Double     : Optional - Drop offset x relative to the top/left corner of the drop area. Center if 0.
// param4 Double     : Optional - Drop offset y relative to the top/left corner of the drop area. Center if 0.
// return WebElement : File input

var args = arguments,
  element = args[0],
  name    = args[1],
  offsetX = args[2],
  offsetY = args[3],
  doc = element.ownerDocument || document;

for (var i = 0; ;) {
  var box = element.getBoundingClientRect(),
    clientX = box.left + (offsetX || (box.width / 2)),
    clientY = box.top + (offsetY || (box.height / 2)),
    target = doc.elementFromPoint(clientX, clientY);

  if (target && element.contains(target))
    break;

  if (++i > 1) {
    var ex = new Error('Element not interactable');
    ex.code = 15;
    throw ex;
  }

  element.scrollIntoView({behavior: 'instant', block: 'center', inline: 'center'});
}

var input = doc.createElement('INPUT');
if (name != null) {
  input.id = name;
  input.name = name;
}
input.setAttribute('type', 'file');
input.setAttribute('multiple', '');
input.setAttribute('style', 'position:fixed;z-index:2147483647;left:0;top:0;');
input.onchange = function (ev) {
  input.parentElement.removeChild(input);
  ev.stopPropagation();

  var dataTransfer = {
    constructor   : DataTransfer,
    effectAllowed : 'all',
    dropEffect    : 'none',
    types         : [ 'Files' ],
    files         : input.files,
    setData       : function setData(){},
    getData       : function getData(){},
    clearData     : function clearData(){},
    setDragImage  : function setDragImage(){}
  };

  if (window.DataTransferItemList) {
    dataTransfer.items = Object.setPrototypeOf(Array.prototype.map.call(input.files, function(file) {
      return {
        constructor : DataTransferItem,
        kind        : 'file',
        type        : file.type,
        getAsFile   : function getAsFile () { return file },
        getAsString : function getAsString (callback) {
          var reader = new FileReader();
          reader.onload = function(ev) { callback(ev.target.result) };
          reader.readAsText(file);
        }
      }
    }), {
      constructor : DataTransferItemList,
      add    : function add(){},
      clear  : function clear(){},
      remove : function remove(){}
    });
  }

  ['dragenter', 'dragover', 'drop'].forEach(function (type) {
    var event = doc.createEvent('DragEvent');
    event.initMouseEvent(type, true, true, doc.defaultView, 0, 0, 0, clientX, clientY, false, false, false, false, 0, null);

    Object.setPrototypeOf(event, null);
    event.dataTransfer = dataTransfer;
    Object.setPrototypeOf(event, DragEvent.prototype);

    target.dispatchEvent(event);
  });
};

doc.documentElement.appendChild(input);
input.getBoundingClientRect(); /* force reflow for Firefox */
return input;
