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

import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CKEditorSetupService, ICKEditorType } from './ckeditor-setup.service';
import type { ICKEditorInstance } from './ckeditor.types';
import autosavePackage from '@ckeditor/ckeditor5-autosave/package.json';
import corePackage from '@ckeditor/ckeditor5-core/package.json';
import editorDecoupledPackage from '@ckeditor/ckeditor5-editor-decoupled/package.json';
import enginePackage from '@ckeditor/ckeditor5-engine/package.json';
import linkPackage from '@ckeditor/ckeditor5-link/package.json';
import utilsPackage from '@ckeditor/ckeditor5-utils/package.json';

describe('CKEditorSetupService with the vendored editor', () => {
  let service:CKEditorSetupService;
  let wrapper:HTMLDivElement;
  let editor:ICKEditorInstance|undefined;
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
    await editor?.destroy();
    editor = undefined;
    wrapper.remove();
    localStorage.removeItem(storageKey);
    vi.unstubAllGlobals();
  });

  it.each<ICKEditorType>(['full', 'constrained'])('creates, saves and destroys the %s editor', async (type) => {
    const created = await service.create(wrapper, { type, macros: false, storageKey }, 'Original text');
    editor = created;

    expect(created.state).toBe('ready');
    expect(within(wrapper).getByRole('toolbar')).toBeInTheDocument();
    expect(within(wrapper).getByRole('textbox')).toHaveTextContent('Original text');

    fireEvent(wrapper, new CustomEvent('op:ckeditor:setData', { detail: 'Updated text' }));
    expect(within(wrapper).getByRole('textbox')).toHaveTextContent('Updated text');

    fireEvent(wrapper, new Event('op:ckeditor:autosave'));
    await waitFor(() => expect(localStorage.getItem(storageKey)).not.toBeNull());

    await created.destroy();
    expect(created.state).toBe('destroyed');
    editor = undefined;
  });

  it.each([
    autosavePackage,
    corePackage,
    editorDecoupledPackage,
    enginePackage,
    linkPackage,
    utilsPackage,
  ])('bundles the CKEditor version that $name declares types for', ({ version }) => {
    expect(globalThis.CKEDITOR_VERSION).toBe(version);
  });
});
