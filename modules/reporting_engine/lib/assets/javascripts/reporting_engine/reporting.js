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

/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Element */

window.Reporting = (function($) {
  var onload = function (func) {
    $(document).ready(func);
  };

  var flash = function (string, type) {
    if (!type) {
      type = "error";
    }

    var options = {};

    if (type === 'error') {
      options = {
        id: 'errorExplanation',
        class: 'errorExplanation'
      };
    }
    else {
      options = {
        id: 'flash_' + type,
        class: 'flash ' + type
      };
    }

    $("#" + options.id).remove();

    var flash = $('<div></div>')
                .attr('id', options.id)
                .attr('class', options.class)
                .attr('tabindex', 0)
                .attr('role', 'alert')
                .html(string);

    $('#content').prepend(flash);
    $('#' + options.id).focus();
  };

  var clearFlash = function () {
    $('div[id^=flash]').remove();
  };

  var fireEvent = function (element, event) {
    var evt;
    if (document.createEventObject) {
      // dispatch for IE
      evt = document.createEventObject();
      return element.fireEvent('on' + event, evt);
    } else {
      // dispatch for firefox + others
      evt = document.createEvent("HTMLEvents");
      evt.initEvent(event, true, true); // event type,bubbling,cancelable
      return !element.dispatchEvent(evt);
    }
  };

  return {
    fireEvent: fireEvent,
    clearFlash: clearFlash,
    flash: flash,
    onload: onload
  };
})(jQuery);
