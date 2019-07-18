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

import {AbstractWorkPackageButtonComponent} from '../wp-buttons.module';
import {ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {StateService} from "@uirouter/core";
import {
  WorkPackageDisplayRepresentationService, wpDisplayCardRepresentation,
  wpDisplayListRepresentation
} from "core-components/wp-fast-table/state/work-package-display-representation.service";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";


@Component({
  template: `
<ul class="toolbar-button-group">
  <li>
    <button class="button"
            type="button"
            [ngClass]="{ '-active': inListView }"
            [disabled]="inListView"
            [attr.id]="buttonId"
            [attr.title]="label"
            [attr.accesskey]="accessKey"
            (accessibleClick)="performAction($event)">
      <op-icon icon-classes="{{ iconListView }} button--icon"></op-icon>
    </button>
  </li>
  <li>
    <button class="button"
            [ngClass]="{ '-active': !inListView }"
            [attr.id]="buttonId"
            [attr.title]="label"
            [disabled]="!inListView"
            (click)="performAction($event)">
      <op-icon icon-classes="{{ iconCardView }} button--icon"></op-icon>
    </button>
  </li>
</ul>
`,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-view-toggle-button',
})
export class WorkPackageViewToggleButton extends AbstractWorkPackageButtonComponent implements OnInit, OnDestroy {
  public iconListView:string = 'icon-view-list';
  public iconCardView:string = 'icon-image2';

  public buttonId:string = 'work-packages-view-toggle-button';

  public inListView:boolean = true;

  public activateLabel:string;
  public deactivateLabel:string;

  constructor(readonly $state:StateService,
              readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpDisplayRepresentationService:WorkPackageDisplayRepresentationService,
              readonly wpListService:WorkPackagesListService) {
    super(I18n);

    this.activateLabel = I18n.t('js.button_card_list');
    this.deactivateLabel = I18n.t('js.button_show_list');
  }

  ngOnInit() {
    this.wpDisplayRepresentationService
      .live$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(() => {
        this.inListView = this.wpDisplayRepresentationService.valueFromQuery(this.wpListService.currentQuery) === wpDisplayListRepresentation;
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy() {
    //
  }

  public performAction(evt:Event):false {
    if (this.inListView) {
      this.activateCardView();
    } else {
      this.activateListView();
    }

    evt.preventDefault();
    return false;
  }

  private activateCardView() {
    this.inListView = false;
    this.wpDisplayRepresentationService.setDisplayRepresentation(wpDisplayCardRepresentation);

    this.cdRef.detectChanges();
  }

  private activateListView() {
    this.inListView = true;
    this.wpDisplayRepresentationService.setDisplayRepresentation(wpDisplayListRepresentation);

    this.cdRef.detectChanges();
  }

}

DynamicBootstrapper.register({ selector: 'wp-view-toggle-button', cls: WorkPackageViewToggleButton });
