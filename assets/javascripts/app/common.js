/*jslint indent: 2*/
/*globals window, document, jQuery*/

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
        var dialog;

        if ($('#msgBox').size() === 0) {
          dialog = $('<div id="msgBox"></div>').appendTo('body');
        }
        else {
          dialog = $('#msgBox');
        }

        dialog.html(msg);
        dialog.dialog({
          title: 'Backlogs Plugin',
          buttons: {
            OK: function () {
              $(this).dialog("close");
            }
          },
          modal: true
        });
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

      // Modify the ajax request before being sent to the server,
      // i.e. add project id and csrf token
      $(document).ajaxSend(function (event, request, settings) {
        var c = window.RB.constants;

        settings.data = settings.data || "";
        settings.data += (settings.data ? "&" : "") + "project_id=" + c.project_id;

        if (c.protect_against_forgery) {
          settings.data += "&" +
                           c.request_forgery_protection_token + "=" +
                           encodeURIComponent(c.form_authenticity_token);
        }
      });

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
