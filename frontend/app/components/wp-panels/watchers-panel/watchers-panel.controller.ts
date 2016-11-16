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
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {CollectionResource} from '../../api/api-v3/hal-resources/collection-resource.service';

export class WatchersPanelController {

  public workPackage: WorkPackageResourceInterface;
  public loadingPromise: ng.IPromise<any>;
  public autocompleteLoadingPromise: ng.IPromise<any>;
  public autocompleteInput = '';
  public error = false;
  public allowedToAdd = false;
  public allowedToRemove = false;

  public watching: any[] = [];
  public text: any;

  constructor(public $scope,
              public $q,
              public I18n,
              public wpNotificationsService: WorkPackageNotificationService,
              public wpCacheService: WorkPackageCacheService) {

    this.text = {
      loading: I18n.t('js.watchers.label_loading'),
      loadingError: I18n.t('js.watchers.label_error_loading'),
      autocomplete: {
        placeholder: I18n.t('js.watchers.tyepahead_placeholder')
      }
    };

    if (!this.workPackage) {
      return;
    }

    wpCacheService.loadWorkPackage(<number> this.workPackage.id).observe($scope)
      .subscribe((wp: WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.loadCurrentWatchers();
      });
  }

  public loadCurrentWatchers() {
    this.error = false;
    this.allowedToAdd = !!this.workPackage.addWatcher;
    this.allowedToRemove = !!this.workPackage.removeWatcher;

    this.workPackage.watchers.$load()
      .then((collection:CollectionResource) => {
        this.watching = collection.elements;
      })
      .catch((error) => {
        this.wpNotificationsService.showError(error, this.workPackage);
      });
  };

  public autocompleteWatchers(query) {
    if (!query) {
      return [];
    }

    const deferred = this.$q.defer();
    this.autocompleteLoadingPromise = deferred.promise;

    this.workPackage.availableWatchers.$link.$fetch(
      {
        filters: JSON.stringify([{
          name: {
            operator: '~',
            values: query,
          }
        }]),
      },
      {
        caching: {enabled: false}
      }).then(collection => {
      deferred.resolve(collection.elements);
    }).catch(() => deferred.reject());

    return deferred.promise;
  }

  public addWatcher(user) {
    this.loadingPromise = this.workPackage.addWatcher.$link.$fetch({user: {href: user.href}})
      .then(() => {
        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been added
        this.wpCacheService.loadWorkPackage(<number> this.workPackage.id, true);
        this.autocompleteInput = '';
      })
      .catch((error) => this.wpNotificationsService.showError(error, this.workPackage));
  };

  public removeWatcher(watcher) {
    this.workPackage.removeWatcher.$link.$prepare({ user_id: watcher.id })()
      .then(() => {
        _.remove(this.watching, (other) => { return other.href === watcher.href; });

        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been removed
        this.wpCacheService.loadWorkPackage(<number> this.workPackage.id, true);
      })
      .catch((error) => this.wpNotificationsService.showError(error, this.workPackage));
  };
}
