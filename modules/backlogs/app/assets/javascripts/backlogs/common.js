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

if (window.RB === null || window.RB === undefined) {
  window.RB = (function ($) {
    var object, Factory, Dialog, UserPreferences,
        ajax;

    object = {
      // Douglas Crockford's technique for object extension
      // http://javascript.crockford.com/prototypal.html
      create: function () {
        var obj, i, methods, methodName;

        function F() {
        }

        F.prototype = arguments[0];
        obj = new F();

        // Add all the other arguments as mixins that
        // 'write over' any existing methods
        for (i = 1; i < arguments.length; i += 1) {
          methods = arguments[i];
          if (typeof methods === 'object') {
            for (methodName in methods) {
              if (methods.hasOwnProperty(methodName)) {
                obj[methodName] = methods[methodName];
              }
            }
          }
        }
        return obj;
      }
    };


    // Object factory for chiliproject_backlogs
    Factory = object.create({

      initialize: function (objType, el) {
        var obj;

        obj = object.create(objType);
        obj.initialize(el);
        return obj;
      }

    });

    // Utilities
    Dialog = object.create({
      msg: function (msg) {
        var dialog, baseClasses;

        baseClasses = 'ui-button ui-widget ui-state-default ui-corner-all';

        if ($('#msgBox').length === 0) {
          dialog = $('<div id="msgBox"></div>').appendTo('body');
        }
        else {
          dialog = $('#msgBox');
        }

        dialog.html(msg);
        dialog.dialog({
          title: 'Backlogs Plugin',
          buttons: [
          {
            text: 'OK',
            class: 'button -highlight',
            click: function () {
              $(this).dialog("close");
            }
          }],
          modal: true
        });
        $('.button').removeClass(baseClasses);
        $('.ui-icon-closethick').prop('title', 'close');
      }
    });

    ajax = (function () {
      var ajaxQueue, ajaxOngoing,
          processAjaxQueue;

      ajaxQueue = [];
      ajaxOngoing = false;

      processAjaxQueue = function () {
        var options = ajaxQueue.shift();

        if (options !== null && options !== undefined) {
          ajaxOngoing = true;
          $.ajax(options);
        }
      };

      // Process outstanding entries in the ajax queue whenever a ajax request
      // finishes.
      $(document).ajaxComplete(function (event, xhr, settings) {
        ajaxOngoing = false;
        processAjaxQueue();
      });

      return function (options) {
        ajaxQueue.push(options);
        if (!ajaxOngoing) {
          processAjaxQueue();
        }
      };
    }());

    // Abstract the user preference from the rest of the RB objects
    // so that we can change the underlying implementation as needed
    UserPreferences = object.create({
      get: function (key) {
        return $.cookie(key);
      },

      set: function (key, value) {
        $.cookie(key, value, { expires: 365 * 10 });
      }
    });

    return {
      Object          : object,
      Factory         : Factory,
      Dialog          : Dialog,
      UserPreferences : UserPreferences,
      ajax            : ajax
    };
  }(jQuery));
}
