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

import { debounce } from 'lodash-es';
import {
  AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, OnDestroy, ViewChild, inject,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EditorView, basicSetup } from 'codemirror';
import { Compartment, type Extension } from '@codemirror/state';
import { LanguageDescription } from '@codemirror/language';
import { languages } from '@codemirror/language-data';

@Component({
  templateUrl: './code-block-macro.modal.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class CodeBlockMacroModalComponent extends OpModalComponent implements AfterViewInit, OnDestroy {
  public changed = false;

  public showClose = true;

  // Language class from markdown, something like 'language-ruby'
  public languageClass:string;

  // Language string, e.g, 'ruby'
  public _language = '';

  public content:string;

  // CodeMirror EditorView instance
  public sourceEditorView:EditorView|null = null;

  // Compartment used to swap the active language without recreating the editor
  private readonly languageCompartment = new Compartment();

  // Latest token requested by the debounced loader, used to ignore stale async loads
  private languageLoadToken = 0;

  public debouncedLanguageLoader = debounce(() => this.loadLanguageAsMode(this.language), 300);

  @ViewChild('codeMirrorPane', { static: true }) codeMirrorPane:ElementRef<HTMLDivElement>;

  readonly I18n = inject(I18nService);

  public text:any = {
    title: this.I18n.t('js.editor.macro.code_block.title'),
    language: this.I18n.t('js.editor.macro.code_block.language'),
    language_hint: this.I18n.t('js.editor.macro.code_block.language_hint'),
    button_save: this.I18n.t('js.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  constructor() {
    super();
    this.languageClass = (this.locals.languageClass as string | undefined) ?? 'language-text';
    this.content = this.locals.content as string;

    const match = /language-(\w+)/.exec(this.languageClass);
    if (match) {
      this.language = match[1];
    } else {
      this.language = 'text';
    }
  }

  public applyAndClose(evt:Event):void {
    this.content = this.sourceEditorView?.state.doc.toString() ?? this.content;
    const lang = this.language || 'text';
    this.languageClass = `language-${lang}`;

    this.changed = true;
    this.closeMe(evt);
  }

  ngAfterViewInit():void {
    this.sourceEditorView = new EditorView({
      parent: this.codeMirrorPane.nativeElement,
      doc: this.content,
      extensions: [
        basicSetup,
        this.languageCompartment.of([]),
      ],
    });

    this.sourceEditorView.focus();

    // Load the language detected from the initial content, if any
    this.loadLanguageAsMode(this.language);
  }

  ngOnDestroy():void {
    this.debouncedLanguageLoader.cancel();
    this.sourceEditorView?.destroy();
    this.sourceEditorView = null;
  }

  get language() {
    return this._language;
  }

  set language(val:string) {
    this._language = val;
    this.debouncedLanguageLoader();
  }

  loadLanguageAsMode(language:string) {
    this.languageLoadToken += 1;
    const token = this.languageLoadToken;

    // For the special language 'text', don't try to load anything
    if (!language || language === 'text') {
      this.reconfigureLanguage([]);
      return;
    }

    const description = LanguageDescription.matchLanguageName(languages, language, true);
    if (!description) {
      this.reconfigureLanguage([]);
      return;
    }

    void description
      .load()
      .then((support) => {
        // Ignore the result if a newer language was requested in the meantime
        if (token === this.languageLoadToken) {
          this.reconfigureLanguage(support);
        }
      })
      .catch((e:unknown) => {
        console.error(`Failed to load language ${language}:`, e);
        if (token === this.languageLoadToken) {
          this.reconfigureLanguage([]);
        }
      });
  }

  private reconfigureLanguage(extension:Extension) {
    this.sourceEditorView?.dispatch({
      effects: this.languageCompartment.reconfigure(extension),
    });
  }

  updateLanguage(newValue?:string) {
    if (!newValue) {
      this.language = '';
      return;
    }

    if (/^\w+$/.exec(newValue)) {
      this.language = newValue;
    } else {
      console.error(`Not updating non-matching language: ${newValue}`);
    }
  }
}
