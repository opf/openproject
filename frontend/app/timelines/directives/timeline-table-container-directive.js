//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(TimelineLoaderService, TimelineTableHelper, SvgHelper, PathHelper) {

  return {
    restrict: 'E',
    replace: true,
    require: '^timelineContainer',
    templateUrl: '/templates/timelines/timeline_table_container.html',
    scope: { timeline: '=' },
    link: function(scope, element, attributes, timelineContainerCtrl) {
      // Hide charts until tables are drawn
      scope.underConstruction = true;

      function showWarning() {
        scope.underConstruction = false;
        scope.warning = true;
        scope.$apply();
      }

      function showError(errorMessage) {
        scope.underConstruction = false;
        timelineContainerCtrl.showError(errorMessage);
      }

      function fetchData() {
        return TimelineLoaderService.loadTimelineData(scope.timeline);
      }

      function completeUI() {
        var paperElement  = jQuery('#timeline-container-' + scope.timeline.id + ' .tl-chart')[0];
        scope.timeline.paper = new SvgHelper(paperElement);

        // perform some zooming. if there is a zoom level stored with the
        // report, zoom to it. otherwise, zoom out. this also constructs
        // timeline graph.
        scope.timeline.zoom(scope.timeline.zoomIndex);

        scope.underConstruction = false;
        scope.warning = false;

        scope.timeline.getChart().scroll(function() {
          scope.timeline.adjustTooltip();
        });

        jQuery(window).scroll(function() {
          scope.timeline.adjustTooltip();
        });
      }

      function buildWorkPackageTable(timeline){
        timeline.lefthandTree = null; // reset cached data tree

        var tree = timeline.getLefthandTree();

        if (tree.containsPlanningElements() || tree.containsProjects()) {
          timeline.adjustForPlanningElements();
          scope.rows = TimelineTableHelper.getTableRowsFromTimelineTree(tree, timeline.options);
        } else{
          scope.rows = [];
        }

        return scope.rows;
      }

      function drawChart(tree) {
        var timeline = scope.timeline;

        try {
          window.clearTimeout(timeline.safetyHook);

          if (scope.rows.length > 0) {
            completeUI();
          } else {
            timeline.warn(I18n.t('js.label_no_data'), 'warning', showWarning);
          }
        } catch (e) {
          timeline.die(e);
        }
      }

      function renderTimeline() {
        return fetchData()
          .then(buildWorkPackageTable)
          .then(drawChart, showError);
      }

      function reloadTimeline() {
        return fetchData()
          .then(buildWorkPackageTable)
          .then(function() {
            if (scope.currentOutlineLevel) {
              scope.timeline.expandToOutlineLevel(scope.currentOutlineLevel); // also triggers rebuildAll()
            } else {
              scope.timeline.rebuildAll();
            }
          }, showError);
      }

      function registerModalHelper() {
        scope.timeline.modalHelper = modalHelperInstance;

        scope.timeline.modalHelper.setupTimeline(
          scope.timeline,
          {
            url_prefix                : PathHelper.staticBase,
            project_prefix            : '/projects'
          }
        );

        jQuery(scope.timeline.modalHelper).on('closed', function() {
          reloadTimeline().then(function() {
            window.clearTimeout(scope.timeline.safetyHook);
          });
          // TODO remove and do updates via scope
        });
      }

      // start timeline
      scope.timeline.registerTimelineContainer(element);
      registerModalHelper();

      renderTimeline();
    }
  };
};
