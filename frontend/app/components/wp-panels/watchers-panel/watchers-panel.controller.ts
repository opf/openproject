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

import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {scopedObservable} from '../../../helpers/angular-rx-utils';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';

export class WatchersPanelController {

  public workPackage:WorkPackageResourceInterface;
  public loadingPromise:ng.IPromise<any>;
  public error = false;
  public allowedToAdd = false;
  public allowedToRemove = false;

  public available:any[] = [];
  public watching:any[] = [];
  public text:any;

  constructor(public $scope,
              public I18n,
              public wpCacheService:WorkPackageCacheService,
              public wpWatchers) {

    this.text = {
      loading: I18n.t('js.watchers.label_loading'),
      loadingError: I18n.t('js.watchers.label_error_loading')
    };


    $scope.$on('watchers.add', (evt, watcher) => {
      this.addWatcher(evt, watcher);
    });
    $scope.$on('watchers.remove', (evt, watcher) => {
      this.removeWatcher(evt, watcher);
    });

    if (!this.workPackage) {
      return;
    }

    scopedObservable($scope, wpCacheService.loadWorkPackage(<number> this.workPackage.id))
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.fetchWatchers();
      });
  }

  public fetchWatchers() {
    this.error = false;
    this.allowedToAdd = !!this.workPackage.addWatcher;
    this.allowedToRemove = !!this.workPackage.removeWatcher;

    this.wpWatchers.forWorkPackage(this.workPackage)
      .then(users => {
        this.watching = users.watching;
        this.available = users.available;
      })
      .catch(() => {
        this.watching = [];
        this.available = [];
        this.error = true;
      });
  };

  public addWatcher(event, watcher) {
    event.stopPropagation();

    watcher.loading = true;
    this.add(watcher, this.watching);
    this.remove(watcher, this.available);

    this.loadingPromise = this.wpWatchers.addForWorkPackage(this.workPackage, watcher)
      .then(watcher => {
        this.$scope.$broadcast('watchers.add.finished', watcher);

        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been added
        this.wpCacheService.loadWorkPackage(<number> this.workPackage.id, true);
      })
      .finally(() => {
        delete watcher.loading;
      });
  };

  public removeWatcher(event, watcher) {
    event.stopPropagation();

    this.wpWatchers.removeFromWorkPackage(this.workPackage, watcher)
      .then(watcher => {
        this.remove(watcher, this.watching);
        this.add(watcher, this.available);

        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been removed
        this.wpCacheService.loadWorkPackage(<number> this.workPackage.id, true);
      });
  };


  private remove(watcher, arr) {
    var idx = _.findIndex(arr, watcher, this.equality(watcher));

    if (idx > -1) {
      arr.splice(idx, 1);
    }
  };

  private add(watcher, arr) {
    var idx = _.findIndex(arr, watcher, this.equality(watcher));

    if (idx === -1) {
      arr.push(watcher);
    }
  };

  private equality(firstElement) {
    return function (secondElement) {
      return firstElement.id === secondElement.id;
    };
  };

}
