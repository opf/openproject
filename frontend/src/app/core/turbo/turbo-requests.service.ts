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

import { Injectable, inject } from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { TurboHelpers } from 'core-turbo/helpers';
import { renderErrorStream, request, type TurboRequestInit } from 'core-turbo/requests';
import { TurboRequestError } from 'core-turbo/turbo-request-error';

@Injectable({ providedIn: 'root' })
export class TurboRequestsService {
  private toast = inject(ToastService);

  #controllers = new Map<string, AbortController>();

  public request(
    url:string,
    init:TurboRequestInit = {},
    suppressErrorToast = false,
    requestId?:string,
  ):Promise<{
    html:string,
    headers:Headers
  }> {
    let controller:AbortController|undefined;
    if (requestId) {
      this.abortRequest(requestId);

      controller = new AbortController();
      this.#controllers.set(requestId, controller);
    }

    return request(url, controller ? { ...init, signal: controller.signal } : init)
      .then(async (response) => {
        const html = await response.responseText;
        await renderErrorStream(response, html);

        if (response.failed) {
          throw new TurboRequestError(response.statusCode, response.response.statusText);
        }

        // enable further processing of the html and headers in the calling function
        return { html, headers: response.response.headers };
      })
      .catch((error) => {
        if (requestId && error instanceof DOMException && error.name === 'AbortError') {
          debugLog(`Request "${requestId}" was aborted.`);

        // this should only catch errors happening in the client side parsing in the above .then() calls
        } else if (!suppressErrorToast) {
          this.toast.addError(error as string);
        } else {
          console.error(error);
        }

        throw error;
      })
      .finally(() => {
        // A replacement request under the same id may already own the slot.
        if (requestId && this.#controllers.get(requestId) === controller) {
          this.#controllers.delete(requestId);
        }
      });
  }

  public submitForm(
    form:HTMLFormElement,
    params:URLSearchParams|null = null,
    url = form.action,
    requestId?:string,
  ):Promise<{ html:string, headers:Headers }> {
    const formData = new FormData(form);
    const requestParams = params ? `?${params.toString()}` : '';
    const requestUrlWithParams = `${url}${requestParams}`;
    return this.request(
      requestUrlWithParams,
      {
        method: form.method,
        body: formData,
      },
      true,
      requestId || requestUrlWithParams,
    );
  }

  public requestStream(
    url:string,
    requestId = url,
  ):Promise<{ html:string, headers:Headers }> {
    TurboHelpers.showProgressBar();

    return this.request(
      url,
      {
        method: 'GET',
        responseKind: 'turbo-stream',
        credentials: 'same-origin',
      },
      false,
      requestId,
    )
    .finally(() => {
      TurboHelpers.hideProgressBar();
    });
  }

  public abortRequest(requestId:string):void {
    const controller = this.#controllers.get(requestId);
    if (controller) {
      controller.abort();
      this.#controllers.delete(requestId);
    }
  }

  public abortAll():void {
    this.#controllers.forEach((controller) => controller.abort());
    this.#controllers.clear();
  }
}
