//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, EventEmitter, Injector, Input, OnInit, Output, inject } from '@angular/core';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { StateService, UIRouterGlobals } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { WpTabDefinition } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';

@Component({
  selector: 'op-wp-tabs',
  templateUrl: './wp-tabs.component.html',
  styleUrls: ['./wp-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WpTabsComponent implements OnInit {
  readonly wpTabsService = inject(WorkPackageTabsService);
  readonly I18n = inject(I18nService);
  readonly injector = inject(Injector);
  readonly $state = inject(StateService);
  readonly uiRouterGlobals = inject(UIRouterGlobals);
  readonly keepTab = inject(KeepTabService);
  readonly pathHelper = inject(PathHelperService);
  readonly currentProject = inject(CurrentProjectService);

  @Input() workPackage:WorkPackageResource;

  @Input() view:'full'|'split';

  @Input() routedFromAngular = true;

  @Input() public currentTabId:string|null = null;

  @Output() public tabSelected = new EventEmitter<TabDefinition>();

  public tabs:TabDefinition[];

  public canViewWatchers = false;

  text = {
    details: {
      close: this.I18n.t('js.button_close_details'),
      goToFullScreen: this.I18n.t('js.button_show_fullscreen'),
    },
  };

  ngOnInit():void {
    this.canViewWatchers = !!(this.workPackage && this.workPackage.watchers);
    this.tabs = this.getDisplayableTabs();
  }

  private getDisplayableTabs():WpTabDefinition[]{
    return this
      .wpTabsService
      .getDisplayableTabs(this.workPackage, this.routedFromAngular)
      .map((tab) => {
        if (this.routedFromAngular) {
          return ({
              ...tab,
              route: '.tabs',
              routeParams: { workPackageId: this.workPackage.id, tabIdentifier: tab.id },
            });
        }

        return ({
          ...tab,
          path: this.pathHelper.genericWorkPackagePath(this.currentProject.identifier, this.workPackage.displayId, tab.id),
        });
      });
  }

  public switchToFullscreen():void {
    this.keepTab.goCurrentShowState(this.workPackage.displayId);
  }

  public close():void {
    this.$state.go(
      this.uiRouterGlobals.current.data.baseRoute,
      this.uiRouterGlobals.params,
    );
  }
}
