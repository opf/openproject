function deleteDeliverableCost(id) {
  var e = $(id),
  parent = e.up();
  
  // de-register observers
  Element.stopObserving (id + '_cost_type_id')
  Element.stopObserving (id + '_units')
  
  // delete the row
  e.next().remove();
  e.remove();
  
  // fix the markup classes
  recalculate_even_odd(parent)
}

function deleteDeliverableHour(id) {
  var e = $(id),
   parent = e.up();
   
  // de-register observers
  Element.stopObserving (id + '_user_id')
  Element.stopObserving (id + '_hours')
  
  // delete the row
  e.next().remove();
  e.remove();

  // fix the markup classes
  recalculate_even_odd(parent)
}

function confirmChangeType(text, select, originalValue) {
  if (originalValue == "") {
    return true;
  }
  var ret = confirm(text);
  if (!ret) {
    select.setValue(originalValue);
  }
  return ret;
}