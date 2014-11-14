//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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

module.exports = function(TimelineLoaderService, TimelineTableHelper, SvgHelper) {

  return {
    restrict: 'E',
    replace: true,
    require: '^timelineContainer',
    templateUrl: '/templates/timelines/timeline_table_container.html',
    link: function(scope, element, attributes, timelineContainerCtrl) {

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

        scope.timeline.paper = new SvgHelper(scope.timeline.paperElement);

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

        if (timeline.isGrouping() && timeline.options.grouping_two_enabled) {
          timeline.secondLevelGroupingAdjustments();
        }

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
              scope.rebuildAll();
            }
          }, showError);
      }

      function registerModalHelper() {
        scope.timeline.modalHelper = modalHelperInstance;

        scope.timeline.modalHelper.setupTimeline(
          scope.timeline,
          {
            api_prefix                : scope.timeline.options.api_prefix,
            url_prefix                : scope.timeline.options.url_prefix,
            project_prefix            : scope.timeline.options.project_prefix
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
}
