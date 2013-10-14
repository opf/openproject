//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
    modalHelperInstance.createModal('/help/keyboard_shortcuts');
  };

  var go_overview = function(){
    if (we_are_in_project()) {
      menu_sidebar().find('.overview')[0].click();
    }
  };

  var go_my_page = function(){
    var my_page = $('#account-nav .my-page');
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


  Mousetrap.bind('?',     function(){ show_help_modal();  return false; });

  Mousetrap.bind('g o',   function(){ go_overview();      return false; });
  Mousetrap.bind('g m',   function(){ go_my_page();       return false; });
  Mousetrap.bind('g w p', function(){ go_work_packages(); return false; });
  Mousetrap.bind('g w i', function(){ go_wiki();          return false; });
  Mousetrap.bind('g a',   function(){ go_activity();      return false; });
  Mousetrap.bind('g c',   function(){ go_calendar();      return false; });
  Mousetrap.bind('g n',   function(){ go_news();          return false; });
  Mousetrap.bind('g t',   function(){ go_timelines();     return false; });

  Mousetrap.bind('n w p', function(){ new_work_package(); return false; });

  Mousetrap.bind('s p',   function(){ search_project();   return false; });
  Mousetrap.bind('s g',   function(){ search_global();    return false; });
})(jQuery);
