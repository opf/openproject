timelinesApp.service('TimelineService',['$rootScope', '$http', function($rootScope, $http) {
  TimelineService = {
    createTimeline: function(timelineOptions) {
      return Timeline.create(timelineOptions);
    },
    loadTimelineData: function(timeline) {
      timelineLoader = null;

      try {
        // prerequisites (3rd party libs)
        timeline.checkPrerequisites();
        timeline.modalHelper = modalHelperInstance;
        timeline.modalHelper.setupTimeline(
          timeline,
          {
            api_prefix                : timeline.options.api_prefix,
            url_prefix                : timeline.options.url_prefix,
            project_prefix            : timeline.options.project_prefix
          }
        );

        jQuery(timeline.modalHelper).on("closed", function () {
          timeline.reload();
        });

        timelineLoader = timeline.provideTimelineLoader();

        jQuery(timelineLoader).on('complete', jQuery.proxy(function(e, data) {
          jQuery.extend(timeline, data);
          $rootScope.$broadcast('timelines.dataLoaded');
          // timeline.defer(jQuery.proxy(timeline, 'onLoadComplete'),
          //            timeline.options.artificial_load_delay);
        }, timeline));

        timeline.safetyHook = window.setTimeout(function() {
          timeline.die(timeline.i18n('timelines.errors.report_timeout'));
        }, Timeline.LOAD_ERROR_TIMEOUT);

        timelineLoader.load();

        return timeline;
      } catch (e) {
        timeline.die(e);
      }
    },
    startTimeline: function(timelineOptions, uiRoot) {
      // TimelineService.loadTimeline(timelineOptions);
      return Timeline.startup(timelineOptions, uiRoot);
    }
  };

  return TimelineService;
}]);
