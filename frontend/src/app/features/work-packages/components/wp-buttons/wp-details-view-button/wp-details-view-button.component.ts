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

import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { AbstractWorkPackageButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-buttons.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { KeepTabService } from '../../wp-single-view-tabs/keep-tab/keep-tab.service';
import { resolveRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';

@Component({
  templateUrl: '../wp-button.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-details-view-button',
  standalone: false,
})
export class WorkPackageDetailsViewButtonComponent extends AbstractWorkPackageButtonComponent implements OnInit {
  readonly I18n:I18nService;
  readonly cdRef = inject(ChangeDetectorRef);
  states = inject(States);
  wpTableFocus = inject(WorkPackageViewFocusService);
  keepTab = inject(KeepTabService);
  urlParams = inject(UrlParamsService);

  public projectIdentifier:string;

  public accessKey = 8;

  public buttonId = 'work-packages-details-view-button';

  public buttonClass = 'toolbar-icon';

  public iconClass = 'icon-info2';

  public activateLabel:string;

  public deactivateLabel:string;

  constructor() {
    const I18n = inject(I18nService);

    super(I18n);
    this.I18n = I18n;


    this.activateLabel = I18n.t('js.button_open_details');
    this.deactivateLabel = I18n.t('js.button_close_details');
  }

  public ngOnInit() {
    this.urlParams
      .pathMatching$(/(\/details\/)/)
      .pipe(this.untilDestroyed())
      .subscribe((match) => {
        this.isActive = !!match;
        this.cdRef.detectChanges();
      });
  }

  public get label():string {
    if (this.isActive) {
      return this.deactivateLabel;
    }
    return this.activateLabel;
  }

  public isToggle():boolean {
    return true;
  }

  public performAction(event:Event) {
    if (this.isActive) {
      this.closeDetailsView();
    } else {
      this.openDetailsView();
    }
  }

  public openListView():void {
  }

  public openDetailsView():void {
    const focused = this.wpTableFocus.focusedWorkPackage;
    if (!focused) {
      return;
    }

    const routingId = resolveRoutingId(this.states, focused);
    const basePath = this.urlParams.basePathWithoutDetails();
    Turbo.visit(
      `${basePath}/details/${routingId}/${this.keepTab.currentDetailsTab}${window.location.search}`,
      { frame: 'content-bodyRight', action: 'advance' },
    );
  }

  private closeDetailsView():void {
    const basePath = this.urlParams.basePathWithoutDetails();
    Turbo.visit(`${basePath}${window.location.search}`, { frame: 'content-bodyRight', action: 'replace' });
  }
}
