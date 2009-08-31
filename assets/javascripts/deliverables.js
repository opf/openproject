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
    var e = $(this.parentElement)
    new Insertion.Bottom(e, this.parsedHTML());
    recalculate_even_odd(e)
  }
});

function recalculate_even_odd(element) {
  $A(element.childElements()).inject(
    0,
    function(acc, e)
    {
      e.removeClassName("even");
      e.removeClassName("odd");
      e.addClassName( (Math.floor(acc/2)%2==0) ? "odd" : "even"); return ++acc;
    }
  )
}

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
