/* redMine - project management software
   Copyright (C) 2006-2008  Jean-Philippe Lang */

var observingContextMenuClick;

ContextMenu = Class.create();
ContextMenu.prototype = {
	initialize: function (url) {
	this.url = url;

	// prevent selection when using Ctrl/Shit key
	var tables = $$('table.issues');
	for (i=0; i<tables.length; i++) {
		tables[i].onselectstart = function () { return false; } // ie
		tables[i].onmousedown = function () { return false; } // mozilla
	}

	if (!observingContextMenuClick) {
		Event.observe(document, 'click', this.Click.bindAsEventListener(this));
		Event.observe(document, (window.opera ? 'click' : 'contextmenu'), this.RightClick.bindAsEventListener(this));
		observingContextMenuClick = true;
	}
	
	this.unselectAll();
	this.lastSelected = null;
	},
  
	RightClick: function(e) {
		this.hideMenu();
		// do not show the context menu on links
		if (Event.findElement(e, 'a') != document) { return; }
		// right-click simulated by Alt+Click with Opera
		if (window.opera && !e.altKey) { return; }
		var tr = Event.findElement(e, 'tr');
		if ((tr == document) || !tr.hasClassName('hascontextmenu')) { return; }
		Event.stop(e);
		if (!this.isSelected(tr)) {
			this.unselectAll();
			this.addSelection(tr);
			this.lastSelected = tr;
		}
		this.showMenu(e);
	},

  Click: function(e) {
  	this.hideMenu();
  	if (Event.findElement(e, 'a') != document) { return; }
    if (window.opera && e.altKey) {	return; }
    if (Event.isLeftClick(e) || (navigator.appVersion.match(/\bMSIE\b/))) {      
      var tr = Event.findElement(e, 'tr');
      if (tr!=document && tr.hasClassName('hascontextmenu')) {
        // a row was clicked, check if the click was on checkbox
        var box = Event.findElement(e, 'input');
        if (box!=document) {
          // a checkbox may be clicked
          if (box.checked) {
            tr.addClassName('context-menu-selection');
          } else {
            tr.removeClassName('context-menu-selection');
          }
        } else {
          if (e.ctrlKey) {
            this.toggleSelection(tr);
          } else if (e.shiftKey) {
            if (this.lastSelected != null) {
              var toggling = false;
              var rows = $$('.hascontextmenu');
              for (i=0; i<rows.length; i++) {
                if (toggling || rows[i]==tr) {
                  this.addSelection(rows[i]);
                }
                if (rows[i]==tr || rows[i]==this.lastSelected) {
                  toggling = !toggling;
                }
              }
            } else {
              this.addSelection(tr);
            }
          } else {
            this.unselectAll();
            this.addSelection(tr);
          }
          this.lastSelected = tr;
        }
      } else {
        // click is outside the rows
        var t = Event.findElement(e, 'a');
        if ((t != document) && (Element.hasClassName(t, 'disabled') || Element.hasClassName(t, 'submenu'))) {
          Event.stop(e);
        }
      }
    }
  },
  
  showMenu: function(e) {
		$('context-menu').style['left'] = (Event.pointerX(e) + 'px');
		$('context-menu').style['top'] = (Event.pointerY(e) + 'px');		
		Element.update('context-menu', '');
		new Ajax.Updater({success:'context-menu'}, this.url, 
      {asynchronous:true,
       evalScripts:true,
       parameters:Form.serialize(Event.findElement(e, 'form')),
       onComplete:function(request){
         Effect.Appear('context-menu', {duration: 0.20});
         if (window.parseStylesheets) { window.parseStylesheets(); } // IE
      }})
  },
  
  hideMenu: function() {
    Element.hide('context-menu');
  },
  
  addSelection: function(tr) {
    tr.addClassName('context-menu-selection');
    this.checkSelectionBox(tr, true);
  },
  
  toggleSelection: function(tr) {
    if (this.isSelected(tr)) {
      this.removeSelection(tr);
    } else {
      this.addSelection(tr);
    }
  },
  
  removeSelection: function(tr) {
    tr.removeClassName('context-menu-selection');
    this.checkSelectionBox(tr, false);
  },
  
  unselectAll: function() {
    var rows = $$('.hascontextmenu');
    for (i=0; i<rows.length; i++) {
      this.removeSelection(rows[i]);
    }
  },
  
  checkSelectionBox: function(tr, checked) {
  	var inputs = Element.getElementsBySelector(tr, 'input');
  	if (inputs.length > 0) { inputs[0].checked = checked; }
  },
  
  isSelected: function(tr) {
    return Element.hasClassName(tr, 'context-menu-selection');
  }
}

function toggleIssuesSelection(el) {
	var boxes = el.getElementsBySelector('input[type=checkbox]');
	var all_checked = true;
	for (i = 0; i < boxes.length; i++) { if (boxes[i].checked == false) { all_checked = false; } }
	for (i = 0; i < boxes.length; i++) {
		if (all_checked) {
			boxes[i].checked = false;
			boxes[i].up('tr').removeClassName('context-menu-selection');
		} else if (boxes[i].checked == false) {
			boxes[i].checked = true;
			boxes[i].up('tr').addClassName('context-menu-selection');
		}
	}
}
