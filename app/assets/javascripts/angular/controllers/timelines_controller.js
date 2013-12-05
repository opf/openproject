timelinesApp.controller('TimelinesController', ['$scope', '$window', 'TimelineService', function($scope, $window, TimelineService){

  $scope.switchTimeline = function() {
    $window.location.href = $scope.timelines[$scope.currentTimelineId].path;
  };

  // Setup

  // Get server-side stuff into scope
  $scope.currentTimelineId = gon.current_timeline_id;
  $scope.timelines = gon.timelines;


  $scope.timelineOptions = angular.extend(gon.timeline_options, { i18n: gon.timeline_translations });
  $scope.timelineOptions.initial_outline_expansion || ($scope.timelineOptions.initial_outline_expansion = '3');


  // Get timelines stuff into scope
  $scope.Timeline = Timeline;
  $scope.slider = null;
  $scope.timelineContainerNo = 1;
  $scope.underConstruction = true;
  $scope.currentOutlineLevel = 'level3';
  $scope.currentScaleName = 'monthly';

  // Load timeline
  $scope.timeline = TimelineService.createTimeline($scope.timelineOptions);
  $scope.treeNode = $scope.timeline.getLefthandTree();


  // Container for timeline rendering
  $scope.getTimelineContainerElementId = function() {
    return 'timeline-container-' + $scope.timelineContainerNo;
  };
  $scope.getTimelineContainer = function() {
    return angular.element(document.querySelector('#' + $scope.getTimelineContainerElementId()));
  };

  $scope.$watch('currentScaleName', function(newScaleName, oldScaleName){
    if (newScaleName !== oldScaleName) {
      $scope.currentScale = Timeline.ZOOM_CONFIGURATIONS[$scope.currentScaleName].scale;
      $scope.timeline.scale = $scope.currentScale;

      $scope.currentScaleIndex = Timeline.ZOOM_SCALES.indexOf($scope.currentScaleName);
      $scope.slider.slider('value', $scope.currentScaleIndex + 1);

      $scope.timeline.zoom($scope.currentScaleIndex); // TODO replace event-driven adaption by bindings
    }
  });

  $scope.$watch('currentOutlineLevel', function(outlineLevel, formerLevel) {
    if (outlineLevel !== formerLevel) {
      $scope.timeline.expansionIndex = Timeline.OUTLINE_LEVELS.indexOf(outlineLevel);
      $scope.timeline.expandToOutlineLevel(outlineLevel); // TODO replace event-driven adaption by bindings
    }
  });

  $scope.increaseZoom = function() {
    if($scope.currentScaleIndex < Object.keys(Timeline.ZOOM_CONFIGURATIONS).length - 1) {
      $scope.currentScaleIndex++;
    }
  };
  $scope.decreaseZoom = function() {
    if($scope.currentScaleIndex > 0) {
      $scope.currentScaleIndex--;
    }
  };

  $scope.updateToolbar = function() {
    $scope.slider.slider('value', $scope.timeline.zoomIndex + 1);
    $scope.currentOutlineLevel = Timeline.OUTLINE_LEVELS[$scope.timeline.expansionIndex];
    $scope.currentScaleName = Timeline.ZOOM_SCALES[$scope.timeline.zoomIndex];
  };


  drawTimeline = function(timeline){
    try {
      window.clearTimeout(timeline.safetyHook);

      if (timeline.isGrouping() && timeline.options.grouping_two_enabled) {
        timeline.secondLevelGroupingAdjustments();
      }

      treeNode = timeline.getLefthandTree();
      if (treeNode.containsPlanningElements() || treeNode.containsProjects()) {
        timeline.adjustForPlanningElements();
        completeUI();
      } else {
        timeline.warn(this.i18n('label_no_data'), 'warning');
      }
    } catch (e) {
      timeline.die(e);
    }
  };

  completeUI = function() {
    // construct tree on left-hand-side.
    $scope.timeline.rebuildTree();

    // lift the curtain, paper otherwise doesn't show w/ VML.
    $scope.underConstruction = false;
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

  $scope.$on('timelines.dataLoaded', function(){
    $scope.$apply();
  });

  angular.element(document).ready(function() {
    // start timeline
    $scope.timeline.registerTimelineContainer($scope.getTimelineContainer());
    TimelineService.loadTimelineData($scope.timeline).then(drawTimeline);

    // TimelineService.loadTimelineData($scope.timeline).then($scope.outputStuff);

    // $scope.timeline = TimelineService.startTimeline($scope.timelineOptions, $scope.getTimelineContainer());

    // Update toolbar values (TODO: Load timeline previously & refactor)
    // $scope.updateToolbar();

  });
}]);
