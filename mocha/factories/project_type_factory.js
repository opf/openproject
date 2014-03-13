(function(ProjectType) {
  Factory.define('ProjectType', ProjectType)
    .sequence('id')
    .sequence('name', function (i) {return "Project Type No. " + i;})
    .sequence('position')
    .attr('allows_association', true)
    .attr('created_at')
    .attr('updated_at');
})($injector.get('ProjectType'));
