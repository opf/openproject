function addRate(date_field){
  RatesForm.add_on_top();

  var newRateRow = $(RatesForm.parentElement).down("tr");
  var validFromField = newRateRow.down('input.date')
  validFromField.value = jQuery.datepicker.formatDate('yy-mm-dd', new Date());
  newRateRow.down('td.currency').down('input').select();
}

function deleteRow(image){
  var row = image.up("tr")
  var parent=row.up();
  row.remove();
  recalculate_even_odd(parent);
}

jQuery(function(jQuery){
  jQuery(document).on("click", "body.action-edit img.delete", function(){
    deleteRow(this);
  });
});
