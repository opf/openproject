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

//= require mousetrap

(function($){
  var menu_sidebar = function() {
    return $('div#menu-sidebar');
  };

  var we_are_in_project = function() {
    return menu_sidebar().size() === 1;
  };

  var show_help_modal = function(){
    var relative_url_root = jQuery('body').data('relative_url_root');
    var template_path = relative_url_root + 'help/keyboard_shortcuts';
    modalHelperInstance.createModal(template_path);
  };

  var go_overview = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.overview')[0].click();
    }
  };

  var go_my_page = function(){
    var my_page = $('.account-nav .my-page');
    if (my_page.size() === 1) {
      my_page[0].click();
    }
  };

  var go_work_packages = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.work-packages')[0].click();
    }
  };

  var go_timelines = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.timelines')[0].click();
    }
  };

  var go_wiki = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.Wiki')[0].click();
    }
  };

  var go_activity = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.activity')[0].click();
    }
  };

  var go_calendar = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.calendar')[0].click();
    }
  };

  var go_news = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.news')[0].click();
    }
  };

  var go_edit = function(){
    edit_link = $('[accesskey=3]')[0];
    if (edit_link !== undefined) {
      edit_link.click();
    }
  };

  var open_more_menu = function(){
    more_menu = $('[accesskey=7]')[0];
    if (more_menu !== undefined) {
      more_menu.click();
    }
  };

  var go_preview = function(){
    preview_link = $('[accesskey=1]')[0];
    if (preview_link !== undefined) {
      preview_link.click();
    }
  };

  var new_work_package = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.new-work-package')[0].click();
    }
  };

  var search_project = function(){
    $('#project-search-container').parents('li.drop-down').click();
  };

  var search_global = function(){
    $('#search_wrap .search_field').focus();
  };

  /*
    Helper function for the j/k-shortcuts. Returns a list of j/k-enumerable
    items on the current page.
  */
  var find_list_in_page = function(){
    var focus_elements = []; // list of [list_entry, first_link] elements

    // old-style table lists
    $('table.list tbody tr').each(function(index, tr){
      var first_link = $(tr).find('a:visible')[0];
      if ( first_link !== undefined ) {
        focus_elements.push( [tr, first_link] );
      }
    });

    // new angular work package list
    $('.workpackages-table .issue').each(function(index, issue){
      var first_link = $(issue).find('a:visible')[0];
      if ( first_link !== undefined ) {
        focus_elements.push( [issue, first_link] );
      }
    });

    return focus_elements;
  };

  var focus_item_offset = function(offset){
    var list, items, i;
    list = find_list_in_page();
    item = $(document.activeElement).parents('tr')[0];
    if (list === null) { return; }
    if (item === undefined) {
      $(list[0][1]).focus();
      return;
    }

    // scan through list to find the index of the current item
    for (i = 0; i < list.length; ++i) {
      if ( list[i][0] === item ) {
        break;
      }
    }
    $(list[(i+offset+list.length) % list.length][1]).focus();
  };

  var focus_next_item = function(){
    focus_item_offset(1);
  };

  var focus_previous_item = function(){
    focus_item_offset(-1);
  };


  Mousetrap.bind('?',     function(){ show_help_modal();     return false; });

  Mousetrap.bind('g o',   function(){ go_overview();         return false; });
  Mousetrap.bind('g m',   function(){ go_my_page();          return false; });
  Mousetrap.bind('g w p', function(){ go_work_packages();    return false; });
  Mousetrap.bind('g w i', function(){ go_wiki();             return false; });
  Mousetrap.bind('g a',   function(){ go_activity();         return false; });
  Mousetrap.bind('g c',   function(){ go_calendar();         return false; });
  Mousetrap.bind('g n',   function(){ go_news();             return false; });
  Mousetrap.bind('g t',   function(){ go_timelines();        return false; });
  Mousetrap.bind('g e',   function(){ go_edit();             return false; });
  Mousetrap.bind('g p',   function(){ go_preview();          return false; });

  Mousetrap.bind('n w p', function(){ new_work_package();    return false; });
  Mousetrap.bind('j',     function(){ focus_next_item();     return false; });
  Mousetrap.bind('k',     function(){ focus_previous_item(); return false; });
  Mousetrap.bind('m',     function(){ open_more_menu();      return false; });

  Mousetrap.bind('p',     function(){ search_project();      return false; });
  Mousetrap.bind('s',     function(){ search_global();       return false; });
})(jQuery);

jQuery(function(){
  // simulated hover effect on tables when using the keyboard
  var content = jQuery('#content');
  content.on('hover', 'table tr *', function(){
    jQuery(this).parents('table tr').first().removeClass('keyboard_hover');
  });
  content.on('focus', 'table tr *', function(){
    jQuery('.keyboard_hover').removeClass('keyboard_hover');
    jQuery(this).parents('table tr').first().addClass('keyboard_hover');
  });
});
