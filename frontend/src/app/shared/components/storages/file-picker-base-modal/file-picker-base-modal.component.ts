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
  ChangeDetectorRef,
  Directive,
  ElementRef,
  Inject,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import {
  BehaviorSubject,
  Observable,
  of,
  Subscription,
  switchMap,
} from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { IStorage } from 'core-app/core/state/storages/storage.model';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { Breadcrumb, BreadcrumbsContent } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';
import {
  StorageFileListItem,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import {
  isDirectory,
  getIconForStorageType,
  makeFilesCollectionLink,
} from 'core-app/shared/components/storages/functions/storages.functions';
import {
  IHalErrorBase,
  v3ErrorIdentifierOutboundRequestForbidden,
} from 'core-app/features/hal/resources/error-resource';

type Alert = 'none'|'noAccess'|'managedFolderNoAccess'|'managedFolderNotFound';

@Directive()
export abstract class FilePickerBaseModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  private loadingSubscription:Subscription;

  protected readonly storageFiles$ = new BehaviorSubject<IStorageFile[]>([]);

  protected currentDirectory:IStorageFile;

  protected get storage():IStorage {
    return this.locals.storage as IStorage;
  }

  public breadcrumbs:BreadcrumbsContent = new BreadcrumbsContent([{
    text: this.storage.name,
    icon: getIconForStorageType(this.storage._links.type.href),
    navigate: () => {},
  }]);

  public showAlert:BehaviorSubject<Alert> = new BehaviorSubject('none');

  public listItems$:Observable<StorageFileListItem[]> = this.storageFiles$
    .pipe(
      map((files) =>
        this.sortFilesPipe.transform(files)
          .map((file, index) => this.storageFileToListItem(file, index))),
    );

  public readonly loading$ = new BehaviorSubject<'loading'|'success'|'error'>('loading');

  protected constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    protected readonly sortFilesPipe:SortFilesPipe,
    protected readonly storageFilesResourceService:StorageFilesResourceService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    this.entryLocation()
      .pipe(
        this.untilDestroyed(),
        switchMap((location:string) => this.storageFilesResourceService.files(makeFilesCollectionLink(this.storage._links.self, location))),
      )
      .subscribe({
        next: (storageFiles) => {
          this.currentDirectory = storageFiles.parent;
          this.breadcrumbs = this.makeBreadcrumbs(storageFiles.ancestors, storageFiles.parent);
          this.storageFiles$.next(storageFiles.files);
          this.loading$.next('success');
        },
        error: (error) => {
          this.loading$.next('error');
          throw error;
        },
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    this.storageFilesResourceService.reset();
  }

  public closeAlert():void {
    this.showAlert.next('none');
  }

  protected abstract storageFileToListItem(file:IStorageFile, index:number):StorageFileListItem;

  protected enterDirectoryCallback(directory:IStorageFile):() => void {
    if (!isDirectory(directory)) {
      return () => {};
    }

    return () => this.changeLevel(directory);
  }

  protected changeLevel(ancestor:IStorageFile):void {
    this.cancelCurrentLoading();
    this.loading$.next('loading');

    this.loadingSubscription = this.storageFilesResourceService
      .files(makeFilesCollectionLink(this.storage._links.self, ancestor.location))
      .subscribe({
        next: (storageFiles) => {
          this.currentDirectory = storageFiles.parent;
          this.breadcrumbs = this.makeBreadcrumbs(storageFiles.ancestors, storageFiles.parent);
          this.storageFiles$.next(storageFiles.files);
          this.loading$.next('success');
        },
        error: (error) => {
          this.loading$.next('error');
          throw error;
        },
      });
  }

  private entryLocation():Observable<string> {
    if (this.locals.projectFolderMode === 'inactive' || this.locals.projectFolderMode === undefined) {
      return of('/');
    }

    if (this.locals.projectFolderMode === 'automatic' && this.locals.projectFolderHref === null) {
      this.showAlert.next('managedFolderNotFound');
      return of('/');
    }

    return this.storageFilesResourceService
      .file(this.locals.projectFolderHref as string)
      .pipe(
        map((file) => file.location),
        catchError((response:HttpErrorResponse) => {
          const isForbiddenOnStorage = response.status === 500
            && (response.error as IHalErrorBase).errorIdentifier === v3ErrorIdentifierOutboundRequestForbidden;

          if (!isForbiddenOnStorage) {
            throw new Error(response.message);
          }

          if (this.locals.projectFolderMode === 'automatic') {
            this.showAlert.next('managedFolderNoAccess');
          } else {
            this.showAlert.next('noAccess');
          }
          return of('/');
        }),
      );
  }

  private cancelCurrentLoading():void {
    this.loadingSubscription?.unsubscribe();
  }

  private makeBreadcrumbs(ancestors:IStorageFile[], parent:IStorageFile):BreadcrumbsContent {
    const crumbs = ancestors.concat(parent).map((ancestor):Breadcrumb => {
      const isRoot = ancestor.location === '/';
      const icon = isRoot ? getIconForStorageType(this.storage._links.type.href) : undefined;
      const text = isRoot ? this.storage.name : ancestor.name;
      return { icon, text, navigate: () => this.changeLevel(ancestor) };
    });

    return new BreadcrumbsContent(crumbs);
  }
}
