function toggle_filter(field) {
    check_box = $('cb_' + field);
    to_toggle = check_box.up().siblings();
    
    if (check_box.checked)
      to_toggle.invoke('show');
    else
      to_toggle.invoke('hide');
}

function toggle_multi_select(field) {
    select = $('values_' + field);
    if (select.multiple === true) {
        select.multiple = false;
    } else {
        select.multiple = true;
    }
}

function operator_changed(field, select) {
  option_tag = select.options[select.selectedIndex]
  arg_count = option_tag.getAttribute("data-arg_count");
  change_argument_visibility(field, arg_count)
}

function change_argument_visibility(field, arg_nr) {
  arg1 = $(field + '_arg_1')
  arg2 = $(field + '_arg_2')
  if (arg1 != null)
    if(arg_nr == 0) arg1.hide();
    else            arg1.show();
  if (arg1 != null)
    if(arg_nr == 2) arg2.show();
    else            arg2.hide();
}

function show_filter(field) {
  if ((field_el = $('tr_' +  field)) != null) {
    field_el.show();
    check_box = $('cb_' + field);
    check_box.checked = true;
    toggle_filter(field);
    operator_changed(field, $("operators_" + field))
  }
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

