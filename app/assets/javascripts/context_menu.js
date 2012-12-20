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

/*globals window, document, jQuery, navigator*/

var ContextMenu = (function ($) {
  var handleRightClick,
      handleClick,
      create,
      init,
      show,
      hide,
      isSelected,
      unselectAll,
      addSelection,
      toggleSelection,
      toggleIssuesSelection,
      removeSelection,
      setLastSelected,
      lastSelected,
      checkSelectionBox,
      clearDocumentSelection,
      window_size,
      contextMenuObserving,
      contextMenuUrl;

  handleRightClick = function (event) {
    var target = $(event.target),
        tr;

    if (target.is('a')) {
      return;
    }
    tr = target.parents('tr').first();

    if (!tr.hasClass('hascontextmenu')) {
      return;
    }
    event.preventDefault();

    if (!isSelected(tr)) {
      unselectAll();
      addSelection(tr);
      setLastSelected(tr);
    }

    show(event);
  };

  handleClick = function (event) {
    var target = $(event.target),
        tr,
        lastSelected,
        toggling;

    if (target.is('a') && target.hasClass('submenu')) {
      event.preventDefault();
      return;
    }
    hide();
    if (target.is('a') || target.is('img')) {
      return;
    }
    if (event.which === 1 || (navigator.appVersion.match(/\bMSIE\b/))) {
      tr = target.parents('tr').first();
      if (tr.length && tr.hasClass('hascontextmenu')) {
        // a row was clicked, check if the click was on checkbox
        if (target.is('input')) {
          // a checkbox may be clicked
          if (target.attr('checked')) {
            tr.addClass('context-menu-selection');
          } else {
            tr.removeClass('context-menu-selection');
          }
        } else {
          if (event.ctrlKey || event.metaKey) {
            toggleSelection(tr);
          } else if (event.shiftKey) {
            lastSelected = lastSelected();
            if (lastSelected.length) {
              toggling = false;
              $('.hascontextmenu').each(function () {
                if (toggling || $(this).is(tr)) {
                  addSelection($(this));
                }
                if ($(this).is(tr) || $(this).is(lastSelected)) {
                  toggling = !toggling;
                }
              });
            } else {
              addSelection(tr);
            }
          } else {
            unselectAll();
            addSelection(tr);
          }
          setLastSelected(tr);
        }
      } else {
        // click is outside the rows
        if (target.is('a') && (target.hasClass('disabled') || target.hasClass('submenu'))) {
          event.preventDefault();
        } else {
          unselectAll();
        }
      }
    }
  };

  create = function () {
    if ($('#context-menu').length < 1) {
      var menu = document.createElement("div");
      menu.setAttribute("id", "context-menu");
      menu.setAttribute("style", "display:none;");
      document.getElementById("wrapper").appendChild(menu);
    }
  };

  show = function (event) {
    var mouse_x = event.pageX,
        mouse_y = event.pageY,
        render_x = mouse_x,
        render_y = mouse_y,// - $('#top-menu').height(),
        dims,
        menu_width,
        menu_height,
        window_width,
        window_height,
        max_width,
        max_height;

    $('#context-menu').css('left', (render_x + 'px'));
    $('#context-menu').css('top', (render_y + 'px'));
    $('#context-menu').html('');

    $.ajax({
      url: contextMenuUrl,
      data: $(event.target).parents('form').first().serialize(),
      success: function (data, textStatus, jqXHR) {

        $('#context-menu').html(data);

        menu_width = $('#context-menu').width();
        menu_height = $('#context-menu').height();
        max_width = mouse_x + 2 * menu_width;
        max_height = mouse_y + menu_height;

        var ws = window_size();
        window_width = ws.width;
        window_height = ws.height;

        /* display the menu above and/or to the left of the click if needed */
        if (max_width > window_width) {
          render_x -= menu_width;
          $('#context-menu').addClass('reverse-x');
        }
        else {
          $('#context-menu').removeClass('reverse-x');
        }
        if (max_height > window_height) {
          render_y -= menu_height;
          $('#context-menu').addClass('reverse-y');
        }
        else {
          $('#context-menu').removeClass('reverse-y');
        }
        if (render_x <= 0) {
          render_x = 1;
        }
        if (render_y <= 0) {
          render_y = 1;
        }
        $('#context-menu').css('left', (render_x + 'px'));
        $('#context-menu').css('top', (render_y + 'px'));
        $('#context-menu').show();

        //if (window.parseStylesheets) { window.parseStylesheets(); } // IE

      }
    });
  };

  setLastSelected = function (tr) {
    $('.cm-last').removeClass('cm-last');
    tr.addClass('cm-last');
  };

  lastSelected = function () {
    return $('.cm-last').first();
  };

  unselectAll = function () {
    $('.hascontextmenu').each(function () {
      removeSelection($(this));
    });
    $('.cm-last').removeClass('cm-last');
  };

  hide = function () {
    $('#context-menu').hide();
  };

  toggleSelection = function (tr) {
    if (isSelected(tr)) {
      removeSelection(tr);
    } else {
      addSelection(tr);
    }
  };

  addSelection = function (tr) {
    tr.addClass('context-menu-selection');
    checkSelectionBox(tr, true);
    clearDocumentSelection();
  };

  removeSelection = function (tr) {
    tr.removeClass('context-menu-selection');
    checkSelectionBox(tr, false);
  };

  isSelected = function (tr) {
    return tr.hasClass('context-menu-selection');
  };

  checkSelectionBox = function (tr, checked) {
    tr.find('input[type=checkbox]').attr('checked', checked);
  };

  clearDocumentSelection = function () {
    // TODO
    if (document.selection) {
      document.selection.clear(); // IE
    } else {
      window.getSelection().removeAllRanges();
    }
  };

  init = function (url) {
    contextMenuUrl = url;
    create();
    unselectAll();

    if (!contextMenuObserving) {
      $(document).click(handleClick);
      $(document).contextmenu(handleRightClick);
      contextMenuObserving = true;
    }
  };

  toggleIssuesSelection = function (el) {
    var boxes = $(el).parents('form').find('input[type=checkbox]'),
        all_checked = true;

    boxes.each(function () {
      if (!$(this).attr('checked')) {
        all_checked = false;
      }
    });
    boxes.each(function () {
      if (all_checked) {
        $(this).removeAttr('checked');
        $(this).parents('tr').removeClass('context-menu-selection');
      } else if (!$(this).attr('checked')) {
        $(this).attr('checked', true);
        $(this).parents('tr').addClass('context-menu-selection');
      }
    });
  };

  window_size = function () {
    var w,
        h;

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
  };

  return {
    init : init
  };
}(jQuery));
