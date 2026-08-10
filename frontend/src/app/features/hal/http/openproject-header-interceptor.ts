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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  HttpEvent, HttpHandler, HttpInterceptor, HttpRequest,
} from '@angular/common/http';
import { Observable } from 'rxjs';
import { Injectable } from '@angular/core';
import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';

export const EXTERNAL_REQUEST_HEADER = 'X-External-Request';

@Injectable()
export class OpenProjectHeaderInterceptor implements HttpInterceptor {
  intercept(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    const withCredentials = req.headers.get(EXTERNAL_REQUEST_HEADER) !== 'true';

    if (withCredentials) {
      return this.handleAuthenticatedRequest(req, next);
    } else {
      return this.handleExternalRequest(req, next);
    }
  }

  private handleExternalRequest(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    // Clone the request to add the new header
    const clonedRequest = req.clone({
      withCredentials: false,
      headers: req.headers.delete(EXTERNAL_REQUEST_HEADER),
    });

    return next.handle(clonedRequest);
  }

  private handleAuthenticatedRequest(req:HttpRequest<any>, next:HttpHandler):Observable<HttpEvent<any>> {
    const csrfToken = getMetaContent('csrf-token');

    let newHeaders = req.headers.set('X-Requested-With', 'XMLHttpRequest');

    if (csrfToken) {
      newHeaders = newHeaders.set('X-CSRF-TOKEN', csrfToken);
    }

    // Clone the request to add the new header
    const clonedRequest = req.clone({
      withCredentials: true,
      headers: newHeaders,
    });

    // Pass the cloned request instead of the original request to the next handle
    return next.handle(clonedRequest);
  }
}
