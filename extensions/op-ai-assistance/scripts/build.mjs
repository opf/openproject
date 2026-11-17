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

import { build } from 'vite';
import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { sparklePng } from './icons.mjs';

const root = resolve(import.meta.dirname, '..');
const staging = resolve(root, 'dist/.staging');
const targets = ['firefox', 'chrome'];

const pages = ['popup', 'chat', 'settings'];
const scripts = { background: 'src/background.ts', content: 'src/content/index.ts' };

function mergeManifest(base, overlay) {
  return { ...base, ...overlay };
}

async function buildPages() {
  await build({
    root: resolve(root, 'src/pages'),
    base: './',
    logLevel: 'warn',
    configFile: false,
    build: {
      outDir: staging,
      emptyOutDir: false,
      modulePreload: false,
      rollupOptions: {
        input: Object.fromEntries(pages.map((page) => [page, resolve(root, `src/pages/${page}.html`)])),
      },
    },
  });
}

// Content scripts and the Chrome service worker load as classic scripts, so each one is a
// single self-contained file.
async function buildScript(name, entry) {
  await build({
    root,
    logLevel: 'warn',
    configFile: false,
    build: {
      outDir: staging,
      emptyOutDir: false,
      lib: { entry: resolve(root, entry), formats: ['iife'], name: `opAiAssistance_${name}`, fileName: () => `${name}.js` },
    },
  });
}

async function writeIcons() {
  const icons = resolve(staging, 'icons');
  await mkdir(icons, { recursive: true });
  await cp(resolve(root, 'src/icons/icon.svg'), resolve(icons, 'icon.svg'));
  for (const size of [16, 32, 48, 128]) {
    await writeFile(resolve(icons, `icon-${size}.png`), sparklePng(size));
  }
}

async function main() {
  await rm(resolve(root, 'dist'), { recursive: true, force: true });
  await mkdir(staging, { recursive: true });

  await buildPages();
  for (const [name, entry] of Object.entries(scripts)) {
    await buildScript(name, entry);
  }
  await writeIcons();

  const base = JSON.parse(await readFile(resolve(root, 'manifest/base.json'), 'utf8'));
  const version = JSON.parse(await readFile(resolve(root, 'package.json'), 'utf8')).version;

  for (const target of targets) {
    const overlay = JSON.parse(await readFile(resolve(root, `manifest/${target}.json`), 'utf8'));
    const out = resolve(root, 'dist', target);
    await cp(staging, out, { recursive: true });
    await writeFile(resolve(out, 'manifest.json'), `${JSON.stringify({ ...mergeManifest(base, overlay), version }, null, 2)}\n`);
  }

  await rm(staging, { recursive: true, force: true });
  console.log(`Built ${targets.map((target) => `dist/${target}`).join(' and ')}`);
}

await main();
