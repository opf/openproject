Factory.define('Reporting', Timeline.Reporting)
  .sequence('id')
  .attr("project", function () {return Factory.build("Project");})
  .attr("reporting_to_project", function () {return Factory.build("Project");})
  .attr("reported_project_status", function () {return Factory.build("ProjectStatus");})
  .attr("reported_project_status_comment", "")
  .attr('created_at')
  .attr('updated_at');