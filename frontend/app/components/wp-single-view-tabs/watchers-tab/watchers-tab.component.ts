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

import {Component, ElementRef, Inject, OnDestroy, OnInit} from '@angular/core';
import {Transition} from '@uirouter/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {LoadingIndicatorService} from 'core-components/common/loading-indicator/loading-indicator.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {I18nToken} from '../../../angular4-transition-utils';

@Component({
  template: require('!!raw-loader!./watchers-tab.html'),
  selector: 'wp-watchers-tab',
})
export class WorkPackageWatchersTabComponent implements OnInit, OnDestroy {
  public workPackageId:string;
  public workPackage:WorkPackageResource;

  public autocompleteInput = '';
  public error = false;
  public noResults:boolean = false;
  public allowedToView = false;
  public allowedToAdd = false;
  public allowedToRemove = false;
  private $element:ng.IAugmentedJQuery;

  public watching:any[] = [];
  public text = {
    loading: this.I18n.t('js.watchers.label_loading'),
    loadingError: this.I18n.t('js.watchers.label_error_loading'),
    autocomplete: {
      placeholder: this.I18n.t('js.watchers.typeahead_placeholder')
    }
  };

  public constructor(@Inject(I18nToken) readonly I18n:op.I18n,
                     readonly elementRef:ElementRef,
                     readonly $transition:Transition,
                     readonly wpNotificationsService:WorkPackageNotificationService,
                     readonly loadingIndicator:LoadingIndicatorService,
                     readonly wpCacheService:WorkPackageCacheService) {
  }

  public ngOnInit() {
    this.$element = angular.element(this.elementRef.nativeElement);

    this.workPackageId = this.$transition.params('to').workPackageId;
    this.wpCacheService.loadWorkPackage(this.workPackageId)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((wp) => {
        this.workPackage = wp;
        this.loadCurrentWatchers();
      });
  }

  public loadCurrentWatchers() {
    this.error = false;
    this.allowedToView = !!this.workPackage.watchers;
    this.allowedToAdd = !!this.workPackage.addWatcher;
    this.allowedToRemove = !!this.workPackage.removeWatcher;

    if (!this.allowedToView) {
      this.error = true;
      return;
    }

    this.workPackage.watchers.$load()
      .then((collection:CollectionResource) => {
        this.watching = collection.elements;
      })
      .catch((error:any) => {
        this.wpNotificationsService.showError(error, this.workPackage);
      });

    this.setupAutoCompletion();
  }

  public setupAutoCompletion() {
    const input = this.$element.find('.ui-autocomplete--input');
    input.autocomplete({
      delay: 250,
      autoFocus: false, // Accessibility!
      source: (request:{ term:string }, response:Function) => {
        this.autocompleteWatchers(request.term).then((values:any) => {
          response(values.map((watcher:any) => {
            return {watcher: watcher, value: watcher.name};
          }));
        });
      },
      select: (evt:JQueryEventObject, ui:any) => {
        this.addWatcher(ui.item.watcher);
        input.val('');
        return false; // Avoid setting the value after selection
      },
      minLength: 0
    } as any);

    input.focus(() => input.autocomplete('search', input.val()));
    (input.autocomplete('instance')as any)._renderItem = (ul:any, item:any) => this.renderWatcherItem(
      ul,
      item);
  }

  public set loadingPromise(promise:Promise<any>) {
    this.loadingIndicator.wpDetails.promise = promise;
  }

  /**
   * Converted renderer from manually compiling the view in ng1
   * @param {JQuery} ul
   * @param {{value:string; watcher:any}} item
   * @returns {any}
   */
  public renderWatcherItem(ul:JQuery, item:{ value:string, watcher:UserResource }):JQuery {
    const li = document.createElement('li');
    li.classList.add('ui-menu-item');
    li.dataset['value'] = item.value;

    const div = document.createElement('div');
    div.classList.add('ui-menu-item-wrapper');

    const link = document.createElement('a');
    link.tabIndex = -1;

    if (item.watcher.avatar) {
      const img = document.createElement('img');
      img.src = item.watcher.avatar;
      img.alt = item.watcher.name;
      img.classList.add('avatar-mini');

      link.appendChild(img);
    }

    const span = document.createElement('span');
    span.textContent = item.value;

    link.appendChild(span);
    div.appendChild(link);
    li.appendChild(div);

    ul.append(li);
    return jQuery(li);
  }

  public async autocompleteWatchers(query:string):Promise<any> {
    let payload:any = {sortBy: JSON.stringify([['name', 'asc']])};

    if (query && query.length > 0) {
      let filter = {
        name: {
          operator: '~',
          values: query,
        }
      };

      payload['filters'] = JSON.stringify([filter]);
    }

    return new Promise<UserResource[]>((resolve, reject) => {
      this.workPackage.availableWatchers
        .$link
        .$fetch(payload, {caching: {enabled: false}})
        .then((collection:CollectionResource<UserResource>) => {
          this.noResults = collection.count === 0;
          resolve(collection.elements);
        })
        .catch(reject);
    });
  }

  public addWatcher(user:any) {
    this.loadingPromise = this.workPackage.addWatcher.$link.$fetch({user: {href: user.href}})
      .then(() => {
        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been added
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
        this.autocompleteInput = '';
      })
      .catch((error:any) => this.wpNotificationsService.showError(error, this.workPackage));
  };

  public removeWatcher(watcher:any) {
    this.workPackage.removeWatcher.$link.$prepare({user_id: watcher.id})()
      .then(() => {
        _.remove(this.watching, (other:HalResource) => {
          return other.href === watcher.href;
        });

        // Forcefully reload the resource to update the watch/unwatch links
        // should the current user have been removed
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
      })
      .catch((error:any) => this.wpNotificationsService.showError(error, this.workPackage));
  };

  ngOnDestroy() {
    // Nothing to do
  }
}
