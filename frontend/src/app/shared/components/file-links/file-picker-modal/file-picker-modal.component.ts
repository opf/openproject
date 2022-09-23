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

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import {
  StorageFilesBreadcrumbs,
} from 'core-app/shared/components/file-links/storage-files-breadcrumbs/storage-files-breadcrumbs';

@Component({
  templateUrl: 'file-picker-modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FilePickerModalComponent extends OpModalComponent implements OnInit, OnDestroy {
  public loading$ = new BehaviorSubject<boolean>(true);

  public storageFiles$ = new BehaviorSubject<IStorageFile[]>([]);

  public breadCrumbs = new StorageFilesBreadcrumbs(
    [
      { text: 'abc', icon: 'nextcloud-circle', navigate: () => {} },
      { text: 'def', navigate: () => {} },
      { text: 'ghi', navigate: () => {} },
    ],
  );

  public text = {
    header: this.i18n.t('js.storages.file_links.select'),
    buttons: {
      openStorage: ():string => this.i18n.t('js.storages.open_storage', { storageType: this.locals.storageType as string }),
      submit: ():string => this.i18n.t('js.storages.file_links.selection_any', { number: this.selectedFileCount }),
      submitEmptySelection: this.i18n.t('js.storages.file_links.selection_none'),
      cancel: this.i18n.t('js.button_cancel'),
    },
  };

  public get selectedFileCount():number {
    return this.selection.size;
  }

  private readonly selection = new Set<string>();

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    private readonly i18n:I18nService,
    private readonly storageFilesResourceService:StorageFilesResourceService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    const filesLink:IHalResourceLink = {
      href: `${(this.locals.storageLink as IHalResourceLink).href}/files`,
      title: 'Storage files',
    };

    this.storageFilesResourceService.files(filesLink)
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
    this.service.close();
  }

  public changeSelection(file:IStorageFile):void {
    const id = file.id as string;
    if (this.selection.has(id)) {
      this.selection.delete(id);
    } else {
      this.selection.add(id);
    }
  }
}
