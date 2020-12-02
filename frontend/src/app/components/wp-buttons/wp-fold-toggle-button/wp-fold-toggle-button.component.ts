// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {KeepTabService} from '../../wp-single-view-tabs/keep-tab/keep-tab.service';
import {States} from '../../states.service';
import {WorkPackageViewFocusService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {StateService, TransitionService} from '@uirouter/core';
import {ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy} from '@angular/core';
import {AbstractWorkPackageButtonComponent} from 'core-components/wp-buttons/wp-buttons.module';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageViewCollapsedGroupsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service";

@Component({
  templateUrl: '../wp-button.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-fold-toggle-view-button',
})
export class WorkPackageFoldToggleButtonComponent extends AbstractWorkPackageButtonComponent implements OnDestroy {
  public activeState:string = 'work-packages.partitioned.list.details';
  public listState:string = 'work-packages.partitioned.list';
  public buttonId:string = 'work-packages-fold-toggle-button';
  public buttonClass:string = 'toolbar-icon';
  public iconClass:string = 'icon-hierarchy';

  public activateLabel:string;
  public deactivateLabel:string;

  private labels = {
    activate: this.I18n.t('js.button_collapse_all'),
    deactivate: this.I18n.t('js.button_expand_all')
  };

  private transitionListener:Function;

  constructor(
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    public wpViewCollapsedGroups:WorkPackageViewCollapsedGroupsService) {
    super(I18n);
  }

  public ngOnDestroy() {
    super.ngOnDestroy();
  }

  public get label():string {
    if (this.isActive) {
      return this.labels.deactivate;
    } else {
      return this.labels.activate;
    }
  }

  public isToggle():boolean {
    return true;
  }

  public performAction(event:Event) {
    this.isActive = !this.isActive;

    this.wpViewCollapsedGroups.setCollapsedAll(this.isActive);
  }
}
