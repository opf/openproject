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
import { BehaviorSubject } from 'rxjs';
import { take } from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { Breadcrumb, BreadcrumbsContent } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';
import {
  IStorageFileListItem,
} from 'core-app/shared/components/file-links/storage-file-list-item/storage-file-list-item';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { isDirectory } from 'core-app/shared/components/file-links/file-link-icons/file-icons.helper';
import getIconForStorageType from 'core-app/shared/components/file-links/storage-icons/get-icon-for-storage-type';

@Component({
  templateUrl: 'file-picker-modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FilePickerModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  public loading$ = new BehaviorSubject<boolean>(true);

  public listItems$ = new BehaviorSubject<IStorageFileListItem[]>([]);

  public breadcrumbs:BreadcrumbsContent;

  public text = {
    header: this.i18n.t('js.storages.file_links.select'),
    buttons: {
      openStorage: ():string => this.i18n.t('js.storages.open_storage', { storageType: this.locals.storageTypeName as string }),
      submit: ():string => this.i18n.t('js.storages.file_links.selection_any', { number: this.selectedFileCount }),
      submitEmptySelection: this.i18n.t('js.storages.file_links.selection_none'),
      cancel: this.i18n.t('js.button_cancel'),
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

  private storageFiles$ = new BehaviorSubject<IStorageFile[]>([]);

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    private readonly i18n:I18nService,
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

    this.storageFiles$
      .pipe(this.untilDestroyed())
      .subscribe((files) => {
        const fileListItems = files.map((file, index) => this.storageFileToListItem(file, index));
        this.listItems$.next(fileListItems);
        this.loading$.next(false);
      });

    this.storageFilesResourceService.files(this.makeFilesCollectionLink(null))
      .pipe(take(1))
      .subscribe((files) => {
        this.storageFiles$.next(files);
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
    this.storageFilesResourceService.files(this.makeFilesCollectionLink(parent))
      .pipe(take(1))
      .subscribe((files) => {
        this.storageFiles$.next(files);
        this.breadcrumbs = new BreadcrumbsContent(crumbs);
      });
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

  private storageFileToListItem(file:IStorageFile, index:number):IStorageFileListItem {
    const listItem:IStorageFileListItem = {
      disabled: this.isAlreadyLinked(file),
      isFirst: index === 0,
      selected: this.selection.has(file.id as string),
      changeSelection: () => { this.changeSelection(file); },
      ...file,
    };

    if (isDirectory(file.mimeType)) {
      listItem.enterDirectory = () => {
        const crumbs = this.breadcrumbs.crumbs;
        const end = crumbs.length + 1;
        const newCrumb:Breadcrumb = {
          text: file.name,
          navigate: () => this.changeLevel(file.location, this.breadcrumbs.crumbs.slice(0, end)),
        };
        this.changeLevel(file.location, crumbs.concat(newCrumb));
      };
    }
    return listItem;
  }

  private isAlreadyLinked(file:IStorageFile):boolean {
    const currentFileLinks = this.locals.fileLinks as IFileLink[];
    const found = currentFileLinks.find((a) => a.originData.id === file.id);

    return !!found;
  }
}
