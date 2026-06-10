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

import { AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, Injector, ViewChild, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { OpenProjectBackupService } from 'core-app/core/backup/op-backup.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { JobStatusModalService } from 'core-app/features/job-status/job-status-modal.service';

@Component({
  selector: 'opce-backup',
  templateUrl: './backup.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class BackupComponent implements AfterViewInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  injector = inject(Injector);
  protected i18n = inject(I18nService);
  protected toastService = inject(ToastService);
  protected pathHelper = inject(PathHelperService);
  protected jobStatusModalService = inject(JobStatusModalService);

  public text = {
    info: this.i18n.t('js.backup.info'),
    note: this.i18n.t('js.backup.note'),
    title: this.i18n.t('js.backup.title'),
    lastBackup: this.i18n.t('js.backup.last_backup'),
    lastBackupFrom: this.i18n.t('js.backup.last_backup_from'),
    includeAttachments: this.i18n.t('js.backup.include_attachments'),
    options: this.i18n.t('js.backup.options'),
    downloadBackup: this.i18n.t('js.backup.download_backup'),
    requestBackup: this.i18n.t('js.backup.request_backup'),
    attachmentsDisabled: this.i18n.t('js.backup.attachments_disabled'),
  };

  public jobStatusId = this.elementRef.nativeElement.dataset.jobStatusId!;

  public lastBackupDate = this.elementRef.nativeElement.dataset.lastBackupDate!;

  public lastBackupAttachmentId = this.elementRef.nativeElement.dataset.lastBackupAttachmentId!;

  public mayIncludeAttachments = this.elementRef.nativeElement.dataset.mayIncludeAttachments !== 'false';

  public includeAttachments = true;

  public backupToken = '';

  readonly opBackup = inject(OpenProjectBackupService);

  @ViewChild('backupTokenInput') backupTokenInput:ElementRef<HTMLInputElement>;

  constructor() {
    this.includeAttachments = this.mayIncludeAttachments;
  }

  ngAfterViewInit():void {
    this.backupTokenInput.nativeElement.focus();
  }

  public isDownloadReady():boolean {
    return this.jobStatusId !== undefined && this.jobStatusId !== ''
      && this.lastBackupAttachmentId !== undefined && this.lastBackupAttachmentId !== '';
  }

  public getDownloadUrl():string {
    return this.pathHelper.attachmentDownloadPath(this.lastBackupAttachmentId, undefined);
  }

  public triggerBackup(event?:Event) {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }

    const { backupToken } = this;

    this.backupToken = '';

    this.opBackup
      .triggerBackup(backupToken, this.includeAttachments)
      .subscribe(
        (resp:HalResource) => {
          this.jobStatusId = resp.jobStatusId as string;
          this.jobStatusModalService.show(resp.jobStatusId as string);
        },
        (error:HalError) => {
          this.toastService.addError(error.message);
        },
      );
  }
}
