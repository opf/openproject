/*global $, selectAllOptions, moveOptions */

function toggle_filter(field) {
    var remove, to_toggle;
    remove = $('rm_' + field);
    to_toggle = remove.up().siblings();
    if (remove.visible()) {
        to_toggle.invoke('show');
    }
    else {
        to_toggle.invoke('hide');
    }
}

function make_select_accept_multiple_values(select) {
    select.multiple = true;
    select.size = 4;
}

function make_select_accept_single_value(select) {
    select.multiple = false;
    select.size = 1;
}

function toggle_multi_select(select) {
    if (select.multiple === true) {
        make_select_accept_single_value(select);
    } else {
        make_select_accept_multiple_values(select);
    }
}

function change_argument_visibility(field, arg_nr) {
    var params, i;
    params = [$(field + '_arg_1'), $(field + '_arg_2')];

    for (i = 0; i < 2; i++) {
        if (params[i] !== null) {
            if (arg_nr >= (i + 1) || arg_nr <= (-1 - i) ) {
                params[i].show();
            }
            else {
                params[i].hide();
            }
        }
    }
}

function operator_changed(field, select) {
    var option_tag, arity;
    option_tag = select.options[select.selectedIndex];
    arity = parseInt(option_tag.getAttribute("data-arity"));
    change_argument_visibility(field, arity);
}

function display_category(tr_field) {
    var label = $(tr_field.getAttribute("data-label"));
    if (label !== null) {
        label.show();
    }
}

function show_filter(field) {
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
        field_el.show();
        toggle_filter(field);
        $('rm_' + field).value = field;
        operator_changed(field, $("operators_" + field));
        display_category(field_el);
    }
}

function hide_filter(field) {
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
        $('rm_' + field).value = "";
        field_el.hide();
        toggle_filter(field);
        operator_changed(field, $("operators_" + field));
    }
}

function disable_select_option(select, field) {
    for (var i = 0; i < select.options.length; i++) {
        if (select.options[i].value == field) {
            select.options[i].disabled = true;
            break;
        }
    }
}

function enable_select_option(select, field) {
    for (var i = 0; i < select.options.length; i++) {
        if (select.options[i].value == field) {
            select.options[i].disabled = false;
            break;
        }
    }
}

function add_filter(select) {
    var field;
    field = select.value;
    show_filter(field);
    select.selectedIndex = 0;
    disable_select_option(select, field);
}

function remove_filter(field) {
    hide_filter(field);
    enable_select_option($("add_filter_select"), field);
}

function show_group_by(group_by, target) {
    var source, group_option, i;
    source = $("group_by_container");
    group_option = null;
    // find group_by option-tag in target select-box
    for (i = 0; i < source.options.length; i++) {
        if (source.options[i].value == group_by) {
            group_option = source.options[i];
            source.options[i] = null;
            break;
        }
    }
    // die if the appropriate option-tag can not be found
    if (group_option === null) {
        return;
    }
    // move the option-tag to the taget select-box while keepings its data
    target.options[target.length] = group_option;
}

function select_operator(field, operator) {
    var select, i;
    select = $("operators_" + field);
    for (i = 0; i < select.options.length; i++) {
        if (select.options[i].value == operator) {
            select.selectedIndex = i;
            break;
        }
    }
    operator_changed(field, select);
}

function restore_select_values(select, values) {
    var i, j;
    if (values.length > 1) {
        make_select_accept_multiple_values(select);
    } else {
        make_select_accept_single_value(select);
    }
    for (i = 0; i < values.length; i++) {
        for (j = 0; j < select.options.length; j++) {
            if (select.options[j].value == values[i]) {
                select.options[j].selected = true;
            }
        }
    }
}

function find_arguments(field) {
    var args = [], arg_count = 0, arg = null;
    arg = $(field + '_arg_' + (arg_count + 1) + '_val');
    while (arg !== null) {
        args[args.length] = arg;
        arg_count++;
        arg = $(field + '_arg_' + (arg_count + 1) + '_val');
    }
    return args;
}

function restore_values(field, values) {
    var op_select, op_arity, args, i;
    op_select = $("operators_" + field);
    op_arity = op_select.options[op_select.selectedIndex].getAttribute("data-arity");
    args = find_arguments(field);

    if (!Object.isArray(values)) {
        values = [values];
    }
    if (op_arity < 0) {
        restore_select_values(args[0], values);
    } else {
        for (i = 0; i < values.length && i < args.length; i++) {
            args[i].setValue(values[i]);
        }
    }
}

function restore_filter(field, operator, values) {
    select_operator(field, operator);
    disable_select_option($("add_filter_select"), field);
    show_filter(field);
    if (typeof(values) != "undefined") {
        restore_values(field, values);
    }
}

function show_group_by_column(group_by) {
    show_group_by(group_by, $('group_by_columns'));
}

function show_group_by_row(group_by) {
    show_group_by(group_by, $('group_by_rows'));
}

function disable_all_filters() {
    $('filter_table').down().childElements().each(function (e) {
        var field, possible_select;
        e.hide();
        if (e.readAttribute('class') == 'filter') {
            field = e.id.gsub('tr_', '');
            hide_filter(field);
            possible_select = $(field + '_arg_1_val');
            if (possible_select !== null && possible_select.type.include('select')) {
                make_select_accept_single_value(possible_select);
            }
        }
    });
}

function disable_all_group_bys() {
    var destination;
    destination = $('group_by_container');
    [$('group_by_columns'), $('group_by_rows')].each(function (origin) {
        selectAllOptions(origin);
        moveOptions(origin, destination);
    });
}
