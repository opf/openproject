Factory.define('Project', Timeline.Project)
  .sequence('id')
  .sequence('name', function (i) {return "Project No. " + i;})
  .sequence('identifier', function (i) {return "projectno" + i;})
  .attr('description', 'Description for Project')
  .after(function(Project, options) {
    if(options && options.children) {
      var i;
      for (i = 0; i < options.children.length; i += 1) {
        options.children[i].project = Project;
        options.children[i].parent = Project;
        options.children[i] = Factory.build('PlanningElement', options.children[i]);
      }
    }
  });