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
import {WorkPackageTimelineTableController} from './../../wp-table/timeline/wp-timeline-container.directive';

export class WorkPackageTimelineButtonController extends WorkPackageButtonController {
  public wpTimelineContainer:WorkPackageTimelineTableController ;

  public buttonId:string = 'work-packages-timeline-toggle-button';
  public iconClass:string = 'icon-view-timeline';

  constructor(public I18n) {
    'ngInject';

    super(I18n);
  }

  public get labelKey():string {
    return 'js.button_timeline';
  }

  public isToggle():boolean {
    return true;
  }

  public isActive():boolean {
    return this.wpTimelineContainer && this.wpTimelineContainer.visible;
  }

  public performAction() {
    this.wpTimelineContainer.toggle();
  }
}

function wpTimelineToggleButton():ng.IDirective {
  return wpButtonDirective({
    require: '^wpTimelineContainer',
    controller: WorkPackageTimelineButtonController,
    link: (scope, attr, element, wpTimelineContainer:WorkPackageTimelineTableController) => {
      scope.vm.wpTimelineContainer = wpTimelineContainer;
    }
  });
}

wpButtonsModule.directive('wpTimelineToggleButton', wpTimelineToggleButton);
