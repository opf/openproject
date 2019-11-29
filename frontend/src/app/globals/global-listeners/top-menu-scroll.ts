// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// ++


// Scroll header on mobile in and out when user scrolls the container
export function scrollHeaderOnMobile(elem:JQuery) {
  const headerHeight = 55;
  let prevScrollPos = elem.scrollTop()!;

  elem.on('scroll', function() {
    // Condition needed for safari browser to avoid negative positions
    let currentScrollPos = elem.scrollTop()! < 0 ? 0 : elem.scrollTop()!;
    // Only if sidebar is not opened or search bar is opened
    if (!(jQuery('#main').hasClass('hidden-navigation')) ||
        jQuery('#top-menu').hasClass('-global-search-expanded') ||
        Math.abs(currentScrollPos - prevScrollPos) <= headerHeight) { // to avoid flickering at the end of the page
      return;
    }

    let marginTop:number = -headerHeight;
    if (prevScrollPos !== undefined && currentScrollPos !== undefined && (prevScrollPos > currentScrollPos)) {
      marginTop = 0;
    }
    toggleTopMenu(marginTop);
    prevScrollPos = currentScrollPos;
  });
}

// Slide top menu in or out of viewport
function toggleTopMenu(marginTop:number) {
  jQuery('#top-menu').css({'margin-top': marginTop + 'px', transition:'margin-top .4s'});
}
