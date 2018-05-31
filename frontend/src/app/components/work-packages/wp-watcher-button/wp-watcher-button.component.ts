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

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {Component, Inject, Input, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageWatchersService} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watchers.service';

@Component({
  selector: 'wp-watcher-button',
  templateUrl: './wp-watcher-button.html'
})
export class WorkPackageWatcherButtonComponent implements OnInit,  OnDestroy {
  @Input('workPackage') public workPackage:WorkPackageResource;
  @Input('showText') public showText:boolean = false;
  @Input('disabled') public disabled:boolean = false;

  public buttonText:string;
  public buttonTitle:string;
  public buttonClass:string;
  public buttonId:string;
  public watchIconClass:string;

  constructor(readonly I18n:I18nService,
              readonly wpWatchersService:WorkPackageWatchersService,
              readonly wpCacheService:WorkPackageCacheService) {
  }

  ngOnInit() {
    this.wpCacheService.loadWorkPackage(this.workPackage.id)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;
        this.setWatchStatus();
      });
  }

  ngOnDestroy() {
    // Nothing to do
  }

  public get isWatched() {
    return this.workPackage.hasOwnProperty('unwatch');
  }

  public get displayWatchButton() {
    return this.isWatched || this.workPackage.hasOwnProperty('watch');
  }

  public toggleWatch() {
    const toggleLink = this.nextStateLink();

    toggleLink(toggleLink.$link.payload).then(() => {
      this.wpWatchersService.clear(this.workPackage.id);
      this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
    });
  }

  public nextStateLink() {
    const linkName = this.isWatched ? 'unwatch' : 'watch';
    return this.workPackage[linkName];
  }

  private setWatchStatus() {
    if (this.isWatched) {
      this.buttonTitle = this.I18n.t('js.label_unwatch_work_package');
      this.buttonText = this.I18n.t('js.label_unwatch');
      this.buttonClass = '-active';
      this.buttonId = 'unwatch-button';
      this.watchIconClass = 'icon-watched';

    } else {
      this.buttonTitle = this.I18n.t('js.label_watch_work_package');
      this.buttonText = this.I18n.t('js.label_watch');
      this.buttonClass = '';
      this.buttonId = 'watch-button';
      this.watchIconClass = 'icon-unwatched';
    }
  }
}
