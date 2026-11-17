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
import { type Control, serveProxy } from '../clients/transport';
import { workPackageIdFrom } from './pageInfo';

const MARK = 'data-op-ai-assistance';
const SETTINGS_HASH = '#ai-assistance';
const SVG_NS = 'http://www.w3.org/2000/svg';
const DIALOG_STYLE = `
  .backdrop { position: fixed; inset: 0; background: rgb(0 0 0 / 20%); z-index: 2147483000; }
  .panel { position: fixed; top: 0; right: 0; bottom: 0; width: min(520px, 100vw); z-index: 2147483001;
           box-shadow: -8px 0 24px rgb(0 0 0 / 20%); background: Canvas; }
  iframe { border: 0; width: 100%; height: 100%; display: block; }`;

function sparkle():SVGSVGElement {
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', '0 0 16 16');
  svg.setAttribute('width', '16');
  svg.setAttribute('height', '16');
  svg.setAttribute('fill', 'currentColor');
  svg.setAttribute('aria-hidden', 'true');
  const path = document.createElementNS(SVG_NS, 'path');
  path.setAttribute('d', 'M8 0c.4 3.8 2.2 5.6 6 6-3.8.4-5.6 2.2-6 6-.4-3.8-2.2-5.6-6-6 3.8-.4 5.6-2.2 6-6z');
  svg.append(path);
  return svg;
}

function element<K extends keyof HTMLElementTagNameMap>(tag:K, className = '', text = ''):HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text) node.textContent = text;
  return node;
}

// An instance under a sub-path (/openproject) renders it here; the root renders "".
const BASE_PATH = (document.querySelector<HTMLMetaElement>('meta[name="app_base_path"]')?.content ?? '').replace(/\/+$/, '');
const MY_ACCOUNT = `${BASE_PATH}/my/account`;

declare global {
  interface Window {
    opAiAssistanceLoaded?:boolean;
  }
}

function frameUrl(page:'chat.html' | 'settings.html', params:Record<string, string>):{ url:string; channel:string } {
  const channel = crypto.randomUUID();
  const hash = new URLSearchParams({
    ...params,
    channel,
    origin: window.location.origin,
    base: BASE_PATH,
    lang: document.documentElement.lang || navigator.language || 'en',
  });
  return { url: `${browser.runtime.getURL(page)}#${hash.toString()}`, channel };
}

function connectFrame(frame:HTMLIFrameElement, channel:string, onControl:(control:Control) => void):void {
  let port:browser.Runtime.Port | null = null;
  frame.addEventListener('load', () => {
    port?.disconnect();
    port = serveProxy(channel, BASE_PATH, onControl);
  });
}

function handleControl(control:Control, close:() => void):void {
  if (control === 'close') close();
  if (control === 'reload') window.location.reload();
  if (control === 'settings') window.location.assign(`${MY_ACCOUNT}${SETTINGS_HASH}`);
}

function openDialog(workPackageId:string):void {
  document.querySelector(`[${MARK}="dialog"]`)?.remove();

  const host = document.createElement('div');
  host.setAttribute(MARK, 'dialog');
  const shadow = host.attachShadow({ mode: 'closed' });
  const { url, channel } = frameUrl('chat.html', { wp: workPackageId });
  const backdrop = element('div', 'backdrop');
  const panel = element('div', 'panel');
  panel.setAttribute('role', 'dialog');
  panel.setAttribute('aria-label', 'AI Assistance');
  const frame = element('iframe');
  frame.title = 'AI Assistance';
  frame.src = url;
  panel.append(frame);
  shadow.append(element('style', '', DIALOG_STYLE), backdrop, panel);

  const close = ():void => {
    host.remove();
    document.removeEventListener('keydown', onKey);
  };
  const onKey = (event:KeyboardEvent):void => {
    if (event.key === 'Escape') close();
  };
  backdrop.addEventListener('click', close);
  document.addEventListener('keydown', onKey);
  connectFrame(frame, channel, (control) => handleControl(control, close));
  document.body.append(host);
}

