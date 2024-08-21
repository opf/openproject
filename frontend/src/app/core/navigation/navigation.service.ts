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

/// <reference types="dom-navigation" />

import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class NavigationService {
  private _currentURL = document.location.href;

  private _urlChanged$:Subject<string> = new Subject();

  public urlChanged$ = this._urlChanged$.asObservable();

  constructor() {
    if ('navigation' in window) {
      window.navigation.addEventListener('navigate', (event:NavigateEvent) => {
        this.handleURLChange(event.destination.url);
      });
    } else {
      // Browser does not support navigation API, use a slower setInterval
      setInterval(() => this.handleURLChange(document.location.href), 250);
    }
  }

  private handleURLChange(url:string):void {
    if (url !== this._currentURL) {
      this._urlChanged$.next(url);
      this._currentURL = url;
    }
  }
}
