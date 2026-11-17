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
import { hostsFrom, SCRIPT_ID } from './shared/hosts';
import { loadSettings } from './shared/storage';

// The content script runs on the hosts that the user granted, and only there. The background
// keeps no state of its own, so it works as a Chrome service worker.
async function registerContentScript():Promise<void> {
  const [{ origins = [] }, settings] = await Promise.all([browser.permissions.getAll(), loadSettings()]);
  const matches = hostsFrom(origins, settings.llmBaseUrl, settings.instanceUrl);

  const registered = await browser.scripting.getRegisteredContentScripts({ ids: [SCRIPT_ID] });
  if (registered.length > 0) await browser.scripting.unregisterContentScripts({ ids: [SCRIPT_ID] });
  if (matches.length === 0) return;

  await browser.scripting.registerContentScripts([{
    id: SCRIPT_ID,
    js: ['content.js'],
    matches,
    runAt: 'document_idle',
    persistAcrossSessions: true,
  }]);
}

// A grant and a settings change often arrive together; the runs must not interleave their
// unregister and register calls.
let syncing = Promise.resolve();

function syncContentScript():Promise<void> {
  syncing = syncing.then(registerContentScript).catch((error:unknown) => {
    console.error('AI Assistance: could not register the content script', error);
  });
  return syncing;
}

// A new OpenProject host gets the content script in its open tabs at once, so the button
// shows without a reload. This runs here and not in the popup: the browser's permission
// prompt can close the popup before the grant arrives.
async function onHostsAdded(added:string[]):Promise<void> {
  await syncContentScript();
  const settings = await loadSettings();
  const hosts = hostsFrom(added, settings.llmBaseUrl, settings.instanceUrl);
  if (hosts.length === 0) return;

  const tabs = await browser.tabs.query({ url: hosts });
  await Promise.all(tabs.map((tab) => tab.id === undefined
    ? Promise.resolve()
    : browser.scripting.executeScript({ target: { tabId: tab.id }, files: ['content.js'] }).then(() => undefined, () => undefined)));
}

browser.runtime.onInstalled.addListener(() => void syncContentScript());
browser.runtime.onStartup.addListener(() => void syncContentScript());
browser.permissions.onAdded.addListener(({ origins = [] }) => void onHostsAdded(origins));
browser.permissions.onRemoved.addListener(() => void syncContentScript());
// The LLM server in the settings is never an OpenProject host.
browser.storage.onChanged.addListener((changes, area) => {
  if (area === 'local' && 'settings' in changes) void syncContentScript();
});
