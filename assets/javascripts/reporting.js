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
  }
};

Reporting.require("filters");
Reporting.require("group_bys");
Reporting.require("restore_query");

//
// /*global $, selectAllOptions, moveOptions */
//
// function hide_category(tr_field) {
//     var label = $(tr_field.getAttribute("data-label"));
//     if (label !== null) {
//         label.hide();
//     }
// }
//
// function set_remove_button_visibility(field, value) {
//     var remove = $('rm_' + field);
//     if (remove !== null) {
//         if (value === true) {
//             remove.show();
//         } else {
//             remove.hide();
//         }
//     }
// }
//
// function show_group_by(group_by, target) {
//     var source, group_option, i;
//     source = $("group_by_container");
//     group_option = null;
//     // find group_by option-tag in target select-box
//     for (i = 0; i < source.options.length; i += 1) {
//         if (source.options[i].value === group_by) {
//             group_option = source.options[i];
//             source.options[i] = null;
//             break;
//         }
//     }
//     // die if the appropriate option-tag can not be found
//     if (group_option === null) {
//         return;
//     }
//     // move the option-tag to the taget select-box while keepings its data
//     target.options[target.length] = group_option;
// }
//
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
// function find_arguments(field) {
//     var args = [], arg_count = 0, arg = null;
//     arg = $(field + '_arg_' + (arg_count + 1) + '_val');
//     while (arg !== null) {
//         args[args.length] = arg;
//         arg_count = arg_count + 1;
//         arg = $(field + '_arg_' + (arg_count + 1) + '_val');
//     }
//     return args;
// }
//
// function restore_values(field, values) {
//     var op_select, op_arity, args, i;
//     op_select = $("operators_" + field);
//     if (op_select !== null) {
//         op_arity = op_select.options[op_select.selectedIndex].getAttribute("data-arity");
//     }
//     else {
//         op_arity = 0;
//     }
//     args = find_arguments(field);
//     if (args.size() === 0) {
//         return; // there are no values to set
//     }
//     if (!Object.isArray(values)) {
//         values = [values];
//     }
//     if (op_arity < 0 && !(args[0].type.empty()) && args[0].type.include('select')) {
//         restore_select_values(args[0], values);
//     } else {
//         for (i = 0; i < values.length && i < args.length; i += 1) {
//             args[i].setValue(values[i]);
//         }
//     }
// }
//
// function serialize_filter_and_group_by() {
//     var ret_str, rows, columns;
//     ret_str = Form.serialize('query_form');
//     rows = Sortable.serialize('group_rows');
//     columns = Sortable.serialize('group_columns');
//     if (rows !== null && rows !== "") {
//         ret_str += "&" + rows;
//     }
//     if (columns !== null && columns !== "") {
//         ret_str += "&" + columns;
//     }
//     return ret_str;
// }
//
// function init_group_bys() {
//     var options = {
//         tag: 'span',
//         overlap: 'horizontal',
//         constraint: 'horizontal',
//         containment: ['group_columns', 'group_rows'],
//         //only: "group_by",
//         dropOnEmpty: true,
//         format: /^(.*)$/,
//         hoverclass: 'drag_container_accept'
//     };
//     Sortable.create('group_columns', options);
//     Sortable.create('group_rows', options);
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
