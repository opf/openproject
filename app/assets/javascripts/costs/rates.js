function addRate(date_field) {
  var my_date = date_field.value;
  var date_elements = $(RatesForm.parentElement).select('input.date');
  
  var highest_date = null;
  for (var e in date_elements) {
    if (e.value > my_date) {
      highest_date = e;
    } else {
      break;
    }
  }
  
  switch (highest_date) {
    case null:
      RatesForm.add_on_top()
      var e = $(RatesForm.parentElement).down("tr");
      break;
    default:
      var after = highest_date.up('tr');
      RatesForm.add_after(after);
      var e = after.next();
      break;
  }
  
  var new_date_field = e.down('input.date')
  new_date_field.value = date_field.value;
  date_field.value = "";
  e.down('td.currency').down('input').select();
}