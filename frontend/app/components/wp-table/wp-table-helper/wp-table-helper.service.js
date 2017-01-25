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

angular
  .module('openproject.workPackages.helpers')
  .factory('WorkPackagesTableHelper', WorkPackagesTableHelper);


function WorkPackagesTableHelper(WorkPackagesHelper) {
  var WorkPackagesTableHelper = {
    /* builds rows from work packages, see IssuesHelper */
    buildRows: function(workPackages, groupBy, splitViewWorkPackageId) {
      var rows = [], ancestors = [];
      var currentGroup, allGroups = [];

      angular.forEach(workPackages, function(workPackage) {
        while(ancestors.length > 0 &&
            (!workPackage.parent ||
             !_.last(ancestors).object.isParentOf(workPackage))) {
          // this helper method only reflects hierarchies if nested work packages follow one another
          ancestors.pop();
        }

        // compose row

        var row = {
          level: ancestors.length,
          checked: splitViewWorkPackageId && workPackage.id === parseInt(splitViewWorkPackageId),
          parent: _.last(ancestors),
          ancestors: ancestors.slice(0),
          object: workPackage
        };

        // manage groups

        // this helper method assumes that the work packages are passed in in blocks
        // each of which consisting of work packages which belong to one group

        if (groupBy) {
          currentGroup = WorkPackagesHelper.getRowObjectContent(workPackage, groupBy);

          if(allGroups.indexOf(currentGroup) === -1) {
            allGroups.push(currentGroup);
          }

          angular.extend(row, {
            groupIndex: allGroups.indexOf(currentGroup),
            groupName: currentGroup
          });
        }

        rows.push(row);

        if (!workPackage.isLeaf) ancestors.push(row);
      });

      return _.sortBy(rows, 'groupIndex');
    },


  };

  return WorkPackagesTableHelper;
}
