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
import { page } from 'vitest/browser';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { CodeBlockMacroModalComponent } from './code-block-macro.modal';

describe('CodeBlockMacroModalComponent', () => {
  let fixture:ComponentFixture<CodeBlockMacroModalComponent>;
  let modal:CodeBlockMacroModalComponent;
  let root:HTMLElement;
  let close:ReturnType<typeof vi.fn<OpModalService['close']>>;

  async function render(languageClass = 'language-text') {
    await page.viewport(1280, 800);
    close = vi.fn<OpModalService['close']>();
    TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule],
      declarations: [CodeBlockMacroModalComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalLocalsToken, useValue: { service: { close }, content: 'Original code', languageClass } },
      ],
    });
    fixture = TestBed.createComponent(CodeBlockMacroModalComponent);
    modal = fixture.componentInstance;
    root = fixture.nativeElement as HTMLElement;
    await fixture.whenStable();
    await waitFor(() => expect(modal.codeMirrorInstance).toBeDefined());
  }

  afterEach(() => modal?.debouncedLanguageLoader.cancel());

  it('renders initial content with the real code editor', async () => {
    await render();
    expect(root.querySelector('.CodeMirror')).toBeInTheDocument();
    expect(modal.codeMirrorInstance?.getValue()).toBe('Original code');
    expect(within(root).getByRole('textbox', { name: 'js.editor.macro.code_block.language' })).toHaveValue('text');
  });

  it('saves edited code and the selected language', async () => {
    await render();
    modal.codeMirrorInstance!.setValue('Updated code');
    fireEvent.input(within(root).getByRole('textbox', { name: 'js.editor.macro.code_block.language' }), { target: { value: 'ruby' } });
    await fixture.whenStable();
    fireEvent.click(within(root).getByRole('button', { name: 'js.button_save' }));
    await fixture.whenStable();
    expect(modal.content).toBe('Updated code');
    expect(modal.languageClass).toBe('language-ruby');
    expect(modal.changed).toBe(true);
    expect(close).toHaveBeenCalledOnce();
  });

  it('defaults an empty language to plain text when saving', async () => {
    await render('invalid');
    const language = within(root).getByRole('textbox', { name: 'js.editor.macro.code_block.language' });
    expect(language).toHaveValue('text');
    fireEvent.input(language, { target: { value: '' } });
    await fixture.whenStable();
    fireEvent.submit(root.querySelector('form')!);
    await fixture.whenStable();
    expect(modal.languageClass).toBe('language-text');
    expect(close).toHaveBeenCalledOnce();
  });

  it('cancels without applying changes from the editor', async () => {
    await render();
    modal.codeMirrorInstance!.setValue('Discarded code');
    fireEvent.click(within(root).getByRole('button', { name: 'js.button_cancel' }));
    await fixture.whenStable();
    expect(modal.changed).toBe(false);
    expect(modal.content).toBe('Original code');
    expect(close).toHaveBeenCalledOnce();
  });
});
