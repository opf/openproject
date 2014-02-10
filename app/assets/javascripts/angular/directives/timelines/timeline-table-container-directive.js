angular.module('openproject.timelines.directives')

.directive('timelineTableContainer', ['TimelineLoaderService', 'TimelineTableHelper', function(TimelineLoaderService, TimelineTableHelper) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/timelines/timeline_table_container.html',
    link: function(scope, element, attributes) {
      completeUI = function() {
        // lift the curtain, paper otherwise doesn't show w/ VML.
        scope.underConstruction = false;
        scope.timeline.paper = new Raphael(scope.timeline.paperElement, 640, 480);

        // perform some zooming. if there is a zoom level stored with the
        // report, zoom to it. otherwise, zoom out. this also constructs
        // timeline graph.
        if (scope.timeline.options.zoom_factor &&
            scope.timeline.options.zoom_factor.length === 1) {
          scope.timeline.zoom(
            scope.timeline.pnum(scope.timeline.options.zoom_factor[0])
          );
        } else {
          scope.timeline.zoomOut();
        }

        // perform initial outline expansion.
        if (scope.timeline.options.initial_outline_expansion &&
            scope.timeline.options.initial_outline_expansion.length === 1) {

          scope.timeline.expandTo(
            scope.timeline.pnum(scope.timeline.options.initial_outline_expansion[0])
          );
        }

        // zooming and initial outline expansion have consequences in the
        // select inputs in the toolbar.
        if(scope.updateToolbar) scope.updateToolbar();

        scope.timeline.getChart().scroll(function() {
          scope.timeline.adjustTooltip();
        });

        jQuery(window).scroll(function() {
          scope.timeline.adjustTooltip();
        });
      };

      buildWorkPackageTable = function(timeline){
        if (timeline.isGrouping() && timeline.options.grouping_two_enabled) {
          timeline.secondLevelGroupingAdjustments();
        }

        tree = timeline.getLefthandTree();

        if (tree.containsPlanningElements() || tree.containsProjects()) {
          timeline.adjustForPlanningElements();
          scope.rows = TimelineTableHelper.getTableRowsFromTimelineTree(tree, timeline.options);
        } else{
          scope.rows = [];
        }

        return scope.rows;
      };

      drawChart = function(tree) {
        timeline = scope.timeline;

        try {
          window.clearTimeout(timeline.safetyHook);

          if (rows.length > 0) {
            completeUI();
          } else {
            timeline.warn(I18n.t('js.label_no_data'), 'warning');
          }
        } catch (e) {
          timeline.die(e);
        }
      };

      // start timeline
      scope.timeline.registerTimelineContainer(element);

      TimelineLoaderService.loadTimelineData(scope.timeline)
        .then(buildWorkPackageTable)
        .then(drawChart);
    }
  };
}]);
