//-- copyright
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
//++

module.exports = function(WorkPackageService) {

  return {
    restrict: 'A',
    scope: true,
    link: function(scope) {
      function fetchTotalSums() {
        scope.fetchTotalSums = WorkPackageService.getWorkPackagesSums(scope.projectIdentifier, scope.query, scope.columns)
          .then(function(data){
            angular.forEach(scope.columns, function(column, i){
              column.total_sum = data.column_sums[i];
            });
          });

        return scope.fetchTotalSums;
      }

      function totalSumsFetched() {
        return scope.columns.every(function(column) {
          return column.hasOwnProperty('total_sum');
        });
      }

      if (!totalSumsFetched()) fetchTotalSums();

      function columnNames() {
        return scope.columns.map(function(column) {
          return column.name;
        });
      }

      scope.$watch(columnNames, function(columnNames, formerNames) {
        if (!angular.equals(columnNames, formerNames) && !totalSumsFetched()) {
          fetchTotalSums();
          scope.$emit('queryStateChange');
        }
      }, true);
    }
  };
};
