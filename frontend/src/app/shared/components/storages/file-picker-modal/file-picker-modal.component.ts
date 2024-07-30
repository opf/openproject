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
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject,
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, take } from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { isDirectory, storageLocaleString } from 'core-app/shared/components/storages/functions/storages.functions';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import {
  StorageFileListItem,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import {
  FilePickerBaseModalComponent,
} from 'core-app/shared/components/storages/file-picker-base-modal/file-picker-base-modal.component';

@Component({
  templateUrl: 'file-picker-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FilePickerModalComponent extends FilePickerBaseModalComponent {
  public readonly text = {
    header: this.i18n.t('js.storages.file_links.select'),
    alertNoAccess: this.i18n.t('js.storages.files.project_folder_no_access'),
    alertNoManagedProjectFolder: this.i18n.t('js.storages.files.managed_project_folder_not_available'),
    alertNoAccessToManagedProjectFolder: this.i18n.t('js.storages.files.managed_project_folder_no_access'),
    content: {
      empty: this.i18n.t('js.storages.files.empty_folder'),
      emptyHint: this.i18n.t('js.storages.files.empty_folder_location_hint'),
      noConnection: (storageType:string) => this.i18n.t('js.storages.no_connection', { storageType }),
      noConnectionHint: (storageType:string) => this.i18n.t('js.storages.information.connection_error', { storageType }),
    },
    buttons: {
      submit: (count:number):string => this.i18n.t('js.storages.file_links.selection', { count }),
      cancel: this.i18n.t('js.button_cancel'),
      selectAll: this.i18n.t('js.storages.file_links.select_all'),
    },
    tooltip: {
      alreadyLinkedFile: this.i18n.t('js.storages.file_links.already_linked_file'),
      alreadyLinkedDirectory: this.i18n.t('js.storages.file_links.already_linked_directory'),
    },
    toast: {
      successFileLinksCreated: (count:number):string => this.i18n.t('js.storages.file_links.success_create', { count }),
    },
  };

  public get selectedFileCount():number {
    return this.selection.size;
  }

  public get storageType():string {
    return this.i18n.t(storageLocaleString(this.storage._links.type.href));
  }

  public get alertText():Observable<string> {
    return this.showAlert
      .pipe(
        map((alert) => {
          switch (alert) {
            case 'noAccess':
              return this.text.alertNoAccess;
            case 'managedFolderNoAccess':
              return this.text.alertNoAccessToManagedProjectFolder;
            case 'managedFolderNotFound':
              return this.text.alertNoManagedProjectFolder;
            case 'none':
              return '';
            default:
              throw new Error('unknown alert type');
          }
        }),
      );
  }

  public showSelectAll = false;

  private readonly selection = new Set<string>();

  private readonly fileMap:Record<string, IStorageFile> = {};

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    protected readonly sortFilesPipe:SortFilesPipe,
    protected readonly storageFilesResourceService:StorageFilesResourceService,
    private readonly i18n:I18nService,
    private readonly toastService:ToastService,
    private readonly timezoneService:TimezoneService,
    private readonly configuration:ConfigurationService,
    private readonly fileLinksResourceService:FileLinksResourceService,
  ) {
    super(
      locals,
      elementRef,
      cdRef,
      sortFilesPipe,
      storageFilesResourceService,
    );

    this.showSelectAll = this.configuration.activeFeatureFlags.includes('storageFilePickingSelectAll');
  }

  public createSelectedFileLinks():void {
    const files = Array.from(this.selection).map((id) => this.fileMap[id]);
    this.fileLinksResourceService.addFileLinks(
      this.locals.collectionKey as string,
      this.locals.addFileLinksHref as string,
      this.storage._links.self,
      files,
    ).subscribe(
      (fileLinks) => { this.toastService.addSuccess(this.text.toast.successFileLinksCreated(fileLinks.count)); },
      (error:HttpErrorResponse) => { this.toastService.addError(error); },
    );

    this.service.close();
  }

  public selectAllOfCurrentLevel():void {
    this.storageFiles$
      .pipe(take(1))
      .subscribe((files) => {
        files.forEach((file) => {
          const id = file.id as string;
          if (!this.selection.has(id) && !this.isAlreadyLinked(file)) {
            this.selection.add(id);
            this.fileMap[id] = file;
          }
        });

        // push the file data again to the subject
        // to trigger a rerender with new selection state
        this.storageFiles$.next(files);
      });
  }

  public changeSelection(file:IStorageFile):void {
    const fileId = file.id as string;
    if (this.selection.has(fileId)) {
      this.selection.delete(fileId);
    } else {
      this.selection.add(fileId);
      this.fileMap[fileId] = file;
    }
  }

  protected storageFileToListItem(file:IStorageFile, index:number):StorageFileListItem {
    return new StorageFileListItem(
      this.timezoneService,
      file,
      this.isAlreadyLinked(file),
      index === 0,
      this.enterDirectoryCallback(file),
      false,
      this.tooltip(file),
      {
        selected: this.selection.has(file.id as string),
        changeSelection: () => { this.changeSelection(file); },
      },
    );
  }

  private isAlreadyLinked(file:IStorageFile):boolean {
    const currentFileLinks = this.locals.fileLinks as IFileLink[];
    const found = currentFileLinks.find((a) => a.originData.id === file.id);

    return !!found;
  }

  private tooltip(file:IStorageFile):string|undefined {
    if (!this.isAlreadyLinked(file)) {
      return undefined;
    }

    return isDirectory(file) ? this.text.tooltip.alreadyLinkedDirectory : this.text.tooltip.alreadyLinkedFile;
  }
}
