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

angular.module('openproject.uiComponents.controllers')

.controller('CheckUncheckController', ['$scope',
                                       'allCheckedFilter',
                                       'DEFAULT_CHECKALL_OPTIONS',
                                      function ($scope, allCheckedFilter, DEFAULT_CHECKALL_OPTIONS) {
  var checkAllData = {
    checkTitle: DEFAULT_CHECKALL_OPTIONS.checkTitle,
    uncheckTitle: DEFAULT_CHECKALL_OPTIONS.uncheckTitle,
  },
  self = this;

  $scope.checkAll = function (state) {
    angular.forEach(self.getRows(), function(row) {
      self.check(row, state)
    });
  };

  this.init = function () {
    this.setRows([]);
    this.isAllChecked();
    this.getTitle();
  }
  this.getTitle = function () {
    return $scope.checkTitle = I18n.t('js.' + ($scope.allChecked ? this.getUncheckTitle() : this.getCheckTitle()));
  };
  this.getCheckTitle = function () {
    return checkAllData.checkTitle;
  };
  this.setCheckTitle = function (title) {
    checkAllData.checkTitle = title;
  };
  this.getUncheckTitle = function () {
    return checkAllData.uncheckTitle;
  };
  this.setUncheckTitle = function (title) {
    checkAllData.uncheckTitle = title;
  };
  this.getRows = function() {
    return $scope.rows;
  };
  this.setRows = function(rows) {
    return $scope.rows = rows;
  };
  this.attach = function(element) {
    this.getRows().push(element);
    this.isAllChecked();
  };
  // returns whether all rows are checked or not.
  this.isAllChecked = function () {
    var before = $scope.allChecked;
    $scope.allChecked = allCheckedFilter(this.getRows());
    if ($scope.allChecked != before) {
      // stuff changed, title switcheroo!
      this.getTitle();
    }
    return $scope.allChecked;
  };
  // Sets @row to @state.
  // returns whether @row's state has changed or not.
  this.check = function (row, state) {
    var changed = (state != row.checked);
    if (changed) {
      row.checked = state;
      this.isAllChecked();
    }
    return changed;
  };
  this.getCheckAllData = function () {
    return checkAllData;
  };
  this.init();
}]);
