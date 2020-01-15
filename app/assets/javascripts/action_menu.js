//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

/*
  The action menu is a menu that usually belongs to an OpenProject entity (like an Issue, WikiPage, Meeting, ..).
  Most likely it looks like this:
    <ul class="action_menu_main">
      <li><a>Menu item text</a></li>
      <li><a>Menu item text</a></li>
      <li class="drop-down">
        <a class="icon icon-more" href="#">More functions</a>
        <ul style="display:none;" class="menu-drop-down-container">
          <li><a>Menu item text</a></li>
        </ul>
      </li>
    </ul>
  The following code is responsible to open and close the "more functions" submenu.
*/

jQuery(function ($) {
  var animationSpeed = 100; // ms

  function menu_top_position(menu) {
    // if an h2 tag follows the submenu should unfold out at the border
    var menu_start_position;
    if (menu.next().get(0) != undefined && (menu.next().get(0).tagName == 'H2')) {
      menu_start_position = menu.next().innerHeight() + menu.next().position().top;
    }
    else if (menu.next().hasClass("wiki-content") && menu.next().children().next().first().get(0) != undefined && menu.next().children().next().first().get(0).tagName == 'H1') {
      var wiki_heading = menu.next().children().next().first();
      menu_start_position = wiki_heading.innerHeight() + wiki_heading.position().top;
    }
    return menu_start_position;
  }

  function close_menu(event) {
    var menu = $(event.data.menu);
    // do not close the menu, if the user accidentally clicked next to a menu item (but still within the menu)
    if (event.target !== menu.find(" > li.drop-down.open > ul").get(0)) {
      menu.find(" > li.drop-down.open").removeClass("open").find("> ul").slideUp(animationSpeed);
      // no need to watch for clicks, when the menu is already closed
      $('html').off('click', close_menu);
    }
  }

  function open_menu(menu) {
    var drop_down = menu.find(" > li.drop-down");
    // do not open a menu, which is already open
    if (!drop_down.hasClass('open')) {
      drop_down.find('> ul').slideDown(animationSpeed, function () {
        drop_down.find('li > a:first').focus();
        // when clicking on something, which is not the menu, close the menu
        $('html').on('click', {menu: menu.get(0)}, close_menu);
      });
      drop_down.addClass('open');
    }
  }

  // open the given submenu when clicking on it
  function install_menu_logic(menu) {
    menu.find(" > li.drop-down").click(function (event) {
      open_menu(menu);
      // and prevent default action (href) for that element
      // but not for the menu items.
      var target = $(event.target);
      if (target.is('.drop-down') || target.closest('li, ul').is('.drop-down')) {
        event.preventDefault();
      }
    });
  }

  $('.project-actions, .toolbar-items').each(function (idx, menu) {
    install_menu_logic($(menu));
  });
});
