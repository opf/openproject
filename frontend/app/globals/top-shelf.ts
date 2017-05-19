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



(function($:JQueryStatic) {

  function mergeOptions(options:any) {
    if (typeof options === "string") {
      options = { message: options };
    }
    return $.extend({}, $.fn.topShelf.defaults, options);
  }

  $.fn.topShelf = function(this:any, options:any) {
    var opts = mergeOptions(options);
    var message = this;
    var topShelf = $("<div/>").addClass(opts.className);
    var link = $("<a/>").append(' ' + opts.link).attr({"href": opts.url});

    if (window.localStorage.getItem(opts.id)) {
      return;
    }

    var closeLink = $("<a/>").append(opts.close);
    closeLink.click(function() {
      window.localStorage.setItem(opts.id, '1');
      topShelf.remove();
    });

    if (message.length === 0) {
      topShelf.append($("<h1/>").append(opts.title))
              .append($("<p/>").append(opts.message).append(link))
              .append($("<h2/>").append(closeLink));
    } else {
      topShelf.append(message);
    }

    $("body").prepend(topShelf);

    return this;
  };

  $.fn.topShelf.defaults = {
    className: "top-shelf icon icon-warning",
    title: "",
    message: "",
    link: "",
    url: ""
  };

}(jQuery));
