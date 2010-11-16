function deleteBudgetItem(id, field) {
  $(id + '_' + field).value = 0;
  $(id).hide();
}

function deleteMaterialBudgetItem(id) { deleteBudgetItem(id, 'units') }
function deleteLaborBudgetItem(id) { deleteBudgetItem(id, 'hours') }

function confirmChangeType(text, select, originalValue) {
  if (originalValue == "") return true;
  var ret = confirm(text);
  if (!ret) select.setValue(originalValue);
  return ret;
}
