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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  inject,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';

@Component({
  templateUrl: './status-board-header.html',
  styleUrls: ['./status-board-header.sass'],
  host: { class: 'title-container -small' },
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class StatusBoardHeaderComponent {
  readonly I18n = inject(I18nService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly toastService = inject(ToastService);
  readonly cdRef = inject(ChangeDetectorRef);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('resource') public status:StatusResource;

  public inFlight = false;

  text = {
    status: this.I18n.t('js.work_packages.properties.status'),
  };

  public get canRename():boolean {
    return !!this.status && (!!this.status.updateImmediately || !!this.status.$links?.updateImmediately);
  }

  public renameStatus(newName:string):void {
    if (!this.status?.id || !newName || newName.trim() === '' || newName.trim() === this.status.name) {
      return;
    }

    this.inFlight = true;
    this.apiV3Service.statuses.id(this.status.id).patch({ name: newName.trim() })
      .subscribe({
        next: (updatedStatus:StatusResource) => {
          this.status.name = updatedStatus.name;
          this.inFlight = false;
          this.toastService.addSuccess(this.I18n.t('js.notice_successful_update'));
          this.cdRef.detectChanges();
        },
        error: (error:any) => {
          this.inFlight = false;
          this.toastService.addError(error);
          this.cdRef.detectChanges();
        },
      });
  }
}
