timelinesApp.directive('timeline', function() {
  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      updateToolbar = function() {
        scope.slider.slider('value', scope.timeline.zoomIndex + 1);
        scope.currentOutlineLevel = Timeline.OUTLINE_LEVELS[scope.timeline.expansionIndex];
        scope.currentScaleName = Timeline.ZOOM_SCALES[scope.timeline.zoomIndex];
      };

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
        updateToolbar();

        scope.timeline.getChart().scroll(function() {
          scope.timeline.adjustTooltip();
        });

        jQuery(window).scroll(function() {
          scope.timeline.adjustTooltip();
        });
      };

      buildTree = function(timeline){
        if (timeline.isGrouping() && timeline.options.grouping_two_enabled) {
          timeline.secondLevelGroupingAdjustments();
        }

        tree = timeline.getLefthandTree();

        scope.availableRows = timeline.getAvailableRows();
        scope.nodes = flattenTree(tree);
        scope.nodes.unshift(tree);

        return tree;
      };


      flattenTree = function(tree) {
        nodes = [];

        angular.forEach(tree.childNodes, function(node){
          nodes.push(node);
          nodes = nodes.concat(flattenTree(node));
        });

        return nodes;
      };

      drawTree = function(tree) {
        console.log('-------- Draw tree --------');

        timeline = scope.timeline;

        try {
          window.clearTimeout(timeline.safetyHook);

          if (tree.containsPlanningElements() || tree.containsProjects()) {
            timeline.adjustForPlanningElements();
            completeUI();
          } else {
            timeline.warn(this.i18n('label_no_data'), 'warning');
          }
        } catch (e) {
          timeline.die(e);
        }

      };

      // start timeline
      scope.timeline.registerTimelineContainer(element);
      TimelineLoaderService.loadTimelineData(scope.timeline)
        .then(buildTree)
        .then(drawTree)
        .then(function(){
          scope.dataLoaded = true;
        });
    }
  };
});

