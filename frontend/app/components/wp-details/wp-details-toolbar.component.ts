//-- copyright
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
//++
import {WorkPackageMoreMenuService} from '../work-packages/work-package-more-menu.service';

import {openprojectModule} from '../../angular-modules';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
import {I18nToken, wpMoreMenuServiceToken} from 'core-app/angular4-transition-utils';
import {Component, Inject, Input, OnInit} from '@angular/core';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {downgradeComponent} from '@angular/upgrade/static';


@Component({
  template: require('!!raw-loader!./wp-details-toolbar.html'),
  selector: 'wp-details-toolbar',
})
export class WorkPackageSplitViewToolbarComponent implements OnInit {
  @Input('workPackage') workPackage:WorkPackageResourceInterface;

  public permittedActions:any;
  public actionsAvailable:any;
  public triggerMoreMenuAction:Function;

  public text = {
    button_more: this.I18n.t('js.button_more')
  }

constructor(@Inject(I18nToken) readonly I18n:op.I18n,
  public wpEditing:WorkPackageEditingService,
  @Inject(wpMoreMenuServiceToken) private wpMoreMenuServiceFactory:any) {
  }

  ngOnInit() {
    let wpMoreMenu = new this.wpMoreMenuServiceFactory(this.workPackage) as WorkPackageMoreMenuService;

    wpMoreMenu.initialize().then(() => {
      this.permittedActions = wpMoreMenu.permittedActions;
      this.actionsAvailable = wpMoreMenu.actionsAvailable;
    });

    this.triggerMoreMenuAction = wpMoreMenu.triggerMoreMenuAction.bind(wpMoreMenu);
  }
}

openprojectModule.directive('wpDetailsToolbar',
  downgradeComponent({component: WorkPackageSplitViewToolbarComponent })
);
