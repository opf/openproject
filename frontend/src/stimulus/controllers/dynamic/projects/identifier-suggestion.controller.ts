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

import {ApplicationController, useDebounce} from 'stimulus-use';

const ALLOWED_CHARS:Record<string, RegExp> = {
  semantic: /[^A-Z0-9_]/g,
  classic: /[^a-z0-9\-_]/g,
};

export default class extends ApplicationController {
  static debounces = ['fetchSuggestion'];
  static targets = ['name', 'identifier'];

  static values = {
    url: String,
    debounce: {type: Number, default: 300},
    mode: {type: String, default: 'classic'},
    setNameFirst: {type: String, default: ''},
  };

  declare urlValue:string;
  declare debounceValue:number;
  declare modeValue:string;
  declare setNameFirstValue:string;

  declare readonly nameTarget:HTMLInputElement;
  declare readonly identifierTarget:HTMLInputElement;
  declare readonly hasNameTarget:boolean;
  declare readonly hasIdentifierTarget:boolean;

  private abortController:AbortController | null = null;

  connect():void {
    if (!this.hasNameTarget || !this.hasIdentifierTarget) return;

    this.abortController = new AbortController();
    const { signal } = this.abortController;

    this.identifierTarget.addEventListener('input', () => this.filterInput(), { signal });

    if (this.urlValue) {
      if (!this.identifierTarget.value) {
        this.identifierTarget.placeholder = this.setNameFirstValue;
        this.identifierTarget.readOnly = true;
      }

      useDebounce(this, { wait: this.debounceValue });

      this.nameTarget.addEventListener('blur', () => {
        void this.fetchSuggestion();
      }, { signal });
    }
  }

  disconnect():void {
    this.abortController?.abort();
    this.abortController = null;
  }

  private filterInput():void {
    if (!this.hasIdentifierTarget) return;

    const pattern = ALLOWED_CHARS[this.modeValue] ?? ALLOWED_CHARS.classic;
    const current = this.identifierTarget.value;
    const filtered = current.replace(pattern, '');

    if (filtered !== current) {
      const pos = this.identifierTarget.selectionStart ?? filtered.length;
      this.identifierTarget.value = filtered;
      const newPos = Math.min(pos, filtered.length);
      this.identifierTarget.setSelectionRange(newPos, newPos);
    }
  }

  private async fetchSuggestion():Promise<void> {
    if (!this.urlValue || !this.hasIdentifierTarget || !this.hasNameTarget) return;

    const name = this.nameTarget.value.trim();
    if (!name) return;

    this.identifierTarget.readOnly = true;
    this.identifierTarget.placeholder = I18n.t('js.projects.identifier_suggestion.loading');

    try {
      const url = `${this.urlValue}?name=${encodeURIComponent(name)}`;
      const response = await fetch(url, {headers: {Accept: 'application/json'}});

      if (!response.ok) return;

      const data = await response.json() as { identifier:string };
      this.identifierTarget.value = data.identifier;
    } finally {
      this.identifierTarget.readOnly = false;
      this.identifierTarget.placeholder = '';
    }
  }
}
