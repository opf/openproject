//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { AbstractWorkPackageButtonComponent } from '../wp-buttons.module';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';

import * as sfimport from "screenfull";
import { Screenfull } from "screenfull";

const screenfull:Screenfull = sfimport as any;
export const zenModeComponentSelector = 'zen-mode-toggle-button';

@Component({
  templateUrl: '../wp-button.template.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: zenModeComponentSelector,
})
export class ZenModeButtonComponent extends AbstractWorkPackageButtonComponent {
  public buttonId = 'work-packages-zen-mode-toggle-button';
  public buttonClass = 'toolbar-icon';
  public iconClass = 'icon-zen-mode';

  static inZenMode = false;

  private activateLabel:string;
  private deactivateLabel:string;

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef) {
    super(I18n);

    this.activateLabel = I18n.t('js.zen_mode.button_activate');
    this.deactivateLabel = I18n.t('js.zen_mode.button_deactivate');
    const self = this;


    if (screenfull.enabled) {
      screenfull.onchange(function() {
        // This event might get triggered several times for once leaving
        // fullscreen mode.
        if (!screenfull.isFullscreen) {
          self.deactivateZenMode();
        }
      });
    }
  }

  public get label():string {
    if (this.isActive) {
      return this.deactivateLabel;
    } else {
      return this.activateLabel;
    }
  }

  public isToggle():boolean {
    return true;
  }

  private deactivateZenMode():void {
    this.isActive = ZenModeButtonComponent.inZenMode = false;
    jQuery('body').removeClass('zen-mode');
    this.disabled = false;
    if (screenfull.enabled && screenfull.isFullscreen) {
      screenfull.exit();
    }
    this.cdRef.detectChanges();
  }

  private activateZenMode() {
    this.isActive = ZenModeButtonComponent.inZenMode = true;
    jQuery('body').addClass('zen-mode');
    if (screenfull.enabled) {
      screenfull.request();
    }
    this.cdRef.detectChanges();
  }

  public performAction(evt:Event):false {
    if (ZenModeButtonComponent.inZenMode) {
      this.deactivateZenMode();
    } else {
      this.activateZenMode();
    }

    evt.preventDefault();
    return false;
  }
}
