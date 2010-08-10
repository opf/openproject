function deleteMaterialBudgetItem(id) {
  $(id + '_units').value = 0;
  $(id).hide();
}

function deleteLaborBudgetItem(id) {
  $(id + '_hours').value = 0;
  $(id).hide();
}

function confirmChangeType(text, select, originalValue) {
  if (originalValue == "") return true;
  var ret = confirm(text);
  if (!ret) select.setValue(originalValue);
  return ret;
}
