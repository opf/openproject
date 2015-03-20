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

module.exports = function($filter, QueryService, WorkPackagesTableHelper) {
  var workPackagesTableData = {
    allRowsChecked: false,
    showFiltersOptions: false
  };
  var bulkLinks = {};

  var WorkPackagesTableService = {
    setBulkLinks: function(links) {
      bulkLinks = links;
    },
    getBulkLinks: function() {
      return bulkLinks;
    },

    getWorkPackagesTableData: function() {
      return workPackagesTableData;
    },

    setAllRowsChecked: function(rows, currentRow, currentState) {
      rows = rows.filter(function(row) {
        return row !== currentRow;
      });
      workPackagesTableData.allRowsChecked = $filter('allRowsChecked')(rows) && currentState;
    },
    allRowsChecked: function() {
      return workPackagesTableData.allRowsChecked;
    },

    setColumns: function(columns) {
      workPackagesTableData.columns = columns;
    },

    addColumnMetaData: function(metaData) {
      angular.forEach(workPackagesTableData.columns, function(column, i){
        column.total_sum = metaData.sums[i];

        if (metaData.group_sums) column.group_sums = metaData.group_sums[i];
      });

      if (!workPackagesTableData.groupableColumns) workPackagesTableData.groupableColumns = metaData.groupable_columns;
    },

    getGroupableColumns: function() {
      return workPackagesTableData.groupableColumns;
    },

    isGroupable: function(column) {
      if (!workPackagesTableData.groupableColumns || !column) return false;

      return workPackagesTableData.groupableColumns.map(function(groupableColumn) {
        return groupableColumn.name;
      }).indexOf(column.name) !== -1;
    },

    buildRows: function(workPackages, groupBy) {
      this.setRows(WorkPackagesTableHelper.buildRows(workPackages, groupBy));
    },

    setRows: function(rows) {
      workPackagesTableData.rows = rows;
    },

    getRows: function() {
      return workPackagesTableData.rows;
    },

    getRowsData: function() {
      return WorkPackagesTableService.getRows().map(function(row) {
        return row.object;
      });
    },

    getRowsByWorkPackageIds: function(ids) {
      var rows = [];

      angular.forEach(WorkPackagesTableService.getRows(), function(row) {
        if (ids.indexOf(row.object.id) >= 0) {
          rows.push(row);
        }
      });

      return rows;
    },

    getGroupBy: function() {
      return workPackagesTableData.groupBy;
    },

    setGroupBy: function(groupBy) {
      workPackagesTableData.groupBy = groupBy;
    },

    removeRow: function(row) {
      var rows = workPackagesTableData.rows;
      var index = rows.indexOf(row);

      if (index > -1) rows.splice(index, 1);
    },
    removeRows: function(rows) {
      angular.forEach(rows, function(row) {
        WorkPackagesTableService.removeRow(row);
      });
    },

    sortBy: function(columnName, direction) {
      QueryService.getQuery().sortation.addSortElement({
        field: columnName,
        direction: direction
      });
    },

    setCheckedStateForAllRows: function(rows, state) {
      angular.forEach(rows, function(row) {
        row.checked = state;
      });
    },
    setRowSelection: function(row, state) {
      row.checked = state;
    },
    selectRowRange: function(rows, row, activeSelectionBorderIndex) {
      if (WorkPackagesTableHelper.getSelectedRows(rows).length == 0) {
        this.setRowSelection(row, true);

        activeSelectionBorderIndex = rows.indexOf(row);
      } else {
        var index = rows.indexOf(row);
        var start = Math.min(index, activeSelectionBorderIndex);
        var end = Math.max(index, activeSelectionBorderIndex);

        for (var x = 0; x < rows.length; x++) {
          rows[x].checked = x >= start && x <= end;
        }
      }

      return activeSelectionBorderIndex;
    },

    getShowFilterOptions: function() {
      return workPackagesTableData.showFiltersOptions;
    },
    toggleShowFilterOptions: function() {
      workPackagesTableData.showFiltersOptions = !workPackagesTableData.showFiltersOptions;
    }
  };

  return WorkPackagesTableService;
};
