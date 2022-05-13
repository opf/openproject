// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  ChangeDetectionStrategy,
  Component,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { Subscription } from 'rxjs';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

@Component({
  selector: 'op-files-tab',
  templateUrl: './op-files-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageFilesTabComponent implements OnInit, OnDestroy {
  public workPackage:WorkPackageResource;

  public text = {
    attachments: {
      label: this.I18n.t('js.label_attachments'),
    },
    file_links: {
      label: this.I18n.t('js.label_nextcloud'),
    },
  };

  public canViewFileLinks = true;

  private subscription:Subscription;

  constructor(
    readonly I18n:I18nService,
    protected hook:HookService,
    private currentUserService:CurrentUserService,
    private currentProjectService:CurrentProjectService,
  ) { }

  ngOnInit():void {
    this.subscription = this
      .currentUserService
      .hasCapabilities$('file_links/view', this.currentProjectService.id as string)
      .subscribe((value) => {
        this.canViewFileLinks = value;
      });
  }

  ngOnDestroy():void {
    this.subscription.unsubscribe();
  }
}
