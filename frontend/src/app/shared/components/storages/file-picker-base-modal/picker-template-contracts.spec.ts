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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ContentLoaderModule } from '@ngneat/content-loader';
import { OpContentLoaderComponent } from 'core-app/shared/components/op-content-loader/op-content-loader.component';
import { CommonModule } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { SpotCheckboxComponent } from 'core-app/spot/components/checkbox/checkbox.component';
import { SpotTooltipComponent } from 'core-app/spot/components/tooltip/tooltip.component';
import { SpotBreadcrumbsComponent } from 'core-app/spot/components/breadcrumbs/breadcrumbs.component';
import { FilePickerModalComponent } from '../file-picker-modal/file-picker-modal.component';
import { LocationPickerModalComponent } from '../location-picker-modal/location-picker-modal.component';
import { LoadingFileListComponent } from '../loading-file-list/loading-file-list.component';
import { StorageFileListItemComponent } from '../storage-file-list-item/storage-file-list-item.component';
import { SortFilesPipe } from '../pipes/sort-files.pipe';

describe('Storage picker template contracts', () => {
  const directory:IStorageFile = {
    id: 'folder-42', name: 'Folder', location: '/folder',
    mimeType: 'application/x-op-directory', permissions: ['readable', 'writeable'],
  };

  function setup<T extends FilePickerModalComponent|LocationPickerModalComponent>(component:new () => T) {
    const files = new Subject<{ parent:IStorageFile; ancestors:IStorageFile[]; files:IStorageFile[] }>();
    const close = vi.fn();
    const reset = vi.fn();
    TestBed.configureTestingModule({
      imports: [CommonModule, IconModule, ContentLoaderModule],
      declarations: [OpContentLoaderComponent, FilePickerModalComponent, LocationPickerModalComponent, LoadingFileListComponent,
        StorageFileListItemComponent, SpotCheckboxComponent, SpotTooltipComponent, SpotBreadcrumbsComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: TimezoneService, useValue: {} },
        { provide: ConfigurationService, useValue: { activeFeatureFlags: [] } },
        { provide: ToastService, useValue: {} },
        { provide: FileLinksResourceService, useValue: {} },
        { provide: SortFilesPipe, useValue: { transform: (values:IStorageFile[]) => values } },
        { provide: StorageFilesResourceService, useValue: { files: () => files, reset } },
        { provide: OpModalLocalsToken, useValue: {
          service: { close }, fileLinks: [], projectFolderMode: 'inactive',
          storage: { name: 'Storage', _links: { type: { href: 'urn:openproject:nextcloud' }, self: { href: '/storages/1' } } },
        } },
      ],
    });
    const fixture = TestBed.createComponent(component);
    fixture.detectChanges();
    return { fixture, files, close, reset, host: fixture.nativeElement as HTMLElement };
  }

  for (const component of [FilePickerModalComponent, LocationPickerModalComponent]) {
    it(`renders loading, empty and unavailable states in ${component.name}`, () => {
      const { fixture, files, host } = setup<FilePickerModalComponent|LocationPickerModalComponent>(component);
      expect(host.querySelector('op-loading-file-list')).not.toBeNull();
      files.next({ parent: directory, ancestors: [], files: [] });
      fixture.detectChanges();
      expect(host.querySelector('op-loading-file-list')).toBeNull();
      expect(host.textContent).toContain('js.storages.files.empty_folder');
      files.error(new Error('unavailable'));
      fixture.detectChanges();
      expect(host.textContent).toContain('js.storages.no_connection');
    });

    it(`preserves directory identity and navigation in ${component.name}`, () => {
      const { fixture, files, host, reset } = setup<FilePickerModalComponent|LocationPickerModalComponent>(component);
      files.next({ parent: directory, ancestors: [], files: [directory] });
      fixture.detectChanges();
      const item = host.querySelector('[op-storage-file-list-item]');
      files.next({ parent: directory, ancestors: [], files: [{ ...directory, name: 'Renamed folder' }] });
      fixture.detectChanges();
      expect(host.querySelector('[op-storage-file-list-item]')).toBe(item);
      expect(host.textContent).toContain('Renamed folder');
      host.querySelector<HTMLButtonElement>('[data-test-selector="op-files-picker-modal--list-item-caret"]')!.click();
      fixture.detectChanges();
      expect(host.querySelector('op-loading-file-list')).not.toBeNull();
      fixture.destroy();
      expect(reset).toHaveBeenCalledExactlyOnceWith();
    });
  }

  it('keeps location confirmation disabled until a writeable directory is loaded', () => {
    const { fixture, files, host, close } = setup(LocationPickerModalComponent);
    const confirm = host.querySelector<HTMLButtonElement>('[data-test-selector="op-files-picker-modal--confirm"]')!;
    expect(confirm.disabled).toBe(true);
    files.next({ parent: { ...directory, permissions: ['readable'] }, ancestors: [], files: [] });
    fixture.detectChanges();
    expect(confirm.disabled).toBe(true);
    files.next({ parent: directory, ancestors: [], files: [] });
    fixture.detectChanges();
    expect(confirm.disabled).toBe(false);
    confirm.click();
    expect(fixture.componentInstance.submitted).toBe(true);
    expect(fixture.componentInstance.location).toBe(directory);
    expect(close).toHaveBeenCalledExactlyOnceWith();
  });
});
