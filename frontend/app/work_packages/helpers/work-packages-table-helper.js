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

module.exports = function(WorkPackagesHelper) {
  var WorkPackagesTableHelper = {
    /* builds rows from work packages, see IssuesHelper */
    buildRows: function(workPackages, groupBy) {
      var rows = [], ancestors = [];
      var currentGroup, allGroups = [], groupIndex = -1;

      angular.forEach(workPackages, function(workPackage, i) {
        while(ancestors.length > 0 && workPackage.parent_id !== _.last(ancestors).object.id) {
          // this helper method only reflects hierarchies if nested work packages follow one another
          ancestors.pop();
        }


        // compose row

        var row = {
          level: ancestors.length,
          parent: _.last(ancestors),
          ancestors: ancestors.slice(0),
          object: workPackage
        };

        // manage groups

        // this helper method assumes that the work packages are passed in in blocks each of which consisting of work packages which belong to one group

        if (groupBy) {
          currentGroup = WorkPackagesHelper.getRowObjectContent(workPackage, groupBy);

          if(allGroups.indexOf(currentGroup) === -1) {
            allGroups.push(currentGroup);
            groupIndex++;
          }

          angular.extend(row, {
            groupIndex: groupIndex,
            groupName: currentGroup
          });
        }

        rows.push(row);

        if (!workPackage['leaf?']) ancestors.push(row);
      });

      return rows;
    },

    allRowsChecked: function(rows) {
      if( rows.length === 0 ) return false;
      return rows
        .map(function(row) {
          return !!row.checked;
        })
        .reduce(function(a, b){
          return a && b;
        });
    },

    getColumnDifference: function (allColumns, columns) {
      var identifiers = columns.map(function(column){
        return column.name;
      });

      return this.getColumnDifferenceByName(allColumns, identifiers);
    },

    getColumnDifferenceByName: function (allColumns, identifiers) {
      return allColumns.filter(function(column) {
        return identifiers.indexOf(column.name) === -1;
      });
    },

    getColumnUnionByName: function (allColumns, columnNames) {
      return allColumns.filter(function(column) {
        return columnNames.indexOf(column.name) !== -1;
      });
    },

    getColumnIndexByName: function(columns, columnName) {
      return columns
        .map(function(column){
          return column.name;
        })
        .indexOf(columnName);
    },

    detectColumnByName: function(columns, columnName) {
      return columns[WorkPackagesTableHelper.getColumnIndexByName(columns, columnName)];
    },

    selectColumnsByName: function(columns, columnNames) {
      return columns.filter(function(column) {
        return columnNames.indexOf(column.name) !== -1;
      });
    },

    mapIdentifiersToColumns: function(columns, columnNames) {
      return columnNames.map(function(columnName) {
        return WorkPackagesTableHelper.detectColumnByName(columns, columnName);
      });
    },

    moveElementBy: function(array, index, positions) {
      // TODO maybe extend the Array prototype
      var newPosition = index + positions;

      if (newPosition > -1 && newPosition < array.length) {
        var elementToMove = array.splice(index, 1)[0];
        array.splice(newPosition, 0, elementToMove);
      }
    },

    moveColumnBy: function(columns, columnName, by) {
      var index = WorkPackagesTableHelper.getColumnIndexByName(columns, columnName);

      WorkPackagesTableHelper.moveElementBy(columns, index, by);
    },

    moveColumns: function (columnNames, fromColumns, toColumns) {
      angular.forEach(columnNames, function(columnName){
        WorkPackagesTableHelper.removeColumn(columnName, fromColumns, function(removedColumn){
          toColumns.push(removedColumn);
        });
      });
    },

    removeColumn: function(columnName, columns, callback) {
      var removed = columns.splice(this.getColumnIndexByName(columns, columnName), 1)[0];

      return typeof(callback) !== 'undefined' ? callback.call(this, removed) : null;
    },

    getSelectedRows: function(rows) {
      return rows
        .filter(function(row) {
          return row.checked;
        });
    },

    getWorkPackagesFromRows: function(rows) {
      return rows
        .map(function(row) {
          return row.object;
        });
    }
  };

  return WorkPackagesTableHelper;
};
