/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting */

window.Reporting = {
  source: ($$("head")[0].select("script[src*='reporting.js']")[0].src),

  require: function (libraryName) {
    var jsName = Reporting.source.replace("reporting.js", "reporting/" + libraryName + ".js");
    try {
      // inserting via DOM fails in Safari 2.0, so brute force approach
      document.write('<script type="text/javascript" src="' + jsName + '"><\/script>');
    } catch (e) {
      // for xhtml+xml served content, fall back to DOM methods
      var script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = jsName;
      document.getElementsByTagName('head')[0].appendChild(script);
    }
  },

  onload: function (func) {
    document.observe("dom:loaded", func);
  },

  flash: function (string, type) {
    if (type === undefined) {
      type = "error";
    }
    $("content").insert({before: "<div onclick='$(this).remove();' id='flash_" + type + "'>" + string + "</div>"});
  },

  fireEvent: function (element, event) {
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
  }
};

Reporting.require("filters");
Reporting.require("group_bys");
Reporting.require("restore_query");
Reporting.require("controls");

//
// function hide_category(tr_field) {
//     var label = $(tr_field.getAttribute("data-label"));
//     if (label !== null) {
//         label.hide();
//     }
// }
//
// function restore_select_values(select, values) {
//     var i, j;
//     if (values.length > 1) {
//         make_select_accept_multiple_values(select);
//     } else {
//         make_select_accept_single_value(select);
//     }
//     for (i = 0; i < values.length; i += 1) {
//         for (j = 0; j < select.options.length; j += 1) {
//             if (select.options[j].value === values[i].toString()) {
//                 try {
//                     select.options[j].selected = true;
//                     break;
//                 } catch(e) {
//                     window.setTimeout('$("' + select.id + '").childElements()[' + j + '].selected = true;', 1);
//                 }
//             }
//         }
//     }
// }
//
// function defineElementGetter() {
//     if (document.getElementsByClassName === undefined) {
//         document.getElementsByClassName = function (className)
//         {
//             var hasClassName, allElements, results, element, elementClass, i;
//             hasClassName = new RegExp("(?:^|\\s)" + className + "(?:$|\\s)");
//             allElements = document.getElementsByTagName("*");
//             results = [];
//             for (i = 0; (element = allElements[i]) !== null; i += 1) {
//                 elementClass = element.className;
//                 if (elementClass && elementClass.indexOf(className) !== -1 && hasClassName.test(elementClass)) {
//                     results.push(element);
//                 }
//             }
//             return results;
//         };
//     }
// }
//
// // defineElementGetter();

