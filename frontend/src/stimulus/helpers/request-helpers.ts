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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import type { FrameElement } from '@hotwired/turbo';
import { FetchRequest, FetchResponse, Options } from '@rails/request.js';
import { hideElement, showElement } from 'core-app/shared/helpers/dom-helpers';
import { TurboHelpers } from 'core-turbo/helpers';
import invariant from 'tiny-invariant';

export function post(url:string|URL, options?:Options) {
  const request = new FetchRequest('post', url, options);
  return withLoadingIndicator(request.perform());
}

export async function performTurboStreamRequest(request:FetchRequest):Promise<FetchResponse> {
  const response = await request.perform();

  if (!response.isTurboStream) {
    throw new FetchRequestError(response.statusCode, 'Response is not a Turbo Stream');
  }

  if (!response.ok && !response.unprocessableEntity) {
    await response.renderTurboStream();
  }

  return response;
}

function loadingIndicator() {
  const indicator = document.querySelector<HTMLElement>('#global-loading-indicator');
  invariant(indicator, 'Expected an Element with id global-loading-indicator to be present');
  return indicator;
}

export function showLoadingIndicator() {
  showElement(loadingIndicator());
}

export function hideLoadingIndicator() {
  hideElement(loadingIndicator());
}

export function withLoadingIndicator<T>(request:Promise<T>, shouldHide:() => boolean = () => true) {
  showLoadingIndicator();

  return request.finally(() => {
    if (shouldHide()) hideLoadingIndicator();
  });
}

export function withProgressBar(request:Promise<FetchResponse>) {
  TurboHelpers.showProgressBar();

  return request.finally(() => {
    TurboHelpers.hideProgressBar();
  });
}

// frame.loaded never settles when a reload cancels the request or the response lacks the frame.
// A cancelled request dispatches neither event, but the request replacing it does.
export function frameResponded(frame:FrameElement):Promise<void> {
  return new Promise((resolve) => {
    const listeners = new AbortController();
    const settle = (event:Event) => {
      if (event.target !== frame) return;

      listeners.abort();
      resolve();
    };
    frame.addEventListener('turbo:frame-load', settle, { signal: listeners.signal });
    frame.addEventListener('turbo:frame-missing', settle, { signal: listeners.signal });
    frame.addEventListener('turbo:fetch-request-error', settle, { signal: listeners.signal });
  });
}

export class FetchRequestError extends Error {
  constructor(public _errorCode:number, message = 'HTTP Error', options:ErrorOptions = {}) {
    super(message, options);
    this.name = 'FetchRequestError';
  }
}

export class ValidationError extends FetchRequestError {
  constructor(message:string, options:ErrorOptions = {}) {
    super(422, message, options);
    this.name = 'ValidationError';
  }
}
