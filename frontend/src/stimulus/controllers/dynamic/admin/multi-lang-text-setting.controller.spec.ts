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

import MultiLangTextSetting from './multi-lang-text-setting.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type { Mock } from 'vitest';
import { ICKEditorInstance } from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';

describe('MultiLangTextSetting', () => {
  let ctx:StimulusTestContext;
  let editorData:string;
  let editor:{ getData:Mock<() => string>; setData:Mock<(data:string) => void> };

  function switchLanguage(select:HTMLSelectElement, lang:string) {
    select.dispatchEvent(new FocusEvent('focus'));
    select.value = lang;
    select.dispatchEvent(new Event('change'));
  }

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'admin--multi-lang-text-setting': MultiLangTextSetting },
    });

    await ctx.mount(`
      <div data-controller="admin--multi-lang-text-setting">
        <label for="lang-for-admin_field">Admin Field</label>
        <select id="lang-for-admin_field"
                name="settings[admin_field]"
                data-admin--multi-lang-text-setting-target="select">
          <option value="en" selected>English</option>
          <option value="de">Deutsch</option>
        </select>
        <input type="hidden"
               name="settings[admin_field][de]"
               value="Initial German content"
               data-admin--multi-lang-text-setting-target="langFor"
               data-lang="de">
        <input type="hidden"
               name="settings[admin_field][en]"
               value="Initial English content"
               data-admin--multi-lang-text-setting-target="langFor"
               data-lang="en"
               data-testid="hidden-en-input">
        <textarea id="settings_admin_field_en"
                  name="settings[admin_field][en]"
                  data-admin--multi-lang-text-setting-target="textArea">Initial textarea content</textarea>
        <opce-ckeditor-augmented-textarea data-text-area-id='"settings_admin_field_en"'>
          <div class="ck-editor__editable_inline"></div>
        </opce-ckeditor-augmented-textarea>
      </div>
    `);
    editorData = 'Initial editor content';
    editor = {
      getData: vi.fn(() => editorData),
      setData: vi.fn((data:string) => { editorData = data; }),
    };
    const editable = ctx.container.querySelector<HTMLElement>('.ck-editor__editable_inline')!;
    editable.ckeditorInstance = editor as unknown as ICKEditorInstance;
  });

  afterEach(() => ctx.dispose());

  it('stores the editor content in a hidden field for the current language on focus', () => {
    const hiddenEnInput = ctx.screen.getByTestId('hidden-en-input');
    const select = ctx.screen.getByRole('combobox');

    expect(hiddenEnInput).toHaveValue('Initial English content');
    editor.setData('New English content');

    select.dispatchEvent(new FocusEvent('focus'));

    expect(hiddenEnInput).toHaveValue('New English content');
  });

  it('loads the text for the selected language and changes the textarea name upon language change', () => {
    const select = ctx.screen.getByRole<HTMLSelectElement>('combobox');
    const textArea = ctx.screen.getByRole<HTMLTextAreaElement>('textbox');

    expect(editor.getData()).toBe('Initial editor content');
    expect(textArea).toHaveAttribute('name', 'settings[admin_field][en]');

    select.value = 'de';
    select.dispatchEvent(new Event('change'));

    expect(editor.getData()).toBe('Initial German content');
    expect(textArea).toHaveAttribute('name', 'settings[admin_field][de]');

    select.value = 'en';
    select.dispatchEvent(new Event('change'));

    expect(editor.getData()).toBe('Initial English content');
    expect(textArea).toHaveAttribute('name', 'settings[admin_field][en]');
  });

  it('keeps edits for each language when switching back and forth', () => {
    const select = ctx.screen.getByRole<HTMLSelectElement>('combobox');
    editor.setData('New English content');

    switchLanguage(select, 'de');

    expect(editor.getData()).toBe('Initial German content');
    editor.setData('New German content');

    switchLanguage(select, 'en');

    expect(editor.getData()).toBe('New English content');

    switchLanguage(select, 'de');

    expect(editor.getData()).toBe('New German content');
  });
});
