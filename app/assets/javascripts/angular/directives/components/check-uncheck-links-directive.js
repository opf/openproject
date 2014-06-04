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

// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('checkUncheckLinks', ['I18n', 'CheckAllService', function(I18n, CheckAllService) {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      checkId: '@'
    },
    templateUrl: '/templates/components/check_uncheck_links.html',
    link: function(scope, element, attrs) {
      scope.I18n = I18n;
      CheckAllService.setRows(jQuery("#" + scope.checkId).find("input:checkbox"));
      scope.checkAllData = CheckAllService.getCheckAllData();
      scope.checkTitle = CheckAllService.getTitle();

      var setCheckTitle = function () { scope.checkTitle = I18n.t('js.' + CheckAllService.getTitle())};

      scope.$watch('checkAllData.allChecked', function() { setCheckTitle() });
      angular.forEach(scope.checkAllData.rows, function(row) {
          row.on("change", function () {
            scope.$apply(function () { setCheckTitle() });
          });
        });

      scope.checkAll = function(state) {
        angular.forEach(scope.checkAllData.rows, function(row) {
          if (CheckAllService.check(row, state)) {
            // make the new check all stuff work with jquery listeners
            jQuery(row).trigger("change");
          }
        });
      };
    }
  };
}]);

