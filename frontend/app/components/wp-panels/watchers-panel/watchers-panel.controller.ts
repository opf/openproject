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

import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {CollectionResource} from "../../api/api-v3/hal-resources/collection-resource.service";
import {HalResource} from "../../api/api-v3/hal-resources/hal-resource.service";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {LoadingIndicatorService} from "../../common/loading-indicator/loading-indicator.service";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import {WorkPackageNotificationService} from "../../wp-edit/wp-notification.service";

export class WatchersPanelController {

  public workPackage: WorkPackageResourceInterface;
  public autocompleteLoadingPromise: ng.IPromise<any>;
  public autocompleteInput = '';
  public error = false;
  public allowedToAdd = false;
  public allowedToRemove = false;

  public watching: any[] = [];
  public text: any;

  constructor(public $scope: ng.IScope,
              public $element: ng.IAugmentedJQuery,
              public $q: ng.IQService,
              public I18n: op.I18n,
              public $templateCache: ng.ITemplateCacheService,
              public $compile: ng.ICompileService,
              public loadingIndicator: LoadingIndicatorService,
              public wpNotificationsService: WorkPackageNotificationService,
              public wpCacheService: WorkPackageCacheService) {

    this.text = {
      loading: I18n.t('js.watchers.label_loading'),
      loadingError: I18n.t('js.watchers.label_error_loading'),
      autocomplete: {
        placeholder: I18n.t('js.watchers.typeahead_placeholder')
      }
    };

    if (!this.workPackage) {
      return;
    }

    scopedObservable($scope, wpCacheService.loadWorkPackage(this.workPackage.id).values$())
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
      .then((collection: CollectionResource) => {
        this.watching = collection.elements;
      })
      .catch((error) => {
        this.wpNotificationsService.showError(error, this.workPackage);
      });

    this.setupAutoCompletion();
  };

  public setupAutoCompletion() {
    const input = this.$element.find('.ui-autocomplete--input');
    input.autocomplete({
      delay: 250,
      autoFocus: false, // Accessibility!
      source: (request: { term: string }, response: Function) => {
        this.autocompleteWatchers(request.term).then((values: any) => {
          response(values.map((watcher: any) => {
            return {watcher: watcher, value: watcher.name};
          }));
        });
      },
      select: (evt: JQueryEventObject, ui: any) => {
        this.addWatcher(ui.item.watcher);
        input.val('');
        return false; // Avoid setting the value after selection
      },
      minLength: 0
    }).focus(() => input.autocomplete('search', input.val()));
    (input.autocomplete("instance")as any)._renderItem = (ul: any, item: any) => this.renderWatcherItem(ul, item);
  }

  public set loadingPromise(promise: ng.IPromise<any>) {
    this.loadingIndicator.wpDetails.promise = promise;
  }

  public renderWatcherItem(ul: JQuery, item: { value: string, watcher: any }) {
    let itemScope = this.$scope.$new();
    itemScope['value'] = item.value;
    itemScope['watcher'] = item.watcher;

    // Render template
    let template = this.$templateCache.get('/components/common/autocomplete/users/user-autocomplete-item.html');
    let element = angular.element(template);
    ul.append(element);
    this.$compile(element)(itemScope);

    return element;
  }

  public autocompleteWatchers(query: string): ng.IPromise<any> {
    const deferred = this.$q.defer();
    this.autocompleteLoadingPromise = deferred.promise;

    let payload:any = { sortBy: JSON.stringify([["name", "asc"]]) }

    if (query && query.length > 0) {
      let filter = {
        name: {
          operator: '~',
          values: query,
        }
      }

      payload['filters'] = JSON.stringify([filter]);
    }

    this.workPackage.availableWatchers.$link.$fetch(
      payload,
      {
        caching: {enabled: false}
      }).then((collection: CollectionResource) => {
      this.$scope['noResults'] = collection.count === 0;
      deferred.resolve(collection.elements);
    }).catch(() => deferred.reject());

    return deferred.promise;
  }

  public addWatcher(user: any) {
    this.loadingPromise = this.workPackage.addWatcher.$link.$fetch({user: {href: user.href}})
      .then(() => {
        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been added
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
        this.autocompleteInput = '';
      })
      .catch((error: any) => this.wpNotificationsService.showError(error, this.workPackage));
  };

  public removeWatcher(watcher: any) {
    this.workPackage.removeWatcher.$link.$prepare({user_id: watcher.id})()
      .then(() => {
        _.remove(this.watching, (other: HalResource) => {
          return other.href === watcher.href;
        });

        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been removed
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
      })
      .catch((error: any) => this.wpNotificationsService.showError(error, this.workPackage));
  };
}
