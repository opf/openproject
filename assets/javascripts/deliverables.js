var Subform = Class.create({
  lineIndex: 1,
  parentElement: "",
  initialize: function(rawHTML, lineIndex, parentElement) {
    this.rawHTML        = rawHTML;
    this.lineIndex      = lineIndex;
    this.parentElement  = parentElement;
  },
  parsedHTML: function() {
    return this.rawHTML.replace(/INDEX/g, this.lineIndex++);
  },
  add: function() {
    new Insertion.Bottom($(this.parentElement), this.parsedHTML());
  }
});



function deleteDeliverableCost(id) {
  var row = document.getElementById(id);
  
  // de-register observers
  Element.stopObserving (id + '_cost_type_id')
  Element.stopObserving (id + '_units')
  
  // delete the row
  Element.remove(row);
}

function deleteDeliverableHour(id) {
  var row = document.getElementById(id);
  
  // de-register observers
  Element.stopObserving (id + '_user_id')
  Element.stopObserving (id + '_hours')
  
  // delete the row
  Element.remove(row);
}
