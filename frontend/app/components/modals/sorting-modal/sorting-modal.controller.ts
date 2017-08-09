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

import {wpControllersModule} from '../../../angular-modules';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';
import {
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC,
  QuerySortByResource
} from '../../api/api-v3/hal-resources/query-sort-by-resource.service';
import {QueryColumn} from '../../wp-query/query-column';

class SortModalObject {
  constructor(public column: QueryColumn|null,
              public direction: string) {
  }
}

function SortingModalController(this:any,
                                sortingModal:any,
                                $scope:any,
                                wpTableSortBy:WorkPackageTableSortByService,
                                I18n:op.I18n) {
  this.name = 'Sorting';
  this.closeMe = sortingModal.deactivate;

  $scope.currentSortation = [];
  $scope.availableColumns = [];
  $scope.allColumns = [];
  $scope.sortationObjects = [];

  wpTableSortBy.onReady($scope).then(() => {
    $scope.currentSortation = wpTableSortBy.currentSortBys;
    let availableSortation = wpTableSortBy.available;
    let allColumns:QueryColumn[] = _.map(availableSortation, sort => sort.column);
    $scope.allColumns = _.uniqBy(allColumns, '$href');

    _.each($scope.currentSortation, sort => {
      $scope.sortationObjects.push(new SortModalObject(sort.column,
                                                       sort.direction.$href));
    });

    fillUpSortElements();
  });

  function fillUpSortElements() {
    while ($scope.sortationObjects.length < 3) {
      $scope.sortationObjects.push(new SortModalObject(null, QUERY_SORT_BY_ASC));
    }
  }

  $scope.$watchCollection('sortationObjects', () => {
    let usedColumns = _.map($scope.sortationObjects, (object:SortModalObject) => object.column);

    $scope.availableColumns = _.differenceBy($scope.allColumns, usedColumns, '$href');
  });

  $scope.availableColumnsAndCurrent = (column:SortModalObject) => {
    return _.uniqBy(_.concat($scope.availableColumns, _.compact([column])), '$href');
  };

  $scope.updateSortation = () => {
    let sortElements = ($scope.sortationObjects as SortModalObject[])
      .filter(object => object.column)
      .map(object => _.find(wpTableSortBy.available, availableSort =>
        availableSort.column.$href === object.column!.$href &&
          availableSort.direction.$href === object.direction
      ));

    wpTableSortBy.set(_.compact(sortElements) as QuerySortByResource[]);

    sortingModal.deactivate();
  };

  $scope.availableDirections = [
    {$href: QUERY_SORT_BY_ASC, name: I18n.t('js.label_ascending')},
    {$href: QUERY_SORT_BY_DESC, name: I18n.t('js.label_descending')}
  ];
}

wpControllersModule.controller('SortingModalController', SortingModalController);
