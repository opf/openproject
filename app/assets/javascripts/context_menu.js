//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

/* redMine - project management software
   Copyright (C) 2006-2008  Jean-Philippe Lang */
var observingContextMenuClick;

ContextMenu = Class.create();
ContextMenu.prototype = {
	initialize: function (url) {
	this.url = url;
	this.createMenu();

	if (!observingContextMenuClick) {
		Event.observe(document, 'click', this.Click.bindAsEventListener(this));
		Event.observe(document, 'contextmenu', this.RightClick.bindAsEventListener(this));
		observingContextMenuClick = true;
	}

	this.unselectAll();
	this.lastSelected = null;
	},

	RightClick: function(e) {
		this.hideMenu();
		// do not show the context menu on links
		if (Event.element(e).tagName == 'A') { return; }
		var tr = Event.findElement(e, 'tr');
		if (tr == document || tr == undefined  || !tr.hasClassName('hascontextmenu')) { return; }
		Event.stop(e);
		if (!this.isSelected(tr)) {
			this.unselectAll();
			this.addSelection(tr, e);
			this.lastSelected = tr;
		}
		this.showMenu(e);
	},

  Click: function(e) {
  	this.hideMenu();
  	if (Event.element(e).tagName == 'A') { return; }
    if (!Event.isRightClick(e) || (navigator.appVersion.match(/\bMSIE\b/))) {      
      var tr = Event.findElement(e, 'tr');
      if (tr!=null && tr!=document && tr.hasClassName('hascontextmenu')) {
        // a row was clicked, check if the click was on checkbox
        var box = Event.findElement(e, 'input');
        if (box!=document && box!=undefined) {
          // a checkbox may be clicked
          if (box.checked) {
            tr.addClassName('context-menu-selection');
          } else {
            tr.removeClassName('context-menu-selection');
          }
        } else {
          if (e.ctrlKey || e.metaKey) {
            this.toggleSelection(tr, e);
          } else if (e.shiftKey) {
            if (this.lastSelected != null) {
              var toggling = false;
              var rows = $$('.hascontextmenu');
              for (i=0; i<rows.length; i++) {
                if (toggling || rows[i]==tr) {
                  this.addSelection(rows[i], e);
                }
                if (rows[i]==tr || rows[i]==this.lastSelected) {
                  toggling = !toggling;
                }
              }
            } else {
              this.addSelection(tr, e);
            }
          } else {
            this.unselectAll();
            this.addSelection(tr, e);
          }
          this.lastSelected = tr;
        }
      } else {
        // click is outside the rows
        var t = Event.findElement(e, 'a');
        if (t == document || t == undefined) {
          this.unselectAll();
        } else {
          if (Element.hasClassName(t, 'disabled') || Element.hasClassName(t, 'submenu')) {
            Event.stop(e);
          }
        }
      }
    }
  },
  
  createMenu: function() {
    if (!$('context-menu')) {
      var menu = document.createElement("div");
      menu.setAttribute("id", "context-menu");
      menu.setAttribute("style", "display:none;");
      document.getElementById("content").appendChild(menu);
    }
  },
  
  showMenu: function(e) {
    var mouse_x = Event.pointerX(e);
    var mouse_y = Event.pointerY(e);
    var render_x = mouse_x;
    var render_y = mouse_y - $('top-menu').getHeight();
    var dims;
    var menu_width;
    var menu_height;
    var window_width;
    var window_height;
    var max_width;
    var max_height;

    $('context-menu').style['left'] = (render_x + 'px');
    $('context-menu').style['top'] = (render_y + 'px');		
    Element.update('context-menu', '');

    // some IE-versions only know the srcElement
    var target = e.target ? e.target : e.srcElement;

    new Ajax.Updater({success:'context-menu'}, this.url,
      {asynchronous:true,
       method: 'get',
       evalScripts:true,
       parameters: jQuery(target).closest("form").serialize(),
       onComplete:function(request){
				 dims = $('context-menu').getDimensions();
				 menu_width = dims.width;
				 menu_height = dims.height;
				 max_width = render_x + 2*menu_width;
				 max_height = render_y + menu_height;

				 var ws = window_size();
				 window_width = ws.width;
				 window_height = ws.height;
			
				 /* display the menu above and/or to the left of the click if needed */
				 if (max_width > window_width) {
				   render_x -= menu_width;
				   $('context-menu').addClassName('reverse-x');
				 } else {
					 $('context-menu').removeClassName('reverse-x');
				 }
				 if (max_height > window_height) {
				   render_y -= menu_height;
				   $('context-menu').addClassName('reverse-y');
				 } else {
					 $('context-menu').removeClassName('reverse-y');
				 }
				 if (render_x <= 0) render_x = 1;
				 if (render_y <= 0) render_y = 1;
				 $('context-menu').style['left'] = (render_x + 'px');
				 $('context-menu').style['top'] = (render_y + 'px');
				 
         Effect.Appear('context-menu', {duration: 0.20});
         if (window.parseStylesheets) { window.parseStylesheets(); } // IE
      }})
  },
  
  hideMenu: function() {
    Element.hide('context-menu');
  },

  addSelection: function(tr, e) {
    tr.addClassName('context-menu-selection');
    this.checkSelectionBox(tr, true);
    this.clearDocumentSelection(e);
  },

  toggleSelection: function(tr,e) {
    if (this.isSelected(tr)) {
      this.removeSelection(tr);
    } else {
      this.addSelection(tr, e);
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
  },

  clearDocumentSelection: function(e) {
    if (document.selection) {
      if (document.selection.type == "Text" && e.shiftKey) {
        document.selection.empty(); // IE
      }
    } else {
      window.getSelection().removeAllRanges();
    }
  }
}

function isChecked(checkbox) {
  return jQuery(checkbox).prop('checked') === true;
}

function setSelectionState(checkbox, select) {
  var table_row = checkbox.parents('tr');

  if (select) {
    table_row.addClass('context-menu-selection');
  } else {
    table_row.removeClass('context-menu-selection');
  }
};

function getCheckboxes(link) {
  var form = jQuery(link).parents('form');

  return jQuery(form).find('input[type=checkbox]');
}

function allCheckboxesChecked(checkboxes) {
  return jQuery.makeArray(checkboxes).every(isChecked);
}

function setAllSelectLinkState(link) {
  var checkboxes = getCheckboxes(link);
  var all_checked = allCheckboxesChecked(checkboxes);

  setAllSelectLinkStateToState(link, !all_checked);
}

function setAllSelectLinkStateToState(link, all_checked) {
  var span = link.find('span.hidden-for-sighted');
  var state_text = I18n.t('js.button_uncheck_all');

  if (all_checked) {
    state_text = I18n.t('js.button_check_all');
  }

  link.attr('title', state_text);
  link.attr('alt', state_text);

  span.text(state_text);
}

function toggleSelection(link) {
  var checkboxes = getCheckboxes(link);
  var all_checked = allCheckboxesChecked(checkboxes);

  checkboxes.each(function(index) {
    var checkbox = jQuery(this);

    checkbox.prop('checked', !all_checked);

    setSelectionState(checkbox, !all_checked);

    setAllSelectLinkStateToState(jQuery(link), all_checked);
  });
}

function window_size() {
    var w;
    var h;
    if (window.innerWidth) {
	w = window.innerWidth;
	h = window.innerHeight;
    } else if (document.documentElement) {
	w = document.documentElement.clientWidth;
	h = document.documentElement.clientHeight;
    } else {
	w = document.body.clientWidth;
	h = document.body.clientHeight;
    }
    return {width: w, height: h};
}
