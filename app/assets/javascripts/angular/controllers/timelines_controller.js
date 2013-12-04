timelinesApp.controller('TimelinesController', ['$scope', '$window', 'TimelineService', function($scope, $window, TimelineService){

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  // Setup
  $scope.slider = null;
  $scope.timelineContainerNo = 1;
  $scope.currentOutlineLevel = 'level3';
  $scope.currentScale = 'monthly';


  // Get server-side stuff into scope
  $scope.currentTimelineId = gon.current_timeline_id;
  $scope.timelines = gon.timelines;
  $scope.timelineOptions = angular.extend(gon.timeline_options, { i18n: gon.timeline_translations });

  // Get timelines stuff into scope
  $scope.Timeline = Timeline;


  // Container for timeline rendering
  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };
  $scope.getTimelineContainer = function() {
    return angular.element(document.querySelector('#' + $scope.getTimelineContainerElementId()));
  };







  $scope.updateToolbar = function() {
    $scope.slider.slider('value', $scope.timeline.zoomIndex + 1);
    $scope.currentOutlineLevel = Timeline.OUTLINE_LEVELS[$scope.timeline.expansionIndex];
    $scope.currentScale = Timeline.ZOOM_SCALES[$scope.timeline.zoomIndex];
  };

  $scope.$on('timelines.dataLoaded', function(){
    tree = null;
    try {
      window.clearTimeout($scope.timeline.safetyHook);

      if ($scope.timeline.isGrouping() && $scope.timeline.options.grouping_two_enabled) {
        $scope.timeline.secondLevelGroupingAdjustments();
      }

      tree = $scope.timeline.getLefthandTree();
      if (tree.containsPlanningElements() || tree.containsProjects()) {
        $scope.timeline.adjustForPlanningElements();
        $scope.completeUI();
      } else {
        $scope.timeline.warn(this.i18n('label_no_data'), 'warning');
      }
    } catch (e) {
      $scope.timeline.die(e);
    }
  });

  $scope.completeUI = function() {
    // construct tree on left-hand-side.
    $scope.timeline.rebuildTree();

    // lift the curtain, paper otherwise doesn't show w/ VML.
    jQuery('.timeline').removeClass('tl-under-construction');
    $scope.timeline.paper = new Raphael($scope.timeline.paperElement, 640, 480);

    // perform some zooming. if there is a zoom level stored with the
    // report, zoom to it. otherwise, zoom out. this also constructs
    // timeline graph.
    if ($scope.timeline.options.zoom_factor &&
        $scope.timeline.options.zoom_factor.length === 1) {

      $scope.timeline.zoom(
        $scope.timeline.pnum($scope.timeline.options.zoom_factor[0])
      );

    } else {
      $scope.timeline.zoomOut();
    }

    // perform initial outline expansion.
    if ($scope.timeline.options.initial_outline_expansion &&
        $scope.timeline.options.initial_outline_expansion.length === 1) {

      $scope.timeline.expandTo(
        $scope.timeline.pnum($scope.timeline.options.initial_outline_expansion[0])
      );
    }

    // zooming and initial outline expansion have consequences in the
    // select inputs in the toolbar.
    $scope.updateToolbar();

    $scope.timeline.getChart().scroll(function() {
      $scope.timeline.adjustTooltip();
    });

    jQuery(window).scroll(function() {
      $scope.timeline.adjustTooltip();
    });
  };






  // Load timeline
  $scope.timeline = TimelineService.createTimeline($scope.timelineOptions);

  angular.element(document).ready(function() {
    // start timeline
    $scope.timeline.registerTimelineContainer($scope.getTimelineContainer());
    TimelineService.loadTimelineData($scope.timeline);

    // $scope.timeline = TimelineService.startTimeline($scope.timelineOptions, $scope.getTimelineContainer());

    // Update toolbar values (TODO: Load timeline previously & refactor)
    // $scope.updateToolbar();

  });
}]);
