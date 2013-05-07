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
    var e = $(this.parentElement);
    Element.insert(e, { bottom: this.parsedHTML()});
    recalculate_even_odd(e);
  },
  
  add_after: function(e) {
    Element.insert(e, { after: this.parsedHTML()});
    recalculate_even_odd($(this.parentElement));
  },
  
  add_on_top: function() {
    var e = $(this.parentElement);
    Element.insert(e, { top: this.parsedHTML()});
    recalculate_even_odd(e);
  }
});

function recalculate_even_odd(element) {
  $A(element.childElements()).inject(
    0,
    function(acc, e)
    {
      e.removeClassName("even");
      e.removeClassName("odd");
      e.addClassName( (acc%2==0) ? "odd" : "even"); return ++acc;
    }
  )
}
