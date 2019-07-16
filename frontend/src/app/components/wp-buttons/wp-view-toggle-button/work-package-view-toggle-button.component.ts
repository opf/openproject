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
import {ChangeDetectionStrategy, ChangeDetectorRef, Component} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {StateService} from "@uirouter/core";
import {WpDisplayRepresentationService} from "core-components/wp-fast-table/state/wp-display-representation.service";


@Component({
  templateUrl: '../wp-button.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-view-toggle-button',
})
export class WorkPackageViewToggleButton extends AbstractWorkPackageButtonComponent {
  public buttonId:string = 'work-packages-view-toggle-button';
  public buttonClass:string = 'toolbar-icon';
  public iconClass:string = 'icon-view-fullscreen';

  public inListView:boolean = true;

  public activateLabel:string;
  public deactivateLabel:string;

  constructor(readonly $state:StateService,
              readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpDisplayRepresentationService:WpDisplayRepresentationService) {
    super(I18n);

    this.activateLabel = I18n.t('js.button_card_list');
    this.deactivateLabel = I18n.t('js.button_show_list');
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
    this.iconClass = 'icon-view-list';
    this.inListView = false;

    this.wpDisplayRepresentationService.setDisplayRepresentation('card');
    this.cdRef.detectChanges();
  }

  private activateListView() {
    this.iconClass = 'icon-view-fullscreen';
    this.inListView = true;

    this.wpDisplayRepresentationService.setDisplayRepresentation('');
    this.cdRef.detectChanges();
  }

}

DynamicBootstrapper.register({ selector: 'wp-view-toggle-button', cls: WorkPackageViewToggleButton });
