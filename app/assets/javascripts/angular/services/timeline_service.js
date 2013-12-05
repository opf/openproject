timelinesApp.service('TimelineService', ['$q', '$rootScope', function($q, $rootScope) {
  deferred = $q.defer();

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

        jQuery(timelineLoader).on('complete', function(e, data) {
          jQuery.extend(timeline, data);
          deferred.resolve(timeline);
          $rootScope.$broadcast('timelines.dataLoaded');
        });

        timeline.safetyHook = window.setTimeout(function() {
          timeline.die(timeline.i18n('timelines.errors.report_timeout'));
          deferred.reject(timeline.i18n('timelines.errors.report_timeout'));
        }, Timeline.LOAD_ERROR_TIMEOUT);

        timelineLoader.load();

      } catch (e) {
        timeline.die(e);
        deferred.reject(e);
      }
      return deferred.promise;
    },
    startTimeline: function(timelineOptions, uiRoot) {
      // TimelineService.loadTimeline(timelineOptions);
      return Timeline.startup(timelineOptions, uiRoot);
    }
  };

  return TimelineService;
}]);
