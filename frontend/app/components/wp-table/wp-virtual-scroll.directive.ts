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

import {wpDirectivesModule} from "../../angular-modules";
import {scopedObservable, runInScopeDigest} from "../../helpers/angular-rx-utils";
import IScope = angular.IScope;
import IRootElementService = angular.IRootElementService;
import IAnimateProvider = angular.IAnimateProvider;
import ITranscludeFunction = angular.ITranscludeFunction;

function wpVirtualScrollRow(workPackageTableVirtualScrollService: WorkPackageTableVirtualScrollService) {
  return {
    restrict: 'A',

    link: ($scope: IScope,
           $element: IRootElementService,
           $attr: any) => {

      new RowDisplay($scope, $element, $attr, workPackageTableVirtualScrollService);
    }
  };
}

wpDirectivesModule.directive('wpVirtualScrollRow', wpVirtualScrollRow);

class RowDisplay {

  private index: number;
  private viewport: [number, number] = [0, 0];
  private watchersEnabled = true;

  constructor(private $scope: angular.IScope,
              private $element: angular.IRootElementService,
              private $attr: any,
              private workPackageTableVirtualScrollService: WorkPackageTableVirtualScrollService) {

    this.index = $scope.$eval($attr.wpVirtualScrollRow);

    scopedObservable($scope, workPackageTableVirtualScrollService.viewportChanges)
      .subscribe(vp => {
        this.viewport = vp;
        this.viewportChanged();
      });

    workPackageTableVirtualScrollService.requestUpdate();
  }

  private isRowInViewport() {
    const offsetTop = this.$element.offset().top;
    const top = this.viewport[0];
    const bottom = this.viewport[1];
    return (offsetTop > top && offsetTop < bottom);
  }

  private viewportChanged() {
    const enableWatchers = this.isRowInViewport();
    if (this.watchersEnabled !== enableWatchers) {
      this.adjustWatchers(this.$element, enableWatchers);
    }
  }

  private adjustWatchers(element: JQuery, enableWatchers: boolean) {
    this.watchersEnabled = enableWatchers;

    const scope: any = angular.element(element).scope();
    if (scope === undefined) {
      return;
    }

    // Do not toggle watch state on table rows themselves
    // since watchers are needed for, e.g., group collapsing
    if (!(element.length > 0 && element[0].tagName === 'TR')) {
      this.setWatchState(scope, enableWatchers);
    }

    angular.forEach(angular.element(element).children(), (child: JQuery) => {
      this.adjustWatchers(child, enableWatchers);
    });

  }

  private setWatchState(scope, enableWatchers: boolean) {
    if (!enableWatchers) {
      if (scope.$$watchers && scope.$$watchers.length > 0) {
        scope.__backup_watchers = scope.$$watchers;
        scope.$$watchers = [];
      }
    } else {
      if (scope.__backup_watchers && scope.__backup_watchers.length > 0) {
        scope.$$watchers = scope.__backup_watchers;
        scope.__backup_watchers = [];
      }
    }
  }
}


class WorkPackageTableVirtualScrollService {

  public viewportChanges: Rx.Subject<[number, number]> = new Rx.ReplaySubject<[number, number]>(0);

  private requestedUpdateTimeout: any;

  /*@ngInject*/
  constructor(private $rootScope: angular.IRootScopeService) {
  }

  updateScrollInfo() {
    runInScopeDigest(this.$rootScope, () => {
      this.viewportChanges.onNext([-50, window.innerHeight + 50]);
    });
  }

  requestUpdate() {
    this.requestedUpdateTimeout && clearTimeout(this.requestedUpdateTimeout);
    this.requestedUpdateTimeout = setTimeout(() => {
      this.updateScrollInfo();
    }, 1000);
  }
}

wpDirectivesModule.service("workPackageTableVirtualScrollService", WorkPackageTableVirtualScrollService);


function wpVirtualScrollTable(workPackageTableVirtualScrollService: WorkPackageTableVirtualScrollService) {
  return {
    restrict: 'A',
    link: ($scope: IScope, $element: IRootElementService, attr: any) => {
      // flag to avoid endless loops
      let updateActive = false;

      const updateScrollInfo = () => {
        if (updateActive) {
          return;
        }
        updateActive = true;
        try {
          workPackageTableVirtualScrollService.updateScrollInfo();
        } finally {
          updateActive = false;
        }
      };

      let scrollTimeout: any;
      $element.on("scroll", () => {
        scrollTimeout && clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(() => {
          updateScrollInfo();
        }, 2000);
      });

      window.addEventListener('resize', () => {
        updateScrollInfo();
      });
    }
  };
}

wpDirectivesModule.directive('wpVirtualScrollTable', wpVirtualScrollTable);
