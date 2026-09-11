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

import { FetchResponse, fetch as turboFetch, renderStreamMessage } from '@hotwired/turbo';
import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';
import { TurboHelpers } from 'core-turbo/helpers';
import type { TurboRequestScope } from 'core-turbo/request-scope';

export interface TurboRequestInit extends RequestInit {
  responseKind?:'turbo-stream';
  progress?:boolean;
  scope?:TurboRequestScope;
}

const CSRF_HEADER = 'X-CSRF-Token';
const CSRF_SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS', 'TRACE']);
const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html';

// The published typings declare no constructor for the exported class.
const NativeFetchResponse = FetchResponse as unknown as new (response:Response) => FetchResponse;

// Performs a Turbo fetch and renders a Turbo Stream response for successful
// and 422 responses. HTTP errors resolve; the caller decides what an error
// status means. Nothing here waits for Angular.
export function request(url:string|URL, init:TurboRequestInit = {}):Promise<FetchResponse> {
  const { responseKind, progress, scope, ...fetchInit } = init;
  const operation = () => perform(url, fetchInit, responseKind, progress);

  return scope ? scope.track(operation) : operation();
}

export function isTurboStream(response:FetchResponse):boolean {
  return response.header('Content-Type')?.startsWith(STREAM_CONTENT_TYPE) ?? false;
}

export function isUnprocessableEntity(response:FetchResponse):boolean {
  return response.statusCode === 422;
}

// Renders the stream of an error response `request` left unrendered, for
// callers that surface server-side error streams. Resolves to whether it
// rendered anything. Pass an already read body to avoid a second read.
export async function renderErrorStream(response:FetchResponse, body?:string):Promise<boolean> {
  if (!isTurboStream(response) || response.succeeded || isUnprocessableEntity(response)) {
    return false;
  }

  renderStreamMessage(body ?? await response.responseText);

  return true;
}

async function perform(
  url:string|URL,
  init:RequestInit,
  responseKind:TurboRequestInit['responseKind'],
  progress:boolean|undefined,
):Promise<FetchResponse> {
  if (progress) {
    TurboHelpers.showProgressBar();
  }

  try {
    const response = new NativeFetchResponse(await turboFetch(url, withRequestHeaders(url, init, responseKind)));

    if (isTurboStream(response) && (response.succeeded || isUnprocessableEntity(response))) {
      renderStreamMessage(await response.responseText);
    }

    return response;
  } finally {
    if (progress) {
      TurboHelpers.hideProgressBar();
    }
  }
}

function withRequestHeaders(
  url:string|URL,
  init:RequestInit,
  responseKind:TurboRequestInit['responseKind'],
):RequestInit {
  const method = (init.method ?? 'GET').toUpperCase();
  const headers = new Headers(init.headers);
  const token = getMetaContent('csrf-token', null);

  if (responseKind === 'turbo-stream') {
    headers.set('Accept', 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml');
  }

  if (token && !CSRF_SAFE_METHODS.has(method) && !headers.has(CSRF_HEADER) && isSameOrigin(url)) {
    headers.set(CSRF_HEADER, token);
  }

  return { ...init, method, headers };
}

function isSameOrigin(url:string|URL):boolean {
  return new URL(String(url), window.location.href).origin === window.location.origin;
}
