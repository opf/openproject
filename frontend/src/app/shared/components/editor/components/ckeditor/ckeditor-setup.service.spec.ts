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
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CKEditorSetupService, ICKEditorType } from './ckeditor-setup.service';
import type { ICKEditorWatchdog } from './ckeditor.types';

describe('CKEditorSetupService with the vendored editor', () => {
  let service:CKEditorSetupService;
  let wrapper:HTMLDivElement;
  let watchdog:ICKEditorWatchdog|undefined;
  const storageKey = 'op-20399-editor-spec';

  beforeAll(async () => {
    await import('core-vendor/ckeditor/ckeditor');
  });

  beforeEach(() => {
    vi.stubGlobal('OpenProject', {
      pluginContext: { value: {
        services: { i18n: { t: (key:string) => key }, notifications: { addError: vi.fn() } },
        helpers: {},
      } },
    });
    TestBed.configureTestingModule({
      providers: [
        CKEditorSetupService,
        { provide: PathHelperService, useValue: { textFormattingHelp: () => '/help', wikiPath: undefined } },
        { provide: ConfigurationService, useValue: { allowedLinkProtocols: [] } },
      ],
    });
    service = TestBed.inject(CKEditorSetupService);
    wrapper = document.createElement('div');
    wrapper.innerHTML = '<div class="document-editor__toolbar"></div><div class="document-editor__editable"></div>';
    document.body.appendChild(wrapper);
  });

  afterEach(async () => {
    await watchdog?.destroy();
    watchdog = undefined;
    wrapper.remove();
    localStorage.removeItem(storageKey);
    vi.unstubAllGlobals();
  });

  it.each<ICKEditorType>(['full', 'constrained'])('creates, saves and destroys the %s editor', async (type) => {
    watchdog = await service.create(wrapper, { type, macros: false, storageKey }, 'Original text');
    const editor = watchdog.editor!;

    expect(watchdog.state).toBe('ready');
    expect(wrapper.querySelector('.document-editor__toolbar .ck-toolbar')).not.toBeNull();
    expect(editor.getData()).toContain('Original text');

    wrapper.dispatchEvent(new CustomEvent('op:ckeditor:setData', { detail: 'Updated text' }));
    expect(editor.getData()).toContain('Updated text');

    wrapper.dispatchEvent(new Event('op:ckeditor:autosave'));
    await vi.waitFor(() => expect(localStorage.getItem(storageKey)).not.toBeNull());

    await watchdog.destroy();
    expect(watchdog.state).toBe('destroyed');
    expect(watchdog.editor).toBeNull();
    watchdog = undefined;
  });
});
