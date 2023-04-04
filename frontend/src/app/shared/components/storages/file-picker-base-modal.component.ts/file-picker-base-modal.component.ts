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
  ChangeDetectorRef,
  Directive,
  ElementRef,
  Inject,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { BehaviorSubject, Observable, Subscription } from 'rxjs';
import { map } from 'rxjs/operators';

import { IHalResourceLink } from 'core-app/core/state/hal-resource';
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

@Directive()
export abstract class FilePickerBaseModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  private loadingSubscription:Subscription;

  protected readonly storageFiles$ = new BehaviorSubject<IStorageFile[]>([]);

  protected currentDirectory:IStorageFile;

  protected get storageLink():IHalResourceLink {
    return this.locals.storageLink as IHalResourceLink;
  }

  public breadcrumbs:BreadcrumbsContent = new BreadcrumbsContent([{
    text: this.locals.storageName as string,
    icon: getIconForStorageType(this.locals.storageType as string),
    navigate: () => {},
  }]);

  public listItems$:Observable<StorageFileListItem[]> = this.storageFiles$
    .pipe(
      map((files) =>
        this.sortFilesPipe.transform(files)
          .map((file, index) => this.storageFileToListItem(file, index))),
    );

  public readonly loading$ = new BehaviorSubject<boolean>(true);

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

    const location = this.locals.location as string || '/';

    this.storageFilesResourceService
      .files(makeFilesCollectionLink(this.storageLink, location))
      .subscribe((storageFiles) => {
        this.currentDirectory = storageFiles.parent;
        this.breadcrumbs = this.makeBreadcrumbs(storageFiles.ancestors, storageFiles.parent);
        this.storageFiles$.next(storageFiles.files);
        this.loading$.next(false);
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    this.storageFilesResourceService.reset();
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
    this.loading$.next(true);

    this.loadingSubscription = this.storageFilesResourceService
      .files(makeFilesCollectionLink(this.storageLink, ancestor.location))
      .subscribe((storageFiles) => {
        this.currentDirectory = storageFiles.parent;
        this.breadcrumbs = this.makeBreadcrumbs(storageFiles.ancestors, storageFiles.parent);
        this.storageFiles$.next(storageFiles.files);
        this.loading$.next(false);
      });
  }

  private cancelCurrentLoading():void {
    this.loadingSubscription?.unsubscribe();
  }

  private makeBreadcrumbs(ancestors:IStorageFile[], parent:IStorageFile):BreadcrumbsContent {
    const crumbs = ancestors.concat(parent).map((ancestor):Breadcrumb => {
      const isRoot = ancestor.location === '/';
      const icon = isRoot ? getIconForStorageType(this.locals.storageType as string) : undefined;
      const text = isRoot ? this.locals.storageName as string : ancestor.name;
      return { icon, text, navigate: () => this.changeLevel(ancestor) };
    });

    return new BreadcrumbsContent(crumbs);
  }
}
