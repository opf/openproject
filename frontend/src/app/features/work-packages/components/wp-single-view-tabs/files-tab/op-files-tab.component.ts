// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
  OnInit,
} from '@angular/core';
import {
  combineLatest,
  Observable,
} from 'rxjs';
import {
  catchError,
  map,
} from 'rxjs/operators';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Component({
  selector: 'op-files-tab',
  templateUrl: './op-files-tab.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageFilesTabComponent implements OnInit {
  workPackage:WorkPackageResource;

  text = {
    attachments: {
      label: this.i18n.t('js.label_attachments'),
    },
  };

  showAttachmentHeader$:Observable<boolean>;

  storages$:Observable<IStorage[]>;

  get storageFileUploadEnabled():boolean {
    return this.configurationService.activeFeatureFlags.includes('storageFileUpload');
  }

  get storageFileLinkingEnabled():boolean {
    return this.configurationService.activeFeatureFlags.includes('storageFileLinking');
  }

  constructor(
    private readonly i18n:I18nService,
    private readonly hook:HookService,
    private readonly currentUserService:CurrentUserService,
    private readonly projectsResourceService:ProjectsResourceService,
    private readonly storagesResourceService:StoragesResourceService,
    private readonly configurationService:ConfigurationService,
    private readonly apiV3:ApiV3Service,
    private readonly toast:ToastService,
  ) { }

  ngOnInit():void {
    const project = this.workPackage.project as HalResource;
    if (project.id === null) {
      return;
    }

    const canViewFileLinks = this.currentUserService.hasCapabilities$('file_links/view', project.id);

    this.storages$ = this
      .storagesResourceService
      .collection(project.href as string)
      .pipe(
        catchError((error) => {
          this.toast.addError(error);
          throw error;
        }),
      );

    this.showAttachmentHeader$ = combineLatest(
      [
        this.storages$,
        canViewFileLinks,
      ],
    ).pipe(
      map(([storages, viewPermission]) => storages.length > 0 && viewPermission),
    );
  }
}