function button(workPackageId:string, compact:boolean):HTMLButtonElement {
  const node = element('button', compact ? 'button' : 'button -primary-light');
  node.type = 'button';
  node.setAttribute(MARK, 'button');
  node.dataset.workPackageId = workPackageId;
  node.title = 'AI Assistance';
  node.setAttribute('aria-label', 'AI Assistance');
  node.append(sparkle());
  if (!compact) {
    const label = element('span', 'button--text', 'AI Assistance');
    label.style.marginLeft = '4px';
    node.append(label);
  }
  node.addEventListener('click', () => openDialog(node.dataset.workPackageId ?? workPackageId));
  return node;
}

function syncButton(container:Element | null, insert:(element:HTMLElement) => void, compact:boolean):void {
  const workPackageId = workPackageIdFrom(window.location.pathname, compact ? 'split' : 'full');
  if (!container || !workPackageId) return;

  const existing = container.querySelector<HTMLButtonElement>(`[${MARK}="button"]`);
  if (existing) {
    existing.dataset.workPackageId = workPackageId;
    return;
  }
  insert(button(workPackageId, compact));
}

function syncWorkPackageButtons():void {
  const fullViewMore = document.querySelector('#action-show-more-dropdown-menu');
  syncButton(fullViewMore?.parentElement ?? null, (element) => {
    const item = document.createElement('li');
    item.className = 'toolbar-item';
    item.append(element);
    fullViewMore?.before(item);
  }, false);

  const splitToolbar = document.querySelector('.work-packages--details-toolbar');
  syncButton(splitToolbar, (element) => {
    const more = splitToolbar?.querySelector('[data-test-selector="wp-details-toolbar--show-more-button"]');
    if (more) more.before(element);
    else splitToolbar?.append(element);
  }, true);
}

function syncMyAccount():void {
  if (!window.location.pathname.startsWith(`${BASE_PATH}/my/`)) return;
  const menu = document.querySelector('#menu-sidebar ul.menu_root');
  const showSettings = window.location.pathname === MY_ACCOUNT && window.location.hash === SETTINGS_HASH;

  if (menu && !menu.querySelector(`[${MARK}="menu"]`)) {
    const item = element('li');
    item.setAttribute(MARK, 'menu');
    const anchor = element('a', 'op-menu--item-action');
    anchor.href = `${MY_ACCOUNT}${SETTINGS_HASH}`;
    const icon = element('span', 'op-menu--item-icon');
    icon.style.display = 'inline-flex';
    icon.append(sparkle());
    anchor.append(icon, element('span', 'op-menu--item-title', 'AI Assistance'));
    item.append(anchor);
    anchor.addEventListener('click', (event) => {
      if (window.location.pathname !== MY_ACCOUNT) return;
      event.preventDefault();
      window.location.hash = SETTINGS_HASH;
    });
    menu.append(item);
  }

  const link = menu?.querySelector(`[${MARK}="menu"] a`);
  if (showSettings) {
    menu?.querySelectorAll('a.selected').forEach((selected) => selected !== link && selected.classList.remove('selected'));
    link?.classList.add('selected');
    showSettingsFrame();
  } else {
    link?.classList.remove('selected');
  }
}

function showSettingsFrame():void {
  const content = document.querySelector('#content') ?? document.querySelector('main');
  if (!content || content.querySelector(`[${MARK}="settings"]`)) return;

  const { url, channel } = frameUrl('settings.html', {});
  const frame = document.createElement('iframe');
  frame.setAttribute(MARK, 'settings');
  frame.title = 'AI Assistance settings';
  frame.src = url;
  frame.style.cssText = 'border:0;width:100%;min-height:calc(100vh - 120px);display:block';
  connectFrame(frame, channel, (control) => handleControl(control, () => undefined));
  content.replaceChildren(frame);
}

function start():void {
  if (window.opAiAssistanceLoaded) return;
  window.opAiAssistanceLoaded = true;

  let scheduled = false;
  const sync = ():void => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      syncWorkPackageButtons();
      syncMyAccount();
    });
  };

  new MutationObserver(sync).observe(document.body, { childList: true, subtree: true });
  window.addEventListener('popstate', sync);
  window.addEventListener('hashchange', () => {
    if (window.location.hash !== SETTINGS_HASH && document.querySelector(`[${MARK}="settings"]`)) window.location.reload();
    sync();
  });
  document.addEventListener('turbo:load', sync);
  sync();
}

start();
