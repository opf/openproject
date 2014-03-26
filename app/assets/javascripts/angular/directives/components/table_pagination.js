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

angular.module('openproject.uiComponents')

.directive('tablePagination', [function(){
  return {
    restrict: 'EA',
    templateUrl: '/templates/components/table_pagination.html',
    scope: {
      paginationOptions: '=',
      perPageOptions: '=',
      totalEntries: '=',
      updateResults: '&'
    },
    link: function(scope, element, attributes){
      scope.selectPerPage = function(perPage){
        scope.paginationOptions.perPage = perPage;

        updatePageNumbers();
        scope.showPage(1);
      };

      scope.showPage = function(pageNumber){
        scope.paginationOptions.page = pageNumber;

        updateCurrentRange();
        scope.updateResults(); // update table
      };

      /**
       * @name updateCurrentRange
       *
       * @description Defines a string containing page bound information inside the directive scope
       */
      updateCurrentRange = function() {
        var page = scope.paginationOptions.page;
        var perPage = scope.paginationOptions.perPage;

        scope.currentRange = "(" + getLowerPageBound(page, perPage) + " - " + getUpperPageBound(page, perPage) + "/" + scope.totalEntries + ")";
      };

      function getLowerPageBound(page, perPage) {
        return perPage * (page - 1) + 1;
      }

      function getUpperPageBound(page, perPage) {
        return Math.min(perPage * page, scope.totalEntries);
      }

      /**
       * @name updatePageNumbers
       *
       * @description Defines a list of all pages in numerical order inside the scope
       */
      updatePageNumbers = function() {
        var pageNumbers = [];
        for (var i = 1; i <= Math.ceil(scope.totalEntries / scope.paginationOptions.perPage); i++) {
          pageNumbers.push(i);
        }
        scope.pageNumbers = pageNumbers;
      };

      scope.$watch('totalEntries', function() {
        updateCurrentRange();
        updatePageNumbers();
      });

    }
  };
}]);
