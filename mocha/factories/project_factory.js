Factory.define('Project', Timeline.Project)
  .sequence('id')
  .sequence('name', function (i) {return "Project No. " + i;})
  .sequence('identifier', function (i) {return "projectno" + i;})
  .attr('description', '');