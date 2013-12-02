timelinesApp.service('TimelineService',['$rootScope', '$http', function($rootScope, $http) {
  TimelineService = {

    loadTimeline: function(timelineOptions) {
      return Timeline.startup(timelineOptions);
    }
  };

  return TimelineService;
}]);
