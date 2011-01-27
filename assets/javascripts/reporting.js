/*
jslint nomen: true, debug: false, evil: false,
    onevar: false, browser: true, white: false, indent: 0
*/

window.Reporting = {
  source: ($$("head")[0].select("script[src*='reporting.js']")[0].src),

  require: function(libraryName) {
    alert("loading "+ libraryName);
    jsName = Reporting.source.replace("reporting.js", "reporting/" + libraryName + ".js");
    try {
      // inserting via DOM fails in Safari 2.0, so brute force approach
      document.write('<script type="text/javascript" src="' + jsName + '"><\/script>');
    } catch(e) {
      // for xhtml+xml served content, fall back to DOM methods
      var script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = jsName;
      document.getElementsByTagName('head')[0].appendChild(script);
    }
  },

  onload: function(func) {
    document.observe("dom:loaded", func);
  }
};

Reporting.require("filters");
Reporting.require("group_bys");
Reporting.require("restore_query");

//
// /*global $, selectAllOptions, moveOptions */
//
// function make_select_accept_multiple_values(select) {
//     select.multiple = true;
//     select.size = 4;
//     // first option just got selected, because THAT'S the kind of world we live in
//     select.options[0].selected = false;
// }
//
// function make_select_accept_single_value(select) {
//     select.multiple = false;
//     select.size = 1;
// }
//
// function toggle_multi_select(select) {
//     if (select.multiple === true) {
//         make_select_accept_single_value(select);
//     } else {
//         make_select_accept_multiple_values(select);
//     }
// }
//
// function change_argument_visibility(field, arg_nr) {
//     var params, i;
//     params = [$(field + '_arg_1'), $(field + '_arg_2')];
//
//     for (i = 0; i < 2; i += 1) {
//         if (params[i] !== null) {
//             if (arg_nr >= (i + 1) || arg_nr <= (-1 - i)) {
//                 params[i].show();
//             }
//             else {
//                 params[i].hide();
//             }
//         }
//     }
// }
//
// function operator_changed(field, select) {
//     var option_tag, arity;
//     if (select === null) {
//         return;
//     }
//     option_tag = select.options[select.selectedIndex];
//     arity = parseInt(option_tag.getAttribute("data-arity"), 10);
//     change_argument_visibility(field, arity);
// }
//
// function display_category(tr_field) {
//     var label = $(tr_field.getAttribute("data-label"));
//     if (label !== null) {
//         label.show();
//     }
// }
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
// function load_available_values_for_filter(filter_name, callback_func) {
//     var select;
//     select = $('' + filter_name + '_arg_1_val');
//     if (select !== null && select.readAttribute('data-loading') === "ajax" && select.childElements().length === 0) {
//         new Ajax.Updater({ success: select }, window.global_prefix + '/cost_reports/available_values', {
//             parameters: { filter_name: filter_name },
//             insertion: 'bottom',
//             evalScripts: false,
//             onCreate: function (a, b) {
//                 $('operators_' + filter_name).disable();
//                 $('' + filter_name + '_arg_1_val').disable();
//             },
//             onComplete: function (a, b) {
//                 $('operators_' + filter_name).enable();
//                 $('' + filter_name + '_arg_1_val').enable();
//                 callback_func();
//             }
//         });
//         make_select_accept_single_value(select);
//     }
//     else {
//         callback_func();
//     }
// }
//
// function show_filter_callback(field, slowly, callback_func) {
//     var field_el = $('tr_' +  field);
//     if (field_el !== null) {
//         load_available_values_for_filter(field, callback_func);
//         // the following command might be included into the callback_function (which is called after the ajax request) later
//         $('rm_' + field).value = field;
//         if (slowly) {
//             new Effect.Appear(field_el);
//         } else {
//             field_el.show();
//         }
//         operator_changed(field, $("operators_" + field));
//         display_category(field_el);
//     }
// }
//
// function show_filter(field) {
//     show_filter_callback(field, true, function () {});
// }
//
// function occupied_category(tr_field) {
//     var i, data_label, filters;
//     data_label = tr_field.getAttribute("data-label");
//     filters = document.getElementsByClassName('filter');
//     for (i = 0; i < filters.length; i += 1) {
//         if (filters[i].visible() && filters[i].getAttribute("data-label") === data_label) {
//             return true;
//         }
//     }
//     return false; //not hit
// }
//
// function hide_filter(field, slowly) {
//     var field_el, operator_select;
//     field_el = $('tr_' +  field);
//     if (field_el !== null) {
//         $('rm_' + field).value = "";
//         if (slowly) {
//             new Effect.Fade(field_el);
//         } else {
//             field_el.hide();
//         }
//         operator_select = $("operators_" + field);
//         if (operator_select !== null) {
//             // in case the filter doesn't have an operator select field'
//             operator_changed(field, $("operators_" + field));
//         }
//         if (!occupied_category(field_el)) {
//             hide_category(field_el);
//         }
//     }
// }
//
// function disable_select_option(select, field) {
//     for (var i = 0; i < select.options.length; i += 1) {
//         if (select.options[i].value === field) {
//             select.options[i].disabled = true;
//             break;
//         }
//     }
// }
//
// function enable_select_option(select, field) {
//     for (var i = 0; i < select.options.length; i += 1) {
//         if (select.options[i].value === field) {
//             select.options[i].disabled = false;
//             break;
//         }
//     }
// }
//
// function add_filter(select) {
//     var field;
//     field = select.value;
//     show_filter(field);
//     select.selectedIndex = 0;
//     disable_select_option(select, field);
// }
//
// function remove_filter(field) {
//     hide_filter(field, true);
//     enable_select_option($("add_filter_select"), field);
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
