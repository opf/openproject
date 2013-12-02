Factory.define('Project', Timeline.Project)
  .sequence('id')
  .sequence('name', function (i) {return "Project No. " + i;})
  .sequence('identifier', function (i) {return "projectno" + i;})
  .attr('description', 'Description for Project')
  .after(function(Project) {
    if(Project && Project.planning_elements) {
      var i;
      for (i = 0; i < Project.planning_elements.length; i += 1) {
        var current = Project.planning_elements[i];
        current.project = Project;
        current.parent = Project;
        current.timeline = Project.timeline;

        if (!Timeline.PlanningElement.is(current)) {
          Project.planning_elements[i] = Factory.build('PlanningElement', current);
        }
      }

      Project.planning_elements = Project.planning_elements;
    }
  })
  .after(function(Project) {
    if(Project && Project.reporters) {
      var i;
      for (i = 0; i < Project.reporters.length; i += 1) {
        var current = Project.reporters[i];
        current.timeline = Project.timeline;

        if (current.identifier !== Timeline.Reporting.identifier) {
          Project.reporters[i] = Factory.build('Reporting', current);
        }
      }

      Project.reporters = Project.reporters;
    }
  });