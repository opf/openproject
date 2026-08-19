/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { ensureId } from 'core-app/shared/helpers/dom-helpers';
import { retrieveCkEditorInstance } from 'core-app/shared/helpers/ckeditor-helpers';
import invariant from 'tiny-invariant';

/**
 * Stimulus Controller for Settings::TextSettingComponent
 */
export default class MultiLangTextSetting extends Controller<HTMLElement> {
  static targets = ['select', 'langFor', 'textArea'];

  declare readonly selectTarget:HTMLSelectElement;
  declare readonly langForTargets:HTMLInputElement[];
  declare readonly textAreaTarget:HTMLTextAreaElement;

  private abortController:AbortController|null = null;

  selectTargetConnected(target:HTMLSelectElement):void {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    target.addEventListener('focus', this.onSelectFocus.bind(this), { signal });
    target.addEventListener('change', this.onSelectChange.bind(this), { signal });
  }

  selectTargetDisconnected(_target:HTMLSelectElement):void {
    this.abortController?.abort();
    this.abortController = null;
  }

  // Upon focusing:
  //   * store the current value of the editor in the hidden field for that lang.
  private onSelectFocus(ev:Event) {
    const select = ev.currentTarget as HTMLSelectElement;
    const { newLang, editor } = this.getLangSelectData(select);
    const hiddenInput = this.langForTargets.find((el) => newLang === el.dataset.lang);
    if (!hiddenInput) return;

    hiddenInput.value = editor.getData();
  }

  // Upon change:
  //   * get the current value from the hidden field for that lang and set the editor text to that value.
  //   * Set the name of the textarea to reflect the current lang so that the value stored in the hidden field
  //     is overwritten.
  private onSelectChange(ev:Event) {
    const select = ev.currentTarget as HTMLSelectElement;
    const { settingName, newLang, textArea, editor } = this.getLangSelectData(select);
    const hiddenInput = this.langForTargets.find((el) => newLang === el.dataset.lang);
    if (!hiddenInput) return;

    editor.setData(hiddenInput.value);
    textArea.setAttribute('name', `settings[${settingName}][${newLang}]`);
  }

  private getLangSelectData(select:HTMLSelectElement) {
    const id = ensureId(select, 'lang-for');
    const settingName = id.replace('lang-for-', '');
    const newLang = select.value;
    const textArea = this.textAreaTarget;
    const textAreaId = ensureId(textArea);
    const ckEditor = this.element.querySelector<HTMLElement>(`opce-ckeditor-augmented-textarea[data-text-area-id='"${textAreaId}"'`);
    invariant(ckEditor, `Expected ckEditor for augmented textarea "${textAreaId}"`);
    const editor = retrieveCkEditorInstance(ckEditor);
    invariant(editor, `Expected ckEditorInstance for augmented textarea "${textAreaId}"`);

    return {
      settingName, newLang, textArea, editor,
    };
  }
}
