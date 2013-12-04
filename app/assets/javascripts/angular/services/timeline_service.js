timelinesApp.service('TimelineService',['$rootScope', '$http', function($rootScope, $http) {
  TimelineService = {
    createTimeline: function(timelineOptions) {
      return Timeline.create(timelineOptions);
    },
    startTimeline: function(timelineOptions, uiRoot) {
      // TimelineService.loadTimeline(timelineOptions);
      return Timeline.startup(timelineOptions, uiRoot);
    }
  };

  return TimelineService;
}]);
