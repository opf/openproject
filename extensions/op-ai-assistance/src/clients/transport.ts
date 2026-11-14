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

import browser from 'webextension-polyfill';
import { sameOrigin } from '../shared/hosts';

export interface TransportRequest {
  method:'GET' | 'POST' | 'PATCH';
  path:string;
  body?:string;
}

export interface TransportResponse {
  status:number;
  body:string;
}

export type Transport = (request:TransportRequest) => Promise<TransportResponse>;

export const PROXY_PORT_PREFIX = 'op-ai-proxy:';
const ALLOWED_PATH = /^\/(?:api\/v3\/|mcp$)/;

// Only API v3 and MCP, after the URL parser has resolved "..": a path such as
// /api/v3/../../admin does not pass.
export function isAllowedPath(path:string):boolean {
  if (!path.startsWith('/') || path.startsWith('//')) return false;
  try {
    const url = new URL(path, 'http://op.invalid');
    return url.host === 'op.invalid' && ALLOWED_PATH.test(url.pathname) && url.pathname === path.split('?')[0];
  } catch {
    return false;
  }
}

const JSON_HEADERS = { accept: 'application/json', 'content-type': 'application/json' };

export function normalizeBasePath(basePath:string):string {
  return basePath.replace(/\/+$/, '');
}

// The clients use paths below the application root (/api/v3/…, /mcp). Hrefs from API v3
// carry the base path of an instance under a sub-path (/openproject/api/v3/…), so it is
// removed before the path check.
export function appPath(path:string, basePath:string):string {
  const base = normalizeBasePath(basePath);
  return base && path.startsWith(`${base}/`) ? path.slice(base.length) : path;
}

// Token mode: the extension page calls the instance itself with the user's API token.
// instanceUrl holds the base path of the instance, if any.
export function tokenTransport(instanceUrl:string, token:string):Transport {
  const url = new URL(instanceUrl);
  const basePath = normalizeBasePath(url.pathname);
  return async ({ method, path, body }) => {
    const relative = appPath(path, basePath);
    if (!isAllowedPath(relative)) throw new Error(`Path not allowed: ${path}`);
    const response = await fetch(`${url.origin}${basePath}${relative}`, {
      method,
      body,
      credentials: 'omit',
      headers: { ...JSON_HEADERS, authorization: `Bearer ${token}` },
    });
    return { status: response.status, body: await response.text() };
  };
}

export type Control = 'close' | 'reload' | 'settings';

interface ProxyMessage {
  id:number;
  request?:TransportRequest;
  response?:TransportResponse;
  error?:string;
  control?:Control;
}

// Session mode, page side. OpenProject accepts a session cookie for writes only from a
// same-origin request (Sec-Fetch-Site), so the content script, which runs on the instance's
// origin, sends the requests for the extension page. The same port carries the frame's
// requests to close the dialog or reload the page.
export function serveProxy(channel:string, basePath:string, onControl:(control:Control) => void):browser.Runtime.Port {
  const port = browser.runtime.connect({ name: `${PROXY_PORT_PREFIX}${channel}` });
  const pageFetch = (globalThis as { content?:{ fetch?:typeof fetch } }).content?.fetch ?? fetch;

  port.onMessage.addListener((message:unknown) => {
    const { id, request, control } = message as ProxyMessage;
    if (control) {
      onControl(control);
      return;
    }
    if (!request) return;
    const relative = appPath(request.path, basePath);
    if (!isAllowedPath(relative)) {
      port.postMessage({ id, error: `Path not allowed: ${request.path}` });
      return;
    }
    pageFetch(`${window.location.origin}${normalizeBasePath(basePath)}${relative}`, {
      method: request.method,
      body: request.body,
      credentials: 'same-origin',
      headers: { ...JSON_HEADERS, 'x-requested-with': 'XMLHttpRequest' },
    })
      .then(async (response) => port.postMessage({ id, response: { status: response.status, body: await response.text() } }))
      .catch((error:unknown) => port.postMessage({ id, error: error instanceof Error ? error.message : String(error) }));
  });
  return port;
}

export interface PageLink {
  transport:Transport;
  control(control:Control):void;
}

// Extension page side: waits for the content script of the page that holds this frame to
// connect on the frame's channel. Only this extension's content script, running on the
// expected origin, is accepted.
export function connectToPage(channel:string, origin:string, timeoutMs = 10_000):Promise<PageLink> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      browser.runtime.onConnect.removeListener(onConnect);
      reject(new Error('The OpenProject page did not connect. Reload the page.'));
    }, timeoutMs);

    function onConnect(port:browser.Runtime.Port):void {
      if (port.name !== `${PROXY_PORT_PREFIX}${channel}`) return;
      if (port.sender?.id !== browser.runtime.id || !sameOrigin(port.sender.url, origin)) {
        port.disconnect();
        return;
      }
      clearTimeout(timer);
      browser.runtime.onConnect.removeListener(onConnect);

      let nextId = 1;
      const pending = new Map<number, { resolve:(response:TransportResponse) => void; reject:(error:Error) => void }>();
      port.onMessage.addListener((message:unknown) => {
        const { id, response, error } = message as ProxyMessage;
        const waiter = pending.get(id);
        if (!waiter) return;
        pending.delete(id);
        if (response) waiter.resolve(response);
        else waiter.reject(new Error(error ?? 'The request failed.'));
      });
      port.onDisconnect.addListener(() => {
        pending.forEach((waiter) => waiter.reject(new Error('The OpenProject page was closed.')));
        pending.clear();
      });

      resolve({
        transport: (request) => new Promise((resolveRequest, rejectRequest) => {
          const id = nextId;
          nextId += 1;
          pending.set(id, { resolve: resolveRequest, reject: rejectRequest });
          port.postMessage({ id, request });
        }),
        control: (control) => port.postMessage({ id: 0, control }),
      });
    }

    browser.runtime.onConnect.addListener(onConnect);
  });
}
