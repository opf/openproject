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
              public $element,
              public $q,
              public I18n,
              public $templateCache:ng.ITemplateCacheService,
              public $compile:ng.ICompileService,
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

    this.setupAutoCompletion();
  };

  public setupAutoCompletion() {
    const input = this.$element.find('.ui-autocomplete--input');
    input.autocomplete({
      delay: 250,
      autoFocus: false, // Accessibility!
      source: (request:{ term:string }, response:Function) => {
        this.autocompleteWatchers(request.term).then((values) => {
          response(values.map(watcher => {
            return { watcher: watcher, value: watcher.name };
          }));
        });
      },
      select: (evt, ui:any) => {
        this.addWatcher(ui.item.watcher);
        input.val('');
        return false; // Avoid setting the value after selection
      },
      _renderItem: (ul:JQuery, item) => this.renderWatcherItem(ul, item)
    })
    .autocomplete( "instance" )._renderItem = (ul, item) => this.renderWatcherItem(ul,item);
  }

  public renderWatcherItem(ul:JQuery, item:{value: string, watcher: any}) {
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
        sortBy: JSON.stringify([["name", "asc"]])
      },
      {
        caching: {enabled: false}
      }).then((collection:CollectionResource) => {
        this.$scope.noResults = collection.count === 0;
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
