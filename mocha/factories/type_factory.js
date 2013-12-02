Factory.define('PlanningElementType', Timeline.PlanningElementType)
  .sequence('id')
  .sequence('name', function (i) {return "Type No. " + i;})
  .sequence('is_default', function (i) {return i === 0;})
  .sequence('position')
  .attr('in_aggregation', false)
  .attr('is_milestone', false)
  .attr('is_closed', false);