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
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { BehaviorSubject, Observable, Subscription } from 'rxjs';
import { map, take } from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { Breadcrumb, BreadcrumbsContent } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';
import {
  StorageFileListItem,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { isDirectory } from 'core-app/shared/components/storages/file-link-icons/file-icons.helper';
import { SortFilesPipe } from 'core-app/shared/components/storages/file-picker-modal/sort-files.pipe';
import getIconForStorageType from 'core-app/shared/components/storages/storage-icons/get-icon-for-storage-type';

@Component({
  templateUrl: 'file-picker-modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FilePickerModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  public breadcrumbs:BreadcrumbsContent;

  public listItems$:Observable<StorageFileListItem[]>;

  public readonly loading$ = new BehaviorSubject<boolean>(true);

  public readonly text = {
    header: this.i18n.t('js.storages.file_links.select'),
    buttons: {
      openStorage: ():string => this.i18n.t('js.storages.open_storage', { storageType: this.locals.storageTypeName as string }),
      submit: ():string => this.i18n.t('js.storages.file_links.selection_any', { number: this.selectedFileCount }),
      submitEmptySelection: this.i18n.t('js.storages.file_links.selection_none'),
      cancel: this.i18n.t('js.button_cancel'),
      selectAll: this.i18n.t('js.storages.file_links.select_all'),
    },
  };

  public get selectedFileCount():number {
    return this.selection.size;
  }

  private get storageLink():IHalResourceLink {
    return this.locals.storageLink as IHalResourceLink;
  }

  private readonly selection = new Set<string>();

  private readonly fileMap:Record<string, IStorageFile> = {};

  private readonly storageFiles$ = new BehaviorSubject<IStorageFile[]>([]);

  private loadingSubscription:Subscription;

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    private readonly i18n:I18nService,
    private readonly timezoneService:TimezoneService,
    private readonly sortFilesPipe:SortFilesPipe,
    private readonly fileLinksResourceService:FileLinksResourceService,
    private readonly storageFilesResourceService:StorageFilesResourceService,
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

    this.storageFilesResourceService.files(this.makeFilesCollectionLink(null))
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

  public createSelectedFileLinks():void {
    const files = Array.from(this.selection).map((id) => this.fileMap[id]);
    this.fileLinksResourceService.addFileLinks(
      this.locals.collectionKey as string,
      this.locals.addFileLinksHref as string,
      this.storageLink,
      files,
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

  private changeLevel(parent:string|null, crumbs:Breadcrumb[]):void {
    this.cancelCurrentLoading();
    this.loading$.next(true);
    this.breadcrumbs = new BreadcrumbsContent(crumbs);

    this.loadingSubscription = this.storageFilesResourceService.files(this.makeFilesCollectionLink(parent))
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

  private makeFilesCollectionLink(parent:string|null):IHalResourceLink {
    let query = '';
    if (parent !== null) {
      query = `?parent=${parent}`;
    }

    return {
      href: `${this.storageLink.href}/files${query}`,
      title: 'Storage files',
    };
  }

  private storageFileToListItem(file:IStorageFile, index:number):StorageFileListItem {
    const enterDirectoryCallback = isDirectory(file.mimeType)
      ? () => {
        const crumbs = this.breadcrumbs.crumbs;
        const end = crumbs.length + 1;
        const newCrumb:Breadcrumb = {
          text: file.name,
          navigate: () => this.changeLevel(file.location, this.breadcrumbs.crumbs.slice(0, end)),
        };
        this.changeLevel(file.location, crumbs.concat(newCrumb));
      }
      : undefined;

    return new StorageFileListItem(
      this.timezoneService,
      file,
      this.isAlreadyLinked(file),
      index === 0,
      this.selection.has(file.id as string),
      () => { this.changeSelection(file); },
      enterDirectoryCallback,
    );
  }

  private isAlreadyLinked(file:IStorageFile):boolean {
    const currentFileLinks = this.locals.fileLinks as IFileLink[];
    const found = currentFileLinks.find((a) => a.originData.id === file.id);

    return !!found;
  }
}
