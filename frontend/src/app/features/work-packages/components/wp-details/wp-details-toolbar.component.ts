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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Component, Input, OnInit } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { Observable } from 'rxjs';

@Component({
  selector: 'wp-details-toolbar',
  templateUrl: './wp-details-toolbar.html',
})
export class WorkPackageSplitViewToolbarComponent implements OnInit {
  @Input() workPackage:WorkPackageResource;

  @Input() displayNotificationsButton:boolean;

  public displayShareButton$:false|Observable<boolean> = false;

  public text = {
    button_more: this.I18n.t('js.button_more'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly halEditing:HalResourceEditingService,
    readonly configurationService:ConfigurationService,
    readonly currentUserService:CurrentUserService,
  ) {
  }

  ngOnInit() {
    this.displayShareButton$ = this.currentUserService.hasCapabilities$('work_package_shares/index', this.workPackage.project.id);
  }
}
