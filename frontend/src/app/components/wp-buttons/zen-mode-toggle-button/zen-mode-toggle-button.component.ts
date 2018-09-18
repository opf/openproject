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
import {Component} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

const screenfull:any = require('screenfull/dist/screenfull.js');

export const zenModeComponentSelector = 'zen-mode-toggle-button';

@Component({
  templateUrl: '../wp-button.template.html',
  selector: zenModeComponentSelector,
})
export class ZenModeButtonComponent extends AbstractWorkPackageButtonComponent {
  public buttonId:string = 'work-packages-zen-mode-toggle-button';
  public buttonClass:string = 'toolbar-icon';
  public iconClass:string = 'icon-zen-mode';

  static inZenMode:boolean = false;

  private activateLabel:string;
  private deactivateLabel:string;

  constructor(readonly I18n:I18nService) {
    super(I18n);

    this.activateLabel = I18n.t('js.zen_mode.button_activate');
    this.deactivateLabel = I18n.t('js.zen_mode.button_deactivate');
    let self = this;

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
    if (this.isActive()) {
      return this.deactivateLabel;
    } else {
      return this.activateLabel;
    }
  }

  public isToggle():boolean {
    return true;
  }

  public isActive():boolean {
    return ZenModeButtonComponent.inZenMode;
  }

  private deactivateZenMode():void {
    ZenModeButtonComponent.inZenMode = false;
    jQuery('body').removeClass('zen-mode');
    this.disabled = false;
    if (screenfull.enabled && screenfull.isFullscreen) {
      screenfull.exit();
    }

  }

  private activateZenMode() {
    ZenModeButtonComponent.inZenMode = true;
    jQuery('body').addClass('zen-mode');
    if (screenfull.enabled) {
      screenfull.request();
    }
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

DynamicBootstrapper.register({ selector: zenModeComponentSelector, cls: ZenModeButtonComponent });
