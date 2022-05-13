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
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { FileLinkResourceService } from 'core-app/core/state/file-links/file-links.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Component({
  selector: 'op-file-link-list',
  templateUrl: './file-link-list.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public resource:HalResource;

  $fileLinks:Observable<IFileLink[]>;

  allowEditing = false;

  constructor(
    private readonly fileLinkResourceService:FileLinkResourceService,
    private currentUserService:CurrentUserService,
    private currentProjectService:CurrentProjectService,
  ) {
    super();
  }

  ngOnInit():void {
    this.fileLinkResourceService.fetchCurrent(this.fileLinkSelfLink);

    this.$fileLinks = this.fileLinkResourceService.all(this.collectionKey)
      .pipe(
        tap((fileLinks) => {
          if (isNewResource(this.resource)) {
            this.resource.fileLinks = { elements: fileLinks.map((a) => a._links?.self) };
          }
        }),
      );

    this
      .currentUserService
      .hasCapabilities$('file_links/manage', this.currentProjectService.id as string)
      .pipe(this.untilDestroyed())
      .subscribe((value) => {
        this.allowEditing = value;
      });
  }

  public removeFileLink(fileLink:IFileLink):void {
    this.fileLinkResourceService.remove(this.collectionKey, fileLink);
  }

  private get fileLinkSelfLink():string {
    const fileLinks = this.resource.fileLinks as unknown&{ href:string };
    return fileLinks.href;
  }

  private get collectionKey():string {
    return isNewResource(this.resource) ? 'new' : this.fileLinkSelfLink;
  }
}
