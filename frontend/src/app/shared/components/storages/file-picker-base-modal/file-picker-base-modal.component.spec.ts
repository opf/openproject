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

import { ChangeDetectorRef, Component, ElementRef, ChangeDetectionStrategy } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Observable, config, throwError } from 'rxjs';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { FilePickerBaseModalComponent, } from 'core-app/shared/components/storages/file-picker-base-modal/file-picker-base-modal.component';
import { StorageFileListItem } from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import type { Mock } from 'vitest';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'test-file-picker',
  template: '',
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
  standalone: false,
})
class TestFilePickerBaseModalComponent extends FilePickerBaseModalComponent {
  public loadDirectory(directory:IStorageFile):void {
    this.changeLevel(directory);
  }

  protected storageFileToListItem(_file:IStorageFile, _index:number):StorageFileListItem {
    return {} as StorageFileListItem;
  }
}

describe('FilePickerBaseModalComponent', () => {
  interface Spies {
    detectChanges:Mock;
    close:Mock;
    files:Mock;
    reset:Mock;
  }

  function buildComponent(spies:Spies) {
    const locals = {
      service: { close: spies.close },
      storage: {
        name: 'Storage',
        _links: {
          type: { href: 'urn:openproject:test-storage' },
          self: { href: '/api/v3/storages/1' },
        },
      },
      projectFolderMode: 'inactive',
    };

    TestBed.configureTestingModule({
      declarations: [TestFilePickerBaseModalComponent],
      providers: [
        { provide: OpModalLocalsToken, useValue: locals },
        { provide: ChangeDetectorRef, useValue: { detectChanges: spies.detectChanges } },
        { provide: ElementRef, useValue: { nativeElement: document.createElement('div') } },
        { provide: SortFilesPipe, useValue: { transform: (files:IStorageFile[]) => files } },
        { provide: StorageFilesResourceService, useValue: { files: spies.files, reset: spies.reset } },
      ],
    });

    const component = TestBed.runInInjectionContext(() => new TestFilePickerBaseModalComponent());
    component.ngOnInit();

    return { component };
  }

  afterEach(() => TestBed.resetTestingModule());

  it('cancels pending directory loading on destroy', () => {
    const teardown = vi.fn();
    const files$ = new Observable(() => teardown);
    const directory = { location: '/folder', mimeType: 'application/x-op-directory' } as IStorageFile;
    const files = vi.fn().mockReturnValue(files$);
    const { component } = buildComponent({
      detectChanges: vi.fn(),
      close: vi.fn(),
      files,
      reset: vi.fn(),
    });

    component.loadDirectory(directory);

    expect(files).toHaveBeenCalledTimes(2);
    expect(teardown).not.toHaveBeenCalled();

    component.ngOnDestroy();

    expect(teardown).toHaveBeenCalledTimes(1);
  });

  it('does not report directory loading errors as unhandled async exceptions', async () => {
    const previousUnhandledError = config.onUnhandledError;
    const onUnhandledError = vi.fn();
    const files$ = throwError(() => new Error('boom'));
    const detectChanges = vi.fn();
    const directory = { location: '/folder', mimeType: 'application/x-op-directory' } as IStorageFile;
    const { component } = buildComponent({
      detectChanges,
      close: vi.fn(),
      files: vi.fn().mockReturnValue(files$),
      reset: vi.fn(),
    });

    config.onUnhandledError = onUnhandledError;

    component.loadDirectory(directory);
    await new Promise((resolve) => window.setTimeout(resolve));

    expect(component.loading$.getValue()).toBe('error');
    expect(detectChanges).toHaveBeenCalledWith();
    expect(onUnhandledError).not.toHaveBeenCalled();

    config.onUnhandledError = previousUnhandledError;
  });
});
