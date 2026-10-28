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

import { execFileSync } from 'node:child_process';
import * as fs from 'node:fs';
import { createRequire } from 'node:module';
import * as path from 'node:path';

interface ViteWatcher {
  on(event:'event', listener:(event:{ code:string }) => void):void;
}

const extensionDir = path.resolve(__dirname, '../../extensions/blocknote-extensions');
const frontendDir = path.resolve(__dirname, '..');
const packageDir = path.join(frontendDir, 'node_modules/@openproject/op-blocknote-extensions');

function log(message:string) {
  console.log(`[op-blocknote-extensions] ${message}`);
}

// Only these are linked, not the whole folder: with preserveSymlinks, the extension's own
// node_modules would otherwise shadow the frontend's copies of react and @blocknote/*.
const linkedEntries = ['package.json', 'dist'];

function isLinked() {
  return fs.lstatSync(path.join(packageDir, 'dist'), { throwIfNoEntry: false })?.isSymbolicLink() ?? false;
}

function link() {
  if (isLinked()) return;

  fs.rmSync(packageDir, { recursive: true, force: true });
  fs.mkdirSync(packageDir, { recursive: true });
  linkedEntries.forEach((entry) => {
    fs.symlinkSync(path.relative(packageDir, path.join(extensionDir, entry)), path.join(packageDir, entry));
  });
}

function restoreNpmPackage() {
  if (!isLinked()) return;

  log('restoring the npm package');
  fs.rmSync(packageDir, { recursive: true, force: true });
  execFileSync('npm', ['install', '--no-save', '--no-audit', '--no-fund'], { cwd: frontendDir, stdio: 'inherit' });
}

function installDependencies() {
  const lockfile = path.join(extensionDir, 'package-lock.json');
  const installedLockfile = path.join(extensionDir, 'node_modules/.package-lock.json');

  if (!fs.existsSync(installedLockfile) || fs.statSync(lockfile).mtimeMs > fs.statSync(installedLockfile).mtimeMs) {
    execFileSync('npm', ['ci'], { cwd: extensionDir, stdio: 'inherit' });
  }
}

async function watch() {
  const extensionRequire = createRequire(path.join(extensionDir, 'package.json'));
  const ts = extensionRequire('typescript') as typeof import('typescript');
  const vite = await import(extensionRequire.resolve('vite')) as { build:(config:object) => Promise<ViteWatcher> };

  ts.createSolutionBuilderWithWatch(
    ts.createSolutionBuilderWithWatchHost(ts.sys),
    [path.join(extensionDir, 'tsconfig.lib.json')],
    { preserveWatchOutput: true },
  ).build();

  const watcher = await vite.build({
    root: extensionDir,
    configFile: path.join(extensionDir, 'vite.config.ts'),
    mode: 'development',
    // tsc writes the type declarations into the same directory
    build: { emptyOutDir: false, watch: {} },
  });

  await new Promise<void>((resolve) => {
    watcher.on('event', ({ code }) => {
      if (code === 'END' || code === 'ERROR') resolve();
    });
  });
}

export async function useLocalOpBlockNoteExtensions(isDevServer:boolean) {
  if (!['true', '1'].includes(process.env.OP_BLOCKNOTE_EXTENSIONS_LOCAL ?? '')) {
    restoreNpmPackage();
    return;
  }

  installDependencies();
  link();

  if (isDevServer) {
    log(`watching ${path.relative(process.cwd(), extensionDir)}`);
    await watch();
  } else {
    execFileSync('npm', ['run', 'build'], { cwd: extensionDir, stdio: 'inherit' });
  }
}
