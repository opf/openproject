(function(Status) {
  Factory.define('Status', Status)
    .sequence('id')
    .sequence('name', function (i) {return "Status No. " + i;})
    .sequence('is_default', function (i) {return i === 0;})
    .sequence('position')
    .attr('is_closed', false);
})($injector.get('Status'));
