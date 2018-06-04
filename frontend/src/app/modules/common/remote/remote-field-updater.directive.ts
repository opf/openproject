// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {keyCodes} from 'core-app/modules/common/keyCodes.enum';
import {Directive, ElementRef, Input, OnDestroy, OnInit} from "@angular/core";
import {HttpClient} from "@angular/common/http";

@Directive({
  selector: 'remote-field-updater'
})
export class RemoteFieldUpdaterDirective implements OnInit, OnDestroy {
  @Input() public url:string;
  @Input() public method:string;

  private inputs:JQuery;
  private target:JQuery;

  constructor(readonly elementRef:ElementRef,
              readonly http:HttpClient) {
  }

  ngOnInit() {
    const element = jQuery(this.elementRef.nativeElement);
    this.inputs = element.find('.remote-field--input');
    this.target = element.find('.remote-field--target');

    this.inputs.on('keyup.remoteFieldUpdater change.remoteFieldUpdater', _.debounce((event:any) => {
        // This prevents an update of the result list when
        // tabbing to the result list (9),
        // pressing enter (13)
        // tabbing back with shift (16) and
        // special cases where the tab code is not correctly recognized (undefined).
        // Thus the focus is kept on the first element of the result list.
        let keyCodesArray = [keyCodes.TAB, keyCodes.ENTER, keyCodes.SHIFT];
        if (keyCodesArray.indexOf(event.keyCode) === -1 && event.keyCode !== undefined) {
          this.updater();
        }
      }, 200)
    );
  }

  ngOnDestroy() {
    this.inputs.off('.remoteFieldUpdater');
  }

  private updater() {
    let params:any = {};

    // Gather request keys
    this.inputs.each((i, el) => {
      const field = jQuery(el);
      params[field.data('remoteFieldKey')] = field.val();
    });

    this
      .request(params)
      .subscribe((response:any) => {
        this.target.html(response.data);
      });
  }

  private request(params:any) {
    const method = (this.method || 'GET').toUpperCase();

    const request = {
      headers: { Accept: 'text/html' },
      params: {},
      body: {},
      responseType: 'text'
    };

    // Append request to either URL params or body
    // Angular doesn't differentiate between those two on its own.
    if (method === 'GET') {
      request['params'] = params;
    } else {
      request['body'] = params;
    }

    return this.http.request(this.url, method, params);
  }
}
