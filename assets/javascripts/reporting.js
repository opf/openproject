function toggle_filter(field) {
    check_box = $('cb_' + field);
    to_toggle = check_box.up().nextSiblings()
    
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

function operator_changed(field) {
  //TODO: this method should update the fields after the id="operator_field"-element depending on the selected operator
}

function add_filter() {
    select = $('add_filter_select');
    field = select.value
    Element.show('tr_' +  field);
    check_box = $('cb_' + field);
    check_box.checked = true;
    toggle_filter(field);
    select.selectedIndex = 0;

    for (i=0; i<select.options.length; i++) {
        if (select.options[i].value == field) {
            select.options[i].disabled = true;
            break;
        }
    }
}
