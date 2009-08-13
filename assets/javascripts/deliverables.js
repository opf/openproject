function deleteDeliverableCostsEntry(id) {
  var row = document.getElementById(id);
  
  // de-register observers
  Element.stopObserving (id + '_cost_type_id')
  Element.stopObserving (id + '_units')
  
  // delete the row
  Element.remove(row);
}

function deleteDeliverableHoursEntry(id) {
  var row = document.getElementById(id);
  
  // de-register observers
  Element.stopObserving (id + '_user_id')
  Element.stopObserving (id + '_hours')
  
  // delete the row
  Element.remove(row);
}
