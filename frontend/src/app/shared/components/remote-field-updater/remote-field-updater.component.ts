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

import { ChangeDetectionStrategy, Component, ElementRef, OnInit } from '@angular/core';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { HttpClient } from '@angular/common/http';

export const remoteFieldUpdaterSelector = 'remote-field-updater';

@Component({
  selector: remoteFieldUpdaterSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '',
})
export class RemoteFieldUpdaterComponent implements OnInit {
  constructor(
    private elementRef:ElementRef,
    private http:HttpClient,
  ) {
  }

  private url:string;

  private htmlMode:boolean;

  private form:HTMLFormElement;

  private target:HTMLElement;

  ngOnInit():void {
    const element = this.elementRef.nativeElement as HTMLElement;
    this.form = element.closest('form') as HTMLFormElement;
    this.target = this.form.querySelector('.remote-field--target') as HTMLElement;

    this.url = element.dataset.url as string;
    this.htmlMode = element.dataset.mode === 'html';

    const debouncedEvent = _.debounce((event:InputEvent) => {
      // This prevents an update of the result list when
      // tabbing to the result list (9),
      // pressing enter (13)
      // tabbing back with shift (16) and
      // special cases where the tab code is not correctly recognized (undefined).
      // Thus the focus is kept on the first element of the result list.
      const keyCodes = [KeyCodes.TAB, KeyCodes.ENTER, KeyCodes.SHIFT];
      if (event.type === 'change' || (event.which && keyCodes.indexOf(event.which) === -1)) {
        this.updater();
      }
    }, 500);

    this.form.addEventListener('keyup', debouncedEvent);
    this.form.addEventListener('change', debouncedEvent);
  }

  private request(params:Record<string, string>) {
    const headers:Record<string, string> = {};

    // In HTML mode, expect html response
    if (this.htmlMode) {
      headers.Accept = 'text/html';
    } else {
      headers.Accept = 'application/json';
    }

    return this.http
      .get(
        this.url,
        {
          params,
          headers,
          responseType: (this.htmlMode ? 'text' : 'json') as any,
          withCredentials: true,
        },
      );
  }

  private updater() {
    const params:Record<string, string> = {};

    // Gather request keys
    this
      .form
      .querySelectorAll('.remote-field--input')
      .forEach((el:HTMLInputElement) => {
        params[el.dataset.remoteFieldKey as string] = el.value;
      });

    this
      .request(params)
      .subscribe((response:any) => {
        if (this.htmlMode) {
          // Replace the given target
          this.target.innerHTML = response as string;
        } else {
          _.each(response, (val:string, selector:string) => {
            const element = document.getElementById(selector) as HTMLElement|HTMLInputElement;

            if (element instanceof HTMLInputElement) {
              element.value = val;
            } else if (element) {
              element.textContent = val;
            }
          });
        }
      });
  }
}
