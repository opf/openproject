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
  OnInit,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { forkJoin, Observable } from 'rxjs';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { IProject } from 'core-app/core/state/projects/project.model';
import { IHalResourceLink, IHalResourceLinks } from 'core-app/core/state/hal-resource';
import { switchMap } from 'rxjs/operators';

export interface ILiveFileLinkCollectionsLinks extends IHalResourceLinks {
  self:IHalResourceLink
}

export interface ILiveFileLinkCollectionEmbeddings {

}

export interface ILiveFileLinkCollection {
  _links:ILiveFileLinkCollectionsLinks;
  _embedded:ILiveFileLinkCollectionEmbeddings;
}

@Component({
  selector: 'op-files-tab',
  templateUrl: './op-files-tab.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageFilesTabComponent implements OnInit {
  workPackage:WorkPackageResource;

  text = {
    attachments: {
      label: this.I18n.t('js.label_attachments'),
    },
    file_links: {
      label: this.I18n.t('js.label_nextcloud'),
    },
  };

  canViewFileLinks$:Observable<boolean>;

  fileLinkCollections$:Observable<ILiveFileLinkCollection[]>;

  constructor(
    readonly I18n:I18nService,
    protected hook:HookService,
    private currentUserService:CurrentUserService,
    private storagesResourceService:StoragesResourceService,
  ) { }

  ngOnInit():void {
    const project = this.workPackage.$embedded.project as IProject;

    this.canViewFileLinks$ = this
      .currentUserService
      .hasCapabilities$('file_links/view', project.id as string);

    const storageLinks = project._links.storages;
    this.fileLinkCollections$ = forkJoin(
      storageLinks.map((link) => this
        .storagesResourceService
        .lookup(link)
        .pipe(
          switchMap((storage) => this
            .storagesResourceService
            .liveLinks(storage)('WorkPackage', this.workPackage.id as string)),
        )),
    );
  }
}
