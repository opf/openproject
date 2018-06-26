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

/**
 * A set of listeners that are relevant on every page to set sensible defaults
 */
(function($:JQueryStatic) {

  // Our application is still a hybrid one, meaning most routes are still
  // handled by Rails. As such, we disable the default link-hijacking that
  // Angular's HTML5-mode turns on.
  $(function() {
    $(document.body)
      .off('click')
      // Prevent angular handling clicks on href="#..." links from other libraries
      // (especially jquery-ui and its datepicker) from routing to <base url>/#
      .on('click', 'a[href^="#"]', (evt) => {
        evt.preventDefault();

        // Set the location to the hash if there is any
        // Since with the base tag, links like href="#whatever" otherwise target to <base>/#whatever
        const link = evt.target.getAttribute('href');
        if (link && link !== '#') {
          window.location.hash = link;
        }

        return false;
      });

    // Disable global drag & drop handling, which results in the browser loading the image and losing the page
    $(document.documentElement)
      .on('dragover drop', (evt:JQueryEventObject) => {
        evt.preventDefault();
        return false;
      });
  });
}(jQuery));
