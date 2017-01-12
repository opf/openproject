//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

/*
  This module is responsible to manage tabed views in OpenProject,
  which you can observe, for example, in the settings page.
  Used by view/common/_tabs.html.erb in inline javascript.
*/

// Called when a tab was selected.
// Responsible to hide the old selected tab and show the content
// of the currently selected tab.
function showTab(name, url) {
  jQuery('div#content .tabs .position-label').hide();
  jQuery('div#content .tabs #tab-' + name + ' .position-label').show();
  jQuery('div#content .tab-content').hide();
  jQuery('div.tabs a').removeClass('selected');
  jQuery('#tab-content-' + name).show();
  jQuery('#tab-' + name).addClass('selected');
  //replaces current URL with the "href" attribute of the current link
  //(only triggered if supported by browser)
  if ("replaceState" in window.history) {
    window.history.replaceState(null, document.title, url);
  }

  window.setTimeout(function() {
    jQuery('#tab-' + name).focus();
  }, 100);
  return false;
}

/*
  There are hidden buttons in the common/_tabs.html.erb view,
  which shall allow the user to scrolls through the tab captions.
  Those buttons are only visible if there is not enough room to
  display all tab captions at once.
*/

// Check if there is enough room to display all tab captions
// and show/hide the tabButtons accordingly.
function displayTabsButtons() {
  var lis;
  var tabsWidth = 0;
  var el;
  jQuery('div.tabs').each(function() {
    el = jQuery(this);
    lis = el.find('ul').children();
    lis.each(function(){
      if (jQuery(this).is(':visible')) {
        tabsWidth += jQuery(this).width() + 6;
      }
    });
    if ((tabsWidth < el.width() - 60) && (lis.first().is(':visible'))) {
      el.find('div.tabs-buttons').hide();
    } else {
      el.find('div.tabs-buttons').show();
    }
  });
}

// scroll the tab caption list right
function moveTabRight(el) {
  var lis = jQuery(el).parents('div.tabs').first().find('ul').children();
  var tabsWidth = 0;
  var i = 0;
  lis.each(function() {
    if (jQuery(this).is(':visible')) {
      tabsWidth += jQuery(this).width() + 6;
    }
  });
  if (tabsWidth < jQuery(el).parents('div.tabs').first().width() - 60) { return; }
  while (i<lis.length && !lis.eq(i).is(':visible')) { i++; }
  lis.eq(i).hide();
}

// scroll the tab caption list left
function moveTabLeft(el) {
  var lis = jQuery(el).parents('div.tabs').first().find('ul').children();
  var i = 0;
  while (i < lis.length && !lis.eq(i).is(':visible')) { i++; }
  if (i > 0) {
    lis.eq(i-1).show();
  }
}
