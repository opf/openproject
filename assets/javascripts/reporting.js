function toggle_filter(field) {
    check_box = $('cb_' + field);
    to_toggle = check_box.up().siblings();
    
    if (check_box.checked)
      to_toggle.invoke('show');
    else
      to_toggle.invoke('hide');
}

function toggle_multi_select(select) {
    if (select.multiple === true) {
        select.multiple = false;
    } else {
        select.multiple = true;
    }
}

function operator_changed(field, select) {
  option_tag = select.options[select.selectedIndex]
  arity = option_tag.getAttribute("data-arity");
  change_argument_visibility(field, arity)
}

function change_argument_visibility(field, arg_nr) {
  arg1 = $(field + '_arg_1')
  arg2 = $(field + '_arg_2')
  if (arg1 != null)
    if(arg_nr == 0) arg1.hide();
    else arg1.show();
  if (arg2 != null)
    if(arg_nr >= 2 || arg_nr <= -2) arg2.show();
    else arg2.hide();
}

function show_filter(field) {
  if ((field_el = $('tr_' +  field)) != null) {
    field_el.show();
    check_box = $('cb_' + field);
    check_box.checked = true;
    toggle_filter(field);
    operator_changed(field, $("operators_" + field))
    display_category(field_el)
  }
}

function display_category(tr_field) {
  if ((label = $(tr_field.getAttribute("data-label"))) != null)
    label.show();
}

function disable_select_option(select, field) {
  for (i=0; i<select.options.length; i++) {
    if (select.options[i].value == field) {
      select.options[i].disabled = true;
      break;
    }
  }
}

function add_filter(select) {
  field = select.value;
  show_filter(field);
  select.selectedIndex = 0;
  disable_select_option(select,field);
}

function show_group_by(group_by, target) {
  source = $("group_by_container");
  group_option = null;
  // find group_by option-tag in target select-box
  for (var i=0; i<source.options.length; i++) {
    if (source.options[i].value == group_by) {
      group_option = source.options[i];
      source.options[i] = null;
      break;
    }
  }
  // die if the appropriate option-tag can not be found
  if (group_option == null)
    return;
  // move the option-tag to the taget select-box while keepings its data
  target.options[target.length] = group_option;
}

function select_operator(field, operator) {
  select = $("operators_" + field);
  for (var i=0; i<select.options.length; i++) {
    if (select.options[i].value == operator) {
      select.selectedIndex = i;
      break;
    }
  }
  operator_changed(field, select);
}

function restore_select_values(select, values) {
  if (values.length > 1)
      select.multiple = true;
  for (var i = 0; i < values.length; i++)
    for (var j = 0; j < select.options.length; j++)
      if (select.options[j].value == values[i])
        select.options[j].selected = true;
}

function find_arguments(field) {
  var arguments = new Array();
  var arg_count = 0;
  var arg = null;
  while (arg = $(field + '_arg_' + (arg_count + 1) + '_val')) {
    arguments[arguments.length] = arg;
    arg_count++;
  }
  return arguments;
}

function restore_values(field, values) {
  var op_select = $("operators_" + field);
  var op_arity = op_select.options[op_select.selectedIndex].getAttribute("data-arity");
  var arguments = find_arguments(field);

  if (!Object.isArray(values))
    values = [values];
  if (op_arity < 0)
    restore_select_values(arguments[0], values);
  else
    for (var i = 0; i < values.length && i < arguments.length; i++)
      arguments[i].setValue(values[i]);
}

function restore_filter(field, operator, values) {
  select_operator(field, operator);
  if(typeof(values) != "undefined")
    restore_values(field, values);
  disable_select_option($("add_filter_select"), field);
  show_filter(field);
}

function show_group_by_column(group_by) {
  show_group_by(group_by, $('group_by_columns'));
}

function show_group_by_row(group_by) {
  show_group_by(group_by, $('group_by_rows'));
}
