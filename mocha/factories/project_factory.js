function addProjectToOwnTimeline(Project) {
  if (Project && Project.timeline) {
    var t = Project.timeline;
    t.projects = t.projects || {};

    t.projects[Project.id] = Project;
  }
}

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
    }
  })
  .after(function(Project) {
    if(Project && Project.children) {
      var i;
      for (i = 0; i < Project.children.length; i += 1) {
        var current = Project.children[i];
        current.project = Project;
        current.parent = Project;
        current.timeline = Project.timeline;

        addProjectToOwnTimeline(current);

        if (!current.is(Timeline.Project)) {
          Project.children[i] = Factory.build('Project', current);
        }
      }
    }
  })
  .after(function(Project) {
    if(Project && Project.reporters) {
      var i;
      for (i = 0; i < Project.reporters.length; i += 1) {
        var current = Project.reporters[i];
        current.timeline = Project.timeline;
        addProjectToOwnTimeline(current);

        if (current.identifier !== Timeline.Reporting.identifier) {
          Project.reporters[i] = Factory.build('Reporting', current);
        }
      }
    }
  })
  .after(function (Project) {
    addProjectToOwnTimeline(Project);
  });