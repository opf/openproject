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
import { originPattern } from '../shared/hosts';
import { loadSettings, saveSettings } from '../shared/storage';
import { h } from './dom';

const app = document.getElementById('app')!;

function render(...children:(Node | string)[]):void {
  app.replaceChildren(h('h2', {}, 'OpenProject AI Assistance'), ...children);
}

async function openSettings(tabId:number, origin:string):Promise<void> {
  await browser.tabs.update(tabId, { url: `${origin}/my/account#ai-assistance` });
  window.close();
}

async function main():Promise<void> {
  const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
  const url = tab?.url ?? '';
  if (!tab?.id || !/^https?:/.test(url)) {
    render(h('p', { class: 'muted' }, 'Open your OpenProject instance in this tab, then click the icon again.'));
    return;
  }

  const tabId = tab.id;
  const origin = new URL(url).origin;
  const pattern = originPattern(url);
  const granted = await browser.permissions.contains({ origins: [pattern] });

  if (granted) {
    render(
      h('p', {}, 'AI Assistance is on for ', h('strong', {}, origin), '.'),
      h('div', { class: 'row' },
        h('button', { class: 'primary', onclick: () => void openSettings(tabId, origin) }, 'Open settings'),
        h('button', {
          class: 'danger',
          onclick: () => void browser.permissions.remove({ origins: [pattern] }).then(() => window.close()),
        }, 'Turn off for this site')),
    );
    return;
  }

  const status = h('p', { class: 'small muted' });
  const settings = await loadSettings();
  render(
    h('p', {}, 'Add the AI Assistance button to the work packages of ', h('strong', {}, origin), '?'),
    h('p', { class: 'small muted' }, 'The extension uses your OpenProject permissions and your own LLM key. It reads and changes nothing until you ask.'),
    h('button', {
      class: 'primary',
      // permissions.request must run in the click handler, while the user gesture is active.
      // The background injects the content script when the grant arrives, because the
      // permission prompt can close this popup.
      onclick: () => {
        void saveSettings({ ...settings, instanceUrl: origin });
        void browser.permissions.request({ origins: [pattern] }).then(async (ok) => {
          if (!ok) {
            status.textContent = 'The permission was not granted.';
            return;
          }
          await openSettings(tabId, origin);
        });
      },
    }, `Enable on ${new URL(url).host}`),
    status,
  );
}

void main();
