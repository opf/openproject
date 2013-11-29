Factory.define('PlanningElement', Timeline.PlanningElement)
  .sequence('id')
  .after(function(PlanningElement, options) {
    if(options && options.children) {
      var i;
      for (i = 0; i < options.children.length; i += 1) {
        options.children[i].Project = PlanningElement.project;
        options.children[i].parent = PlanningElement;
        options.children[i] = Factory.build('PlanningElement', options.children[i]);
      }
    }
  });