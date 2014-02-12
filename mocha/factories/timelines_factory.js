Factory.define('Timeline', Timeline)
  .attr("options", Timeline.defaults)
  .attr("projects", {})
  .after(function (Timeline, options) {
    if (options) {
      Timeline.options = options;
    }
  });