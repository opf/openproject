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

import { CommonModule } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { SpotCheckboxComponent } from 'core-app/spot/components/checkbox/checkbox.component';
import { SpotTooltipComponent } from 'core-app/spot/components/tooltip/tooltip.component';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { StorageFileListItem, StorageFileListItemCheckbox } from './storage-file-list-item';
import { StorageFileListItemComponent } from './storage-file-list-item.component';

describe('StorageFileListItemComponent selection contract', () => {
  function setup(checkbox:StorageFileListItemCheckbox) {
    TestBed.configureTestingModule({
      imports: [CommonModule, IconModule, OpenprojectPrincipalRenderingModule],
      declarations: [StorageFileListItemComponent, SpotCheckboxComponent, SpotTooltipComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: TimezoneService, useValue: {} },
      ],
    });
    const fixture = TestBed.createComponent(StorageFileListItemComponent);
    const file:IStorageFile = {
      id: 'folder-42', name: 'Folder', location: '/folder',
      mimeType: 'application/x-op-directory', permissions: ['readable', 'writeable'],
    };
    const enterDirectory = vi.fn();
    const content = new StorageFileListItem(TestBed.inject(TimezoneService), file, false, true, enterDirectory, false, undefined, checkbox);
    fixture.componentRef.setInput('content', content);
    fixture.detectChanges();
    return { fixture, enterDirectory, host: fixture.nativeElement as HTMLElement };
  }

  it('allows a checkbox without a selection callback', () => {
    const { fixture } = setup({ selected: false });
    const checkbox = fixture.debugElement.query(By.css('spot-checkbox'));
    expect(() => checkbox.triggerEventHandler('checkedChange', true)).not.toThrow();
  });

  it('retains checkbox selection and directory-label navigation', () => {
    const changeSelection = vi.fn();
    const { fixture, enterDirectory, host } = setup({ selected: false, changeSelection });
    fixture.debugElement.query(By.css('spot-checkbox')).triggerEventHandler('checkedChange', true);
    expect(changeSelection).toHaveBeenCalledExactlyOnceWith();
    expect(enterDirectory).not.toHaveBeenCalled();
    host.querySelector<HTMLElement>('.op-file-list--item-title')!.click();
    expect(enterDirectory).toHaveBeenCalledExactlyOnceWith();
  });
});
