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
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  ViewChild,
} from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { JobStatusModalComponent } from 'core-app/features/job-status/job-status-modal/job-status.modal';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpenProjectBackupService } from 'core-app/core/backup/op-backup.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';

export const restoreSelector = 'restore';

@Component({
  selector: restoreSelector,
  templateUrl: './restore.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RestoreComponent implements AfterViewInit {
  public text = {
    restoreInfo: this.i18n.t('js.restore.info'),
    restoreNote: this.i18n.t('js.restore.note'),
    restoreTitle: this.i18n.t('js.restore.title'),
    previewInfo: this.i18n.t('js.restore.preview_info'),
    previewNote: this.i18n.t('js.restore.preview_note'),
    previewTitle: this.i18n.t('js.restore.preview_title'),
    restoreBackup: this.i18n.t('js.restore.restore_backup'),
    previewBackup: this.i18n.t('js.restore.preview_backup'),
  };

  private inputDataset = (this.elementRef.nativeElement as HTMLElement).dataset;

  jobStatusId:string = this.inputDataset.jobStatusId || '';

  backupToken = '';

  backupId:string = this.inputDataset.backupId || '';

  backupComment:string = this.inputDataset.backupComment || '';

  preview:boolean = this.inputDataset.preview !== 'false';

  @InjectField() opBackup:OpenProjectBackupService;

  @ViewChild('backupTokenInput') backupTokenInput:ElementRef;

  constructor(
    readonly elementRef:ElementRef,
    public injector:Injector,
    protected i18n:I18nService,
    protected toastService:ToastService,
    protected opModalService:OpModalService,
    protected pathHelper:PathHelperService,
  ) {
  }

  ngAfterViewInit():void {
    (this.backupTokenInput.nativeElement as HTMLElement).focus();
  }

  public triggerRestore(event:JQuery.TriggeredEvent) {
    if (event) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
      event.stopPropagation();
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
      event.preventDefault();
    }

    const { backupToken } = this;

    this.backupToken = '';

    this.opBackup
      .triggerRestore(backupToken, this.backupId, this.preview)
      .subscribe(
        (resp:HalResource) => {
          this.jobStatusId = resp.jobStatusId as string;
          this.opModalService.show(JobStatusModalComponent, 'global', { jobId: resp.jobStatusId });
        },
        (error:HalError) => {
          this.toastService.addError(error.message);
        },
      );
  }
}
