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
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnDestroy,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import {
  combineLatest,
  Observable,
  of,
  throwError,
} from 'rxjs';
import {
  catchError,
  filter, first,
  map,
  switchMap,
  take,
  tap,
} from 'rxjs/operators';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFileLink, IFileLinkOriginData } from 'core-app/core/state/file-links/file-link.model';
import { IPrepareUploadLink, IStorage } from 'core-app/core/state/storages/storage.model';
import { IProjectStorage } from 'core-app/core/state/project-storages/project-storage.model';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import {
  fileLinkStatusError,
  nextcloud,
  storageConnected,
} from 'core-app/shared/components/storages/storages-constants.const';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  StorageInformationBox,
} from 'core-app/shared/components/storages/storage-information/storage-information-box';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  FilePickerModalComponent,
} from 'core-app/shared/components/storages/file-picker-modal/file-picker-modal.component';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import {
  LocationPickerModalComponent,
} from 'core-app/shared/components/storages/location-picker-modal/location-picker-modal.component';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { IUploadFile, OpUploadService } from 'core-app/core/upload/upload.service';
import { IUploadLink } from 'core-app/core/state/storage-files/upload-link.model';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  UploadConflictModalComponent,
} from 'core-app/shared/components/storages/upload-conflict-modal/upload-conflict-modal.component';
import { LocationData, UploadData } from 'core-app/shared/components/storages/storage/interfaces';
import isNotNull from 'core-app/core/state/is-not-null';
import compareId from 'core-app/core/state/compare-id';
import isHttpResponse from 'core-app/core/upload/is-http-response';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import {
  StorageInformationService,
} from 'core-app/shared/components/storages/storage-information/storage-information.service';
import { storageLocaleString } from 'core-app/shared/components/storages/functions/storages.functions';
import { storageIconMappings } from 'core-app/shared/components/storages/icons.mapping';
import {
  IStorageFileUploadResponse,
  StorageUploadService,
} from 'core-app/shared/components/storages/upload/storage-upload.service';
import {
  IHalErrorBase, v3ErrorIdentifierMissingEnterpriseToken,
} from 'core-app/features/hal/resources/error-resource';

