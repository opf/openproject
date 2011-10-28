ContextMenu.addMethods({
  RightClick: function(e) {
	this.hideMenu();
	// do not show the context menu on links
	if (Event.element(e).tagName == 'A') { return; }
	// right-click simulated by Alt+Click with Opera
	if (window.opera && !e.altKey) { return; }
	var tr = Event.findElement(e, 'tr');
	if (tr == document || tr == undefined  || !tr.hasClassName('hascontextmenu')) { return; }
	Event.stop(e);

    this.OpenMenuWrapper(e, tr);
  },

  // Theme: New method from RightClick
  OpenMenu: function(e) {
	this.hideMenu();
	// do not show the context menu on links
	if (Event.element(e).tagName == 'A') { return; }
	// right-click simulated by Alt+Click with Opera
	if (window.opera && !e.altKey) { return; }
	var tr = Event.findElement(e, 'tr');
	if (tr == document || tr == undefined  || !tr.hasClassName('hascontextmenu')) { return; }
	Event.stop(e);
	this.showMenu(e);
  },

  Click: function(e) {
  	this.hideMenu();
  	if (Event.element(e).tagName == 'A') { return; }
    if (window.opera && e.altKey) {	return; }

    var tr = Event.findElement(e, 'tr');
    if (tr!=null && tr!=document && tr.hasClassName('hascontextmenu')) {
        if (!tr.hasClassName('no-select')) {
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
                // Checkbox wasn't checked so see if the menu should open.
                this.OpenMenuWrapper(e, tr);
            }
        } else {
            // Header clicked
            this.OpenMenuWrapper(e, tr);
        }
    } else {
      // click is outside the rows
      this.removeSingleSelectedItem();
      var t = Event.findElement(e, 'a');
      if ((t != document) && (Element.hasClassName(t, 'disabled') || Element.hasClassName(t, 'submenu'))) {
        Event.stop(e);
      }
    }
  },

  removeSingleSelectedItem: function() {
    if (($$('.context-menu-selection').size() == 1)) {
      var context_menu = this;
      $$('.context-menu-selection').each(function(selected_item) {
        context_menu.removeSelection(selected_item);
      });
    }
  },

  // Theme: Open the context menu if the clicked column is the issue ID column and at least
  //        one row is checked.  Or if the issue header is clicked.
  OpenMenuWrapper: function(e, tr) {
      if (!tr.hasClassName('no-select')) {
          var issue_cell = $(Event.element(e));
          var tdClicked = Event.findElement(e,'td');

          if (issue_cell && issue_cell.hasClassName('issue')) {
              this.addSelection(tr);
              this.lastSelected = tr;
              this.showMenu(e);
          } else {
              // Menu wasn't requested on a selected item, see about removing the single item selection.
              this.removeSingleSelectedItem();
          }
      } else {
          // block clicking on the All Issues toggle
          if (!Event.findElement(e, 'a')) {
              // Remove selected items
              this.removeSingleSelectedItem();
              this.addSelection(tr);
              this.lastSelected = tr;
              this.showMenu(e);
          }
      }
  }
});
