timelinesApp.service('TimelineService',['$rootScope', '$http', function($rootScope, $http) {
  TimelineService = {

    loadTimeline: function(timelineOptions) {
      timeline = Timeline.create(timelineOptions);
      timeline = Timeline.load(timelineOptions);

      return timeline;
    },

    startTimeline: function(timelineOptions, uiRoot) {
      // TimelineService.loadTimeline(timelineOptions);
      return Timeline.startup(timelineOptions, uiRoot);
    }
  };

  return TimelineService;
}]);