@Component({
  selector: 'op-storage',
  templateUrl: './storage.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{ provide: OpUploadService, useClass: StorageUploadService }],
})
export class StorageComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input() public resource:HalResource;

  @Input() public projectStorage:IProjectStorage;

  @Input() public allowUploading = true;

  @Input() public allowLinking = true;

  @ViewChild('hiddenFileInput') public filePicker:ElementRef<HTMLInputElement>;

  @Output() public fileRemoved = new EventEmitter<void>();

  @Output() public fileAdded = new EventEmitter<void>();

  fileLinks:Observable<IFileLink[]>;

  storage:Observable<IStorage>;

  disabled:Observable<boolean>;

  storageType:Observable<string>;

  storageErrors:Observable<StorageInformationBox[]>;

  draggingOverDropZone = false;

  dragging = 0;

  icon = {
    storageHeader: (storageType:string) => storageIconMappings[storageType] || storageIconMappings.default,
  };

  text = {
    actions: {
      linkExisting: this.i18n.t('js.storages.link_existing_files'),
      uploadFile: this.i18n.t('js.storages.upload_files'),
    },
    toast: {
      successFileLinksCreated: (count:number):string => this.i18n.t('js.storages.file_links.success_create', { count }),
      uploadFailed: (fileName:string):string => this.i18n.t('js.storages.file_links.upload_error.default', { fileName }),
      uploadFailedNextcloudDetail: this.i18n.t('js.storages.file_links.upload_error.detail.nextcloud'),
      uploadFailedForbidden: (fileName:string):string => this.i18n.t('js.storages.file_links.upload_error.403', { fileName }),
      uploadFailedSizeLimit:
        (fileName:string, storageType:string):string => this.i18n.t(
          'js.storages.file_links.upload_error.413',
          {
            fileName,
            storageType,
          },
        ),
      uploadFailedQuota: (fileName:string):string => this.i18n.t('js.storages.file_links.upload_error.507', { fileName }),
      linkingAfterUploadFailed:
        (fileName:string, workPackageId:string):string => this.i18n.t(
          'js.storages.file_links.link_uploaded_file_error',
          {
            fileName,
            workPackageId,
          },
        ),
      draggingManyFiles: (storageType:string):string => this.i18n.t('js.storages.files.dragging_many_files', { storageType }),
      draggingFolder: (storageType:string):string => this.i18n.t('js.storages.files.dragging_folder', { storageType }),
      uploadingLabel: this.i18n.t('js.label_upload_notification'),
    },
    dropBox: {
      uploadLabel: this.i18n.t('js.storages.upload_files'),
      dropFiles: (name:string):string => this.i18n.t('js.storages.drop_files', { name }),
      dropClickFiles: (name:string):string => this.i18n.t('js.storages.drop_or_click_files', { name }),
    },
    emptyList: (storageType:string):string => this.i18n.t('js.storages.file_links.empty', { storageType }),
    openStorage: (storageType:string):string => this.i18n.t('js.storages.open_storage', { storageType }),
  };

  private get addFileLinksHref():string {
    if (isNewResource(this.resource)) {
      return this.pathHelperService.fileLinksPath();
    }

    return (this.resource.$links as { addFileLink:IHalResourceLink }).addFileLink.href;
  }

  private onGlobalDragLeave:(_event:DragEvent) => void = (_event) => {
    this.dragging = Math.max(this.dragging - 1, 0);
    this.cdRef.detectChanges();
  };

  private onGlobalDragEnd:(_event:DragEvent) => void = (_event) => {
    this.dragging = 0;
    this.cdRef.detectChanges();
  };

  private onGlobalDragEnter:(_event:DragEvent) => void = (_event) => {
    // When the global drag and drop is active and the dragging happens over the DOM
    // elements, the dragenter and dragleave events are always fired in pairs.
    // On dragenter the this.dragging is set to 2 and on dragleave we deduct it to 1,
    // meaning the drag and drop remains active. When the drag and drop action is canceled
    // i.e. by the "Escape" key, an extra dragleave event is fired.
    // In this case this.dragging will be deducted to 0, disabling the active drop areas.
    this.dragging = 2;
    this.cdRef.detectChanges();
  };

  public get openStorageLink() {
    return this.projectStorage._links.openWithConnectionEnsured?.href || this.projectStorage._links.open?.href;
  }

  constructor(
    private readonly i18n:I18nService,
    private readonly cdRef:ChangeDetectorRef,
    private readonly toastService:ToastService,
    private readonly uploadService:OpUploadService,
    private readonly opModalService:OpModalService,
    private readonly timezoneService:TimezoneService,
    private readonly pathHelperService:PathHelperService,
    private readonly storagesResourceService:StoragesResourceService,
    private readonly fileLinkResourceService:FileLinksResourceService,
    private readonly storageInformationService:StorageInformationService,
    private readonly storageFilesResourceService:StorageFilesResourceService,
  ) {
    super();
  }

  ngOnInit():void {
    this.storage = this.storagesResourceService.requireEntity(this.projectStorage._links.storage.href);

    this.fileLinks = this.collectionKey()
      .pipe(
        switchMap((key) => {
          if (isNewResource(this.resource)) {
            return this.fileLinkResourceService.collection(key);
          }

          return this.fileLinkResourceService.requireCollection(key);
        }),
        tap((fileLinks) => {
          if (isNewResource(this.resource)) {
            this.resource.fileLinks = { elements: fileLinks.map((a) => a._links?.self) };
          }
        }),
      );

    this.disabled = combineLatest([
      this.storage,
      this.fileLinks,
    ]).pipe(
      map(([storage, fileLinks]) =>
        this.hasFileLinkViewErrors(fileLinks) || storage._links.authorizationState.href !== storageConnected),
    );

    this.storageType = this.storage
      .pipe(
        map((storage) => this.i18n.t(storageLocaleString(storage._links.type.href))),
      );

    this.storage.pipe(take(1)).subscribe((storage) => {
      (this.uploadService as StorageUploadService).setUploadStrategy(storage._links.type.href);
    });

    this.storageErrors = combineLatest([
      this.storage,
      this.fileLinks,
    ]).pipe(
      this.untilDestroyed(),
      switchMap(([storage, fileLinks]) => this.storageInformationService.storageInformation(storage, fileLinks)),
    );

    document.body.addEventListener('dragenter', this.onGlobalDragEnter);
    document.body.addEventListener('dragleave', this.onGlobalDragLeave);
    document.body.addEventListener('dragend', this.onGlobalDragEnd);
    document.body.addEventListener('drop', this.onGlobalDragEnd);
  }

  ngOnDestroy():void {
    document.body.removeEventListener('dragenter', this.onGlobalDragEnter);
    document.body.removeEventListener('dragleave', this.onGlobalDragLeave);
    document.body.removeEventListener('dragend', this.onGlobalDragEnd);
    document.body.removeEventListener('drop', this.onGlobalDragEnd);
  }

  public removeFileLink(fileLink:IFileLink):void {
    this.collectionKey()
      .pipe(
        switchMap((key) => this.fileLinkResourceService.remove(key, fileLink)),
      )
      .subscribe({
        next: () => { this.fileRemoved.emit(); },
        error: (error:HttpErrorResponse) => this.toastService.addError(error),
      });
  }

  public openLinkFilesDialog():void {
    combineLatest([
      this.storage,
      this.fileLinks,
      this.collectionKey(),
    ]).pipe(first())
      .subscribe(([storage, fileLinks, collectionKey]) => {
        const locals = {
          addFileLinksHref: this.addFileLinksHref,
          projectFolderHref: this.projectStorage._links.projectFolder?.href || null,
          projectFolderMode: this.projectStorage.projectFolderMode,
          storage,
          collectionKey,
          fileLinks,
        };

        this.opModalService.show<FilePickerModalComponent>(FilePickerModalComponent, 'global', locals);
      });
  }

  public triggerFileInput():void {
    this.filePicker.nativeElement.click();
  }

  public onFilePickerChanged():void {
    const fileList = this.filePicker.nativeElement.files;
    if (fileList === null) return;

    this.storageFileUpload(fileList[0]);
    // reset file input, so that selecting the same file again triggers a change
    this.filePicker.nativeElement.value = '';
  }

  private storageFileUpload(file:File):void {
    this.storage
      .pipe(
        switchMap((storage) => this.selectUploadLocation(storage)),
        switchMap((data) => this.resolveUploadConflicts(file, data.files, data.location)),
      )
      .subscribe((data) => {
        this.uploadAndCreateFileLink(data);
      });
  }

  private selectUploadLocation(storage:IStorage):Observable<LocationData> {
    const locals = {
      projectFolderHref: this.projectStorage._links.projectFolder?.href,
      projectFolderMode: this.projectStorage.projectFolderMode,
      storage,
    };

    return this.opModalService.show<LocationPickerModalComponent>(LocationPickerModalComponent, 'global', locals)
      .pipe(
        switchMap((modal) => modal.closingEvent),
        filter((modal) => modal.submitted),
        first(),
        map((modal) => ({ location: modal.location.id as string, files: modal.filesAtLocation })),
      );
  }

  private resolveUploadConflicts(file:File, storageFiles:IStorageFile[], location:string):Observable<UploadData> {
    const conflict = storageFiles.find((f) => f.name === file.name);
    if (!conflict) {
      return of({ file, location, overwrite: null });
    }

    return this.opModalService.show<UploadConflictModalComponent>(UploadConflictModalComponent, 'global', { fileName: file.name })
      .pipe(
        switchMap((modal) => modal.closingEvent),
        filter((modal) => modal.overwrite !== null),
        take(1),
        map((modal) => ({ file, location, overwrite: modal.overwrite })),
      );
  }

  private uploadAndCreateFileLink(data:UploadData):void {
    let isUploadError = false;

    this.storage
      .pipe(
        switchMap((storage) => {
          const link = this.uploadResourceLink(storage, data.file.name, data.location);
          return this.storageFilesResourceService.uploadLink(link);
        }),
        switchMap((link) => this.uploadAndNotify(link, data.file, data.overwrite)),
        catchError((error) => {
          isUploadError = true;
          return throwError(error);
        }),
        switchMap((uploadResponse) => this.createFileLinkData(uploadResponse)),
        tap((fileLinkCreationData) => {
          // Update the file link list of this storage only in case of a linked file got updated
          if (fileLinkCreationData === null) {
            this.collectionKey()
              .pipe(switchMap((key) => this.fileLinkResourceService.fetchCollection(key)))
              .subscribe();
          }
        }),
        filter(isNotNull),
        switchMap((file) =>
          combineLatest([
            this.storage.pipe(first()),
            this.collectionKey(),
          ])
            .pipe(
              switchMap(([storage, collectionKey]) => this.fileLinkResourceService.addFileLinks(
                collectionKey,
                this.addFileLinksHref,
                storage._links.self,
                [file],
              )),
            )),
      )
      .subscribe({
        next: (collection) => {
          this.toastService.addSuccess(this.text.toast.successFileLinksCreated(collection.count));
          this.fileAdded.emit();
        },
        error: (error) => {
          if (isUploadError) {
            this.handleUploadError(error as HttpErrorResponse, data.file.name);
          } else {
            this.toastService.addError(this.text.toast.linkingAfterUploadFailed(data.file.name, this.resource.id as string));
          }

          console.error(error);
        },
      });
  }

  private handleUploadError(error:HttpErrorResponse, fileName:string):void {
    if (error.status === 500 && (error.error as IHalErrorBase).errorIdentifier === v3ErrorIdentifierMissingEnterpriseToken) {
      this.toastService.addError(error);
      return;
    }

    switch (error.status) {
      case 403:
        this.toastService.addError(this.text.toast.uploadFailedForbidden(fileName));
        break;
      case 413:
        this.storage
          .pipe(first())
          .subscribe((storage) => {
            const storageType = this.i18n.t(storageLocaleString(storage._links.type.href));
            const toast = this.text.toast.uploadFailedSizeLimit(fileName, storageType);
            this.toastService.addError(toast);
          });
        break;
      case 507:
        this.toastService.addError(this.text.toast.uploadFailedQuota(fileName));
        break;
      default:
        this.storage
          .pipe(first())
          .subscribe((storage) => {
            const additionalInfo = storage._links.type.href === nextcloud ? this.text.toast.uploadFailedNextcloudDetail : [];
            this.toastService.addError(this.text.toast.uploadFailed(fileName), additionalInfo);
          });
    }
  }

  private uploadAndNotify(link:IUploadLink, file:File, overwrite:boolean|null):Observable<IStorageFileUploadResponse> {
    const { href } = link._links.destination;
    const uploadFiles:IUploadFile[] = [{ file, overwrite: overwrite !== null ? overwrite : undefined }];
    const observable = this.uploadService.upload<IStorageFileUploadResponse>(href, uploadFiles)[0];
    this.toastService.addUpload(this.text.toast.uploadingLabel, [[file, observable]]);

    return observable
      .pipe(
        filter(isHttpResponse),
        map((ev) => ev.body),
        map((data) => {
          if (data === null) {
            throw new Error('Upload data is null.');
          }

          return data;
        }),
      );
  }

  private createFileLinkData(response:IStorageFileUploadResponse):Observable<IFileLinkOriginData|null> {
    return this.fileLinks
      .pipe(
        take(1),
        map((fileLinks) => {
          const existingFileLink = fileLinks.find((l) => compareId(l.originData.id, response.id));
          if (existingFileLink) {
            return null;
          }

          const now = this.timezoneService.parseDate(new Date()).toISOString();
          return ({
            id: response.id,
            name: response.name,
            mimeType: response.mimeType,
            size: response.size,
            createdAt: now,
            lastModifiedAt: now,
          });
        }),
      );
  }

  private uploadResourceLink(storage:IStorage, fileName:string, location:string):IPrepareUploadLink {
    const project = (this.resource.project as { id:string }).id;
    const link = storage._links.prepareUpload.filter((value) => project === value.payload.projectId.toString());
    if (link.length === 0) {
      throw new Error('Cannot upload to this storage. Missing permissions in project.');
    }

    return {
      href: link[0].href,
      method: link[0].method,
      title: link[0].title,
      payload: {
        projectId: link[0].payload.projectId,
        parent: location,
        fileName,
      },
    };
  }

  private hasFileLinkViewErrors(fileLinks:IFileLink[]):boolean {
    return fileLinks.filter((fileLink) => fileLink._links.status?.href === fileLinkStatusError).length > 0;
  }

  private collectionKey():Observable<string> {
    return isNewResource(this.resource)
      ? of('new')
      : this.storage.pipe(
        first(),
        map((storage) => this.fileLinkSelfLink(storage)),
      );
  }

  private fileLinkSelfLink(storage:IStorage):string {
    const fileLinks = this.resource.fileLinks as { href:string };
    return `${fileLinks.href}?filters=[{"storage":{"operator":"=","values":["${storage.id}"]}}]`;
  }

  public onDropFiles(event:DragEvent):void {
    if (event.dataTransfer === null) return;

    this.draggingOverDropZone = false;
    this.dragging = 0;

    const files = event.dataTransfer.files;
    const draggingManyFiles = files.length !== 1;
    const isDirectory = event.dataTransfer.items[0].webkitGetAsEntry()?.isDirectory;
    if (draggingManyFiles || isDirectory) {
      this.storageType
        .pipe(first())
        .subscribe((storageType) => {
          const toast = draggingManyFiles
            ? this.text.toast.draggingManyFiles(storageType)
            : this.text.toast.draggingFolder(storageType);
          this.toastService.addError(toast);
        });
      return;
    }

    this.storageFileUpload(files[0]);
  }

  public onDragOver(event:DragEvent):void {
    const containsFiles = (dataTransfer:DataTransfer):boolean => dataTransfer.types.indexOf('Files') >= 0;

    if (event.dataTransfer !== null && containsFiles(event.dataTransfer)) {
      // eslint-disable-next-line no-param-reassign
      event.dataTransfer.dropEffect = 'copy';
      this.draggingOverDropZone = true;
    }
  }

  public onDragLeave(_event:DragEvent):void {
    this.draggingOverDropZone = false;
  }
}
