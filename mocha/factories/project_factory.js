var projectFactory = {
  create: function (options) {
    return jQuery.extend(Object.create(Timeline.Project), options);
  }
}