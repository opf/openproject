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
angular.module('openproject.workPackages.directives')

.directive('workPackageColumn', ['PathHelper', 'WorkPackagesHelper', 'UserService', function(PathHelper, WorkPackagesHelper, UserService){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      workPackage: '=',
      column: '=',
      displayType: '@',
      displayEmpty: '@'
    },
    templateUrl: '/templates/work_packages/work_package_column.html',
    compile: function() {
      return {
        pre: function(scope, element, attributes) {
          var displayText;
          scope.displayType = scope.displayType || 'text';
          scope.displayEmpty = scope.displayEmpty || '';

          // initially render placeholder content
          var placeholder = angular.element('<span>' + scope.displayEmpty + '</span>');
          element.append(placeholder);

          // Set text to be displayed
          scope.$watch(dataAvailable, function(dataAvailable) {
            if(dataAvailable) {
              setColumnData(getFormattedColumnValue());
              placeholder.remove();
            }
          });

          // Check if the data is available on the work package

          function dataAvailable() {
            if (!scope.workPackage) return false;

            if (scope.column.custom_field) {
              return customValueAvailable();
            } else {
              return scope.workPackage.hasOwnProperty(scope.column.name);
            }
          }

          function customValuesLoaded() {
            return scope.workPackage.custom_values !== undefined;
          }

          function customValueAvailable() {
            var customFieldId = scope.column.custom_field.id;

            return customValuesLoaded() &&
              scope.workPackage.custom_values.filter(function(customValue){
                return customValue && customValue.custom_field_id === customFieldId;
              }).length;
          }

          // Write column data to the scope

          function setColumnData(formattedValue) {
            setDisplayText(formattedValue);

            if (scope.column.meta_data.link.display) {
              displayDataAsLink();
            } else {
              setCustomDisplayType();
            }

            scope.columnData = {
              displayText: displayText
            };
          }

          function getFormattedColumnValue() {
            // retrieve column value from work package
            if (scope.column.custom_field) {
              var custom_field = scope.column.custom_field;
              return WorkPackagesHelper.getFormattedCustomValue(scope.workPackage, custom_field);
            } else {
              return WorkPackagesHelper.getFormattedColumnData(scope.workPackage, scope.column);
            }
          }

          /**
           * @name setDisplayText
           * @function
           *
           * @description
           * Sets displayText to the passed value or applies a default
           *
           * @param {String|Number} value The value for displayText
           *
           * @returns null
           */
          function setDisplayText(value) {
            if (typeof value == 'number' || value){
              displayText = value;
            } else {
              displayText = scope.displayEmpty || '';
            }
          }

          function setCustomDisplayType() {
            if (scope.column.name === 'done_ratio') scope.displayType = 'progress_bar';
            // ...
          }

          function displayDataAsLink() {
            // Example of how we can look to the provided meta data to format the column
            // This relies on the meta being sent from the server
            scope.displayType = 'link';
            scope.url = getLinkFor(scope.column.meta_data.link);
          }

          function getLinkFor(link_meta){
            if (link_meta.model_type === 'work_package') {
              return PathHelper.workPackagePath(scope.workPackage.id);
            } else if (scope.workPackage[scope.column.name]) {
              switch (link_meta.model_type) {
                case 'user':
                  return PathHelper.staticUserPath(scope.workPackage[scope.column.name].id);
                case 'version':
                  return PathHelper.staticVersionPath(scope.workPackage[scope.column.name].id);
                case 'project':
                  return PathHelper.staticProjectPath(scope.workPackage.project.identifier);
                default:
                  return '';
              }

            }
          }

        }
      };
    },
    // link: function(scope, element, attributes) {

    // }
  };
}]);
