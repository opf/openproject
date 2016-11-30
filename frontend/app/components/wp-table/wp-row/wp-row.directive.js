// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// ++


var WorkPackagesTimelineCell = require("../timeline/wp-timeline-cell").WorkPackageTimelineCell;

function wpRow(WorkPackagesTableService, wpCacheService, states) {

  function setCheckboxTitle(scope) {
    scope.checkboxTitle = I18n.t('js.description_select_work_package',
      {id: scope.workPackage.id});
  }

  function setHiddenWorkPackageLabel(scope) {
    scope.parentWorkPackageHiddenText = I18n.t('js.description_subwork_package',
      {id: scope.row.parent.object.id});
  }

  function buildTimelineCell(scope, element, wpTimelineContainer) {
      // required data for timeline cell
      var workPackageId = scope.workPackage.id;
      var timelineTd = element.find(".wp-timeline-cell")[0];
      const timelineCell = new WorkPackagesTimelineCell(
        wpTimelineContainer,
        wpCacheService,
        scope,
        states,
        workPackageId,
        timelineTd
      );

      // show timeline cell
      timelineCell.activate();

      // remove timeline cell on scope destroy
      scope.$on("$destroy", function () {
        timelineCell.deactivate();
      });
  }

  return {
    restrict: 'A',

    require: '^wpTimelineContainer',
    link: function (scope, element, attr, wpTimelineContainer) {
      scope.workPackage = scope.row.object;

      buildTimelineCell(scope, element, wpTimelineContainer);
      setCheckboxTitle(scope);

      if (scope.row.parent) setHiddenWorkPackageLabel(scope);

      scope.$watch('row.checked', function (checked, formerState) {
        if (checked !== formerState) {
          WorkPackagesTableService.setAllRowsChecked(scope.rows, scope.row, checked);
        }
      });
    }
  };
}

angular
  .module('openproject.workPackages.directives')
  .directive('wpRow', wpRow);
