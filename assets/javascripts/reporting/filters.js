Reporting.Filters = {
  function show_filter(field, slowly, callback_func) {
    if (callback_func == undefined) {
      callback_func = function() {};
    }
    if (slowly == undefined) {
      slowly = true;
    }
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
        load_available_values_for_filter(field, callback_func);
        // the following command might be included into the callback_function (which is called after the ajax request) later
        $('rm_' + field).value = field;
        if (slowly) {
            new Effect.Appear(field_el);
        } else {
            field_el.show();
        }
        operator_changed(field, $("operators_" + field));
        display_category(field_el);
    }
  }
}
