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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { EditorView, basicSetup } from 'codemirror';
import { markdown } from '@codemirror/lang-markdown';
import { LanguageDescription, LanguageSupport } from '@codemirror/language';
import { languages } from '@codemirror/language-data';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { CodeBlockMacroModalComponent } from './code-block-macro.modal';

describe('CodeBlockMacroModalComponent (CodeMirror 6 integration)', () => {
  let fixture:ComponentFixture<CodeBlockMacroModalComponent>;
  let component:CodeBlockMacroModalComponent;

  const i18nStub = { t: (key:string) => key };
  let closed = false;
  const serviceStub:Pick<OpModalService, 'close'> = { close: () => { closed = true; } };

  beforeEach(async () => {
    closed = false;

    await TestBed.configureTestingModule({
      imports: [FormsModule],
      declarations: [CodeBlockMacroModalComponent],
      providers: [
        { provide: I18nService, useValue: i18nStub },
        {
          provide: OpModalLocalsToken,
          useValue: { service: serviceStub, languageClass: 'language-ruby', content: 'puts "hi"' },
        },
      ],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(CodeBlockMacroModalComponent);
    component = fixture.componentInstance;
  });

  afterEach(() => fixture.destroy());

  it('parses the language from the language class', () => {
    expect(component.language).toEqual('ruby');
  });

  it('mounts an EditorView seeded with the initial content', () => {
    fixture.detectChanges();

    expect(component.sourceEditorView).not.toBeNull();
    expect(component.sourceEditorView!.state.doc.toString()).toEqual('puts "hi"');
    expect(fixture.nativeElement.querySelector('.cm-content')).toBeTruthy();
  });

  it('reads the edited document back and closes on apply', () => {
    fixture.detectChanges();

    const view = component.sourceEditorView!;
    view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: 'edited code' } });

    component.applyAndClose(new Event('submit'));

    expect(component.content).toEqual('edited code');
    expect(component.languageClass).toEqual('language-ruby');
    expect(component.changed).toBe(true);
    expect(closed).toBe(true);
  });

  it('destroys the EditorView when the modal is torn down', () => {
    fixture.detectChanges();
    fixture.destroy();

    expect(component.sourceEditorView).toBeNull();
  });
});

describe('CodeMirror 6 language loading', () => {
  it('resolves a legacy-mode language (ruby) via @codemirror/language-data', async () => {
    const description = LanguageDescription.matchLanguageName(languages, 'ruby', true);

    expect(description).toBeTruthy();

    const support = await description!.load();
    expect(support).toBeInstanceOf(LanguageSupport);
  });

  it('mounts a markdown EditorView matching the CKEditor source view setup', () => {
    const host = document.createElement('div');
    const view = new EditorView({
      parent: host,
      doc: '# Title',
      extensions: [basicSetup, markdown()],
    });

    expect(view.state.doc.toString()).toEqual('# Title');
    expect(host.querySelector('.cm-content')).toBeTruthy();

    view.destroy();
  });
});
