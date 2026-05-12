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
import { from, Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

import { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';

export interface MatchPreviewDialogSubmittedEvent {
  detail:{
    regularExpressions:string;
    previewGroups:string;
  }
}

export default class MatchPreviewDialogController extends Controller {
  static targets = [
    'regexpInput',
    'groupNamesInput',
  ];

  static values = {
    updateUrl: String,
  };

  declare readonly regexpInputTarget:HTMLInputElement;
  declare readonly groupNamesInputTarget:HTMLInputElement;

  declare dialog:HTMLDialogElement;
  declare updateUrlValue:string;
  declare updateMatchTimeout:ReturnType<typeof setTimeout>;

  private pluginContextData:OpenProjectPluginContext|null = null;

  connect() {
    this.dialog = this.element as HTMLDialogElement;
    this.regexpInputTarget.addEventListener('input', () => { this.updateMatchPreview(); });
    this.groupNamesInputTarget.addEventListener('input', () => { this.updateMatchPreview(); });
  }

  updateRegexpValue(value:string) {
    this.regexpInputTarget.value = value;
    this.updateMatchPreview();
  }

  submitDialog() {
    const event:MatchPreviewDialogSubmittedEvent = {
      detail: {
        regularExpressions: this.regexpInputTarget.value,
        previewGroups: this.groupNamesInputTarget.value,
      },
    };
    this.dispatch('submitted', event);
    this.dialog.close();
  }

  private updateMatchPreview() {
    if(this.updateMatchTimeout) clearTimeout(this.updateMatchTimeout);

    this.updateMatchTimeout = setTimeout(() => { this.doUpdateMatchPreview(); }, 500);
  }

  private doUpdateMatchPreview() {
    this.pluginContext.subscribe((context) => {
      void context.services.turboRequests.request(this.updateUrlValue, {
        method: 'POST',
        headers: {
          Accept: 'text/vnd.turbo-stream.html',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          preview_group_names: this.groupNamesInputTarget.value,
          preview_regular_expressions: this.regexpInputTarget.value,
        }),
      });
    });
  }

  private get pluginContext():Observable<OpenProjectPluginContext> {
    if (this.pluginContextData === null) {
      return from(window.OpenProject.getPluginContext()).pipe(
        tap((context) => {
          this.pluginContextData = context;
        }),
      );
    }

    return of(this.pluginContextData);
  }
}
