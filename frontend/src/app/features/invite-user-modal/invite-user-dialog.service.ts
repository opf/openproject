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

import { EventEmitter, inject, Injectable, OnDestroy } from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Injectable({ providedIn: 'root' })
export class OpInviteUserDialogService implements OnDestroy {
  public close = new EventEmitter<HalResource|HalResource[]>();

  protected currentProjectService = inject(CurrentProjectService);
  turboRequests = inject(TurboRequestsService);
  pathHelper = inject(PathHelperService);
  apiV3Service = inject(ApiV3Service);

  private closeDialogHandler:EventListener = this.handleDialogClose.bind(this);

  constructor() {
    document.addEventListener('dialog:close', this.closeDialogHandler);
  }

  ngOnDestroy():void {
    document.removeEventListener('dialog:close', this.closeDialogHandler);
  }

  public open(projectId:string|null = this.currentProjectService.id) {
    void this.turboRequests.request(
      this.pathHelper.inviteUserPath(projectId),
      { method: 'GET' },
    );
  }

  private handleDialogClose(event:CustomEvent):void {
    const {
      detail: { dialog, submitted, additional },
    } = event as { detail:{ dialog:HTMLDialogElement; submitted:boolean, additional:{ user_id:number } } };
    if (dialog.id === 'user-invitation-dialog' && submitted) {
      this
        .apiV3Service
        .principals
        .id(additional.user_id)
        .get()
        .subscribe((user) => this.close.emit(user));
    }
  }
}
