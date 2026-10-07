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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CKEditorSetupService } from './ckeditor-setup.service';
import { CodeMirrorLoaderService } from './codemirror-loader.service';
import { OpCkeditorComponent } from './op-ckeditor.component';
import type { ICKEditorInstance, ICKEditorWatchdog } from './ckeditor.types';

describe('OpCkeditorComponent', () => {
  let component:OpCkeditorComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [OpCkeditorComponent],
      providers: [
        { provide: ToastService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ConfigurationService, useValue: {} },
        { provide: CKEditorSetupService, useValue: {} },
        { provide: CodeMirrorLoaderService, useValue: {} },
      ],
    })
      .overrideComponent(OpCkeditorComponent, { set: { template: '' } })
      .compileComponents();

    vi.spyOn(OpCkeditorComponent.prototype, 'ngOnInit').mockImplementation(() => undefined);
    component = TestBed.createComponent(OpCkeditorComponent).componentInstance;
  });

  afterEach(() => vi.restoreAllMocks());

  it('handles a rejected watchdog destruction', async () => {
    const error = new Error('Destruction failed');
    component.watchdog = {
      destroy: vi.fn().mockResolvedValue(undefined).mockRejectedValueOnce(error),
    } as unknown as ICKEditorWatchdog;
    const log = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    component.ngOnDestroy();

    await vi.waitFor(() => expect(log).toHaveBeenCalledWith('Failed to destroy CKEditor instance:', error));
  });

  it('can be destroyed before a watchdog is created', () => {
    const log = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    component.ngOnDestroy();

    expect(log).not.toHaveBeenCalled();
  });

  it('requests untrimmed editor data', () => {
    const getData = vi.fn().mockReturnValue(' ');
    component.ckEditorInstance = { getData } as unknown as ICKEditorInstance;

    expect(component.getRawData()).toBe(' ');
    expect(getData).toHaveBeenCalledWith({ trim: 'none' });
  });
});
