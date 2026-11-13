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
import { FormsModule } from '@angular/forms';
import { fireEvent } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { CodeMirrorLoaderService } from 'core-app/shared/components/editor/components/ckeditor/codemirror-loader.service';
import { CodeBlockMacroModalComponent } from './code-block-macro.modal';

describe('CodeBlockMacroModalComponent language loading', () => {
  it('initializes the editor asynchronously and saves its content', async () => {
    const close = vi.fn();
    const editor = { getValue: () => 'Updated code', setOption: vi.fn(), refresh: vi.fn() };
    const fromTextArea = vi.fn().mockReturnValue(editor);
    TestBed.configureTestingModule({
      declarations: [CodeBlockMacroModalComponent],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalLocalsToken, useValue: { content: 'Original code', languageClass: 'language-text', service: { close } } },
        { provide: CodeMirrorLoaderService, useValue: {
          loadCore: () => Promise.resolve({ fromTextArea }),
          ensureModeLoaded: () => Promise.resolve(true),
        } },
      ],
    });
    const fixture = TestBed.createComponent(CodeBlockMacroModalComponent);
    try {
      await fixture.whenStable();
      const element = fixture.nativeElement as HTMLElement;
      expect(element.querySelector('textarea')).toHaveValue('Original code');
      expect(fromTextArea).toHaveBeenCalledWith(element.querySelector('textarea'), expect.objectContaining({ value: 'Original code' }));
      const language = element.querySelector<HTMLInputElement>('#selected-language')!;
      fireEvent.input(language, { target: { value: 'ruby' } });
      await fixture.whenStable();
      fixture.componentInstance.debouncedLanguageLoader.flush();
      await vi.waitFor(() => expect(editor.setOption).toHaveBeenCalledWith('mode', 'ruby'));
      fireEvent.click(element.querySelector<HTMLButtonElement>('.spot-modal--submit-button')!);
      expect(fixture.componentInstance.content).toBe('Updated code');
      expect(fixture.componentInstance.languageClass).toBe('language-ruby');
      expect(close).toHaveBeenCalled();
    } finally {
      fixture.componentInstance.debouncedLanguageLoader.cancel();
    }
  });
});
