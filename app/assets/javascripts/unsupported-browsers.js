//-- copyright
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
//++

(function($) {

  $(function() {

    var agent = navigator.userAgent;
    if (agent.match(/MSIE [789]\.0/) === null &&                // IE 7-9
        agent.match(/MSIE 10\.\d/) === null &&                // IE 10.0, 10.6
        agent.match(/Firefox\/(([1-2][0-9]|3[0-7])\.)/) === null) { // Firefox 10-37
      return;
    }

    $().topShelf({
      title: I18n.t("js.unsupported_browser.title"),
      message: I18n.t("js.unsupported_browser.message"),
      link: I18n.t("js.unsupported_browser.learn_more"),
      url: "https://www.openproject.org/supported_browsers"
    });

  });

}(jQuery));
