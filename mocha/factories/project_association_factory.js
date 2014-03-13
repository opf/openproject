(function(ProjectAssociation) {
  Factory.define('ProjectAssociation', ProjectAssociation)
    .sequence('id')
    .sequence("to_project_id")
    .attr("description", "");
})($injector.get('ProjectAssociation');
