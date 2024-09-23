// -- copyright
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
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { combineLatest, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectStoragesResourceService } from 'core-app/core/state/project-storages/project-storages.service';
import { IProjectStorage } from 'core-app/core/state/project-storages/project-storage.model';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  selector: 'op-files-tab',
  templateUrl: './op-files-tab.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageFilesTabComponent implements OnInit {
  @Input() workPackage:WorkPackageResource;

  text = {
    attachments: {
      label: this.i18n.t('js.label_attachments'),
    },
  };

  showAttachmentHeader$:Observable<boolean>;

  projectStorages:Observable<IProjectStorage[]>;

  allowManageFileLinks$:Observable<boolean>;

  showAttachments:boolean;

  constructor(
    private readonly i18n:I18nService,
    private readonly currentUserService:CurrentUserService,
    private readonly projectStoragesResourceService:ProjectStoragesResourceService,
    private readonly pathHelper:PathHelperService,
    private readonly turboRequests:TurboRequestsService,
  ) { }

  ngOnInit():void {
    const project = this.workPackage.project as HalResource;
    if (project.id === null) {
      return;
    }

    this.showAttachments = !!this.workPackage.$links.attachments;
    const canViewFileLinks = this.currentUserService.hasCapabilities$('file_links/view', project.id);

    this.projectStorages = this
      .projectStoragesResourceService
      .requireCollection({ filters: [['projectId', '=', [project.id]]] });

    this.allowManageFileLinks$ = this
      .currentUserService
      .hasCapabilities$('file_links/manage', project.id);

    this.showAttachmentHeader$ = combineLatest(
      [
        this.projectStorages,
        canViewFileLinks,
      ],
    ).pipe(
      map(([storages, viewPermission]) => storages.length > 0 && viewPermission),
    );
  }

  attachmentRemoved() {
    this.updateCounter();
  }

  attachmentAdded() {
    this.updateCounter();
  }

  private updateCounter() {
    if (this.workPackage.id) {
      const url = this.pathHelper.workPackageUpdateCounterPath(this.workPackage.id, 'files');
      void this.turboRequests.request(url);
    }
  }
}
