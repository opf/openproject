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

import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {Component, Inject, Input, OnDestroy, OnInit} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {downgradeComponent} from '@angular/upgrade/static';

@Component({
  templateUrl: './wp-watcher-button.html',
  selector: 'wp-watcher-button',
})
export class WorkPackageWatcherButtonComponent implements OnInit,  OnDestroy {
  @Input('workPackage') public workPackage:WorkPackageResourceInterface;
  @Input('showText') public showText:boolean = false;
  @Input('disabled') public disabled:boolean = false;

  public buttonText:string;
  public buttonTitle:string;
  public buttonClass:string;
  public buttonId:string;
  public watchIconClass:string;

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              public wpCacheService:WorkPackageCacheService) {
  }

  ngOnInit() {
    this.wpCacheService.loadWorkPackage(this.workPackage.id)
      .values$()
      .takeUntil(componentDestroyed(this))
      .subscribe((wp: WorkPackageResourceInterface) => {
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

wpDirectivesModule.directive('wpWatcherButton',
  downgradeComponent({component: WorkPackageWatcherButtonComponent})
);
