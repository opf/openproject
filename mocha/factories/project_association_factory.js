Factory.define('ProjectAssociation', Timeline.ProjectAssociation)
  .sequence('id')
  .sequence("to_project_id")
  .attr("description", "");