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

import {wpButtonsModule} from '../../../angular-modules';
import {WorkPackageButtonController, wpButtonDirective} from '../wp-buttons.module';

export class WorkPackageZenModeButtonController extends WorkPackageButtonController {
  public buttonId:string = 'work-packages-zen-mode-toggle-button';
  public iconClass:string = 'icon-zen-mode';

  public iconClassDeactive:string = 'icon-zen-mode';
  public iconClassActive:string = 'icon-no-zen-mode';
  public inZenMode:boolean = false;

  private activateLabel:string;
  private deactivateLabel:string;

  constructor(public I18n:op.I18n) {
    super(I18n);

    this.activateLabel = I18n.t('js.timelines.button_activate');
    this.deactivateLabel = I18n.t('js.timelines.button_deactivate');
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
    return this.inZenMode;
  }

  public performAction() {
    if (this.inZenMode) {
      // deactivate Zen Mode
      console.log("ZEN MODE TOGGLE: deactivate");
      this.inZenMode = false;
      angular.element('body').removeClass('zen-mode');
    } else {
      // activate Zen Mode
      console.log("ZEN MODE TOGGLE: activate");
      this.inZenMode = true;
      angular.element('body').addClass('zen-mode');
    }
    // this.wpTableTimeline.toggle();
  }
}

function wpZenModeToggleButton():ng.IDirective {
  return wpButtonDirective({
    // require: '^wpTimelineContainer',
    controller: WorkPackageZenModeButtonController
  });
}

wpButtonsModule.directive('wpZenModeToggleButton', wpZenModeToggleButton);
