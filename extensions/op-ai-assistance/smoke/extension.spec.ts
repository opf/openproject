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

import { type BrowserContext, chromium, expect, test } from '@playwright/test';
import { resolve } from 'node:path';

const extensionPath = resolve(import.meta.dirname, '../dist/chrome');

let context:BrowserContext;
let extensionId:string;

test.beforeAll(async () => {
  context = await chromium.launchPersistentContext('', {
    channel: 'chromium',
    args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`],
  });
  const worker = context.serviceWorkers()[0] ?? await context.waitForEvent('serviceworker');
  extensionId = new URL(worker.url()).host;
});

test.afterAll(async () => {
  await context.close();
});

test('the service worker starts', () => {
  expect(extensionId).toMatch(/^[a-p]{32}$/);
});

test('the settings page renders the default skills without errors', async () => {
  const page = await context.newPage();
  const errors:string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));

  await page.goto(`chrome-extension://${extensionId}/settings.html`);

  await expect(page.getByRole('heading', { name: 'AI Assistance', level: 1 })).toBeVisible();
  await expect(page.getByText('Refresh work package')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Save' })).toBeVisible();
  expect(errors).toEqual([]);
});

test('the popup asks to open an OpenProject page', async () => {
  const page = await context.newPage();
  await page.goto(`chrome-extension://${extensionId}/popup.html`);
  await expect(page.getByRole('heading', { name: 'OpenProject AI Assistance' })).toBeVisible();
});

test('the chat page refuses an origin that the user did not grant', async () => {
  const page = await context.newPage();
  await page.goto(`chrome-extension://${extensionId}/chat.html#wp=1&channel=none&origin=https://op.example.com`);
  await expect(page.getByText('AI Assistance is not enabled for this page.')).toBeVisible();
});

test('the settings page ignores an origin that the user did not grant', async () => {
  const page = await context.newPage();
  await page.goto(`chrome-extension://${extensionId}/settings.html#channel=x&origin=https://evil.example`);
  await expect(page.getByRole('heading', { name: 'Connection' })).toBeVisible();
  await expect(page.getByText('https://evil.example')).toHaveCount(0);
  await expect(page.getByPlaceholder('https://openproject.example.com')).toBeVisible();
});
