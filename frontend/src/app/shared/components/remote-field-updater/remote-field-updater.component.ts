//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Component, ElementRef, OnInit } from '@angular/core';
import { keyCodes } from 'core-app/modules/common/keyCodes.enum';
import { HttpClient } from '@angular/common/http';

export const remoteFieldUpdaterSelector = 'remote-field-updater';

@Component({
  selector: remoteFieldUpdaterSelector,
  template: ''
})
export class RemoteFieldUpdaterComponent implements OnInit {

  constructor(private elementRef:ElementRef,
              private http:HttpClient) {
  }

  private url:string;
  private htmlMode:boolean;

  private inputs:JQuery;
  private target:JQuery;

  ngOnInit():void {
    const $element = jQuery(this.elementRef.nativeElement);
    const $form = $element.parent();
    this.inputs = $form.find('.remote-field--input');
    this.target = $form.find('.remote-field--target');

    this.url = $element.data('url');
    this.htmlMode = $element.data('mode') === 'html';

    this.inputs.on('keyup change', _.debounce((event:JQuery.TriggeredEvent) => {
      // This prevents an update of the result list when
      // tabbing to the result list (9),
      // pressing enter (13)
      // tabbing back with shift (16) and
      // special cases where the tab code is not correctly recognized (undefined).
      // Thus the focus is kept on the first element of the result list.
      const keyCodesArray = [keyCodes.TAB, keyCodes.ENTER, keyCodes.SHIFT];
      if (event.type === 'change' || (event.which && keyCodesArray.indexOf(event.which) === -1)) {
        this.updater();
      }
    }, 500));
  }

  private request(params:any) {
    const headers:any = {};

    // In HTML mode, expect html response
    if (this.htmlMode) {
      headers['Accept'] = 'text/html';
    } else {
      headers['Accept'] = 'application/json';
    }

    return this.http
      .get(
        this.url,
        {
          params: params,
          headers: headers,
          responseType: (this.htmlMode ? 'text' : 'json') as any,
          withCredentials: true
        }
      );
  }

  private updater() {
    const params:any = {};

    // Gather request keys
    this.inputs.each((i, el:HTMLInputElement) => {
      params[el.dataset.remoteFieldKey!] = el.value;
    });

    this
      .request(params)
      .subscribe((response:any) => {
        if (this.htmlMode) {
        // Replace the given target
          this.target.html(response);
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

