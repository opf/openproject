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
  ChangeDetectorRef,
  Directive,
  ElementRef,
  Inject,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { BehaviorSubject, Observable, Subscription } from 'rxjs';
import { map, take } from 'rxjs/operators';

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
  public breadcrumbs:BreadcrumbsContent;

  public listItems$:Observable<StorageFileListItem[]>;

  public readonly loading$ = new BehaviorSubject<boolean>(true);

  protected get storageLink():IHalResourceLink {
    return this.locals.storageLink as IHalResourceLink;
  }

  protected readonly storageFiles$ = new BehaviorSubject<IStorageFile[]>([]);

  private loadingSubscription:Subscription;

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

    this.breadcrumbs = new BreadcrumbsContent([{
      text: this.locals.storageName as string,
      icon: getIconForStorageType(this.locals.storageType as string),
      navigate: () => this.changeLevel(null, this.breadcrumbs.crumbs.slice(0, 1)),
    }]);

    this.listItems$ = this.storageFiles$
      .pipe(
        map((files) =>
          this.sortFilesPipe.transform(files)
            .map((file, index) => this.storageFileToListItem(file, index))),
      );

    this.storageFilesResourceService.files(makeFilesCollectionLink(this.storageLink, null))
      .pipe(take(1))
      .subscribe((files) => {
        this.storageFiles$.next(files);
        this.loading$.next(false);
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    this.storageFilesResourceService.reset();
  }

  public openStorageLocation():void {
    window.open(this.locals.storageLocation, '_blank');
  }

  protected abstract storageFileToListItem(file:IStorageFile, index:number):StorageFileListItem;

  protected enterDirectoryCallback(directory:IStorageFile):() => void {
    if (!isDirectory(directory.mimeType)) {
      return () => {};
    }

    return () => {
      const crumbs = this.breadcrumbs.crumbs;
      const end = crumbs.length + 1;
      const newCrumb:Breadcrumb = {
        text: directory.name,
        navigate: () => this.changeLevel(directory.location, this.breadcrumbs.crumbs.slice(0, end)),
      };
      this.changeLevel(directory.location, crumbs.concat(newCrumb));
    };
  }

  private changeLevel(parent:string|null, crumbs:Breadcrumb[]):void {
    this.cancelCurrentLoading();
    this.loading$.next(true);
    this.breadcrumbs = new BreadcrumbsContent(crumbs);

    this.loadingSubscription = this.storageFilesResourceService.files(makeFilesCollectionLink(this.storageLink, parent))
      .pipe(take(1))
      .subscribe((files) => {
        this.storageFiles$.next(files);
        this.loading$.next(false);
      });
  }

  private cancelCurrentLoading():void {
    if (this.loadingSubscription) {
      this.loadingSubscription.unsubscribe();
    }
  }
}
