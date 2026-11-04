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

import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const frontendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const buildScript = path.join(frontendDir, 'scripts/build-service-worker.mjs');
const ngBin = path.join(frontendDir, 'node_modules/@angular/cli/bin/ng.js');

const commands = {
  serve: { ng: ['serve'], worker: [] },
  // Angular must keep the worker file in the output directory it writes to.
  build: { ng: ['build', '--watch', '--no-delete-output-path'], worker: ['--outdir=../public/assets/frontend'] },
};
const [first, ...rest] = process.argv.slice(2);
const [command, ngArgs] = first === 'build' ? ['build', rest] : ['serve', process.argv.slice(2)];
const workerArgs = ['--dev', ...commands[command].worker];

// The worker file must exist before Angular globs its assets, so it is built once up front.
const initial = spawnSync(process.execPath, [buildScript, ...workerArgs], { stdio: 'inherit', cwd: frontendDir });
if (initial.status !== 0) {
  process.exit(initial.status ?? 1);
}

const children = [
  spawn(process.execPath, [buildScript, ...workerArgs, '--watch'], { stdio: 'inherit', cwd: frontendDir }),
  spawn(process.execPath, [...process.execArgv, ngBin, ...commands[command].ng, ...ngArgs], {
    stdio: 'inherit',
    cwd: frontendDir,
  }),
];

// Ctrl-C reaches both children and this runner at once, so an interrupt-style exit counts as a clean stop.
const interruptCodes = new Set([130, 143]);
const interruptSignals = new Set(['SIGINT', 'SIGTERM', 'SIGHUP']);
const finished = new Set();
let exitCode;

function stopAll() {
  children.forEach((child) => child.kill('SIGTERM'));
}

function settle(child, code) {
  finished.add(child);
  exitCode ??= code;
  stopAll();
  if (finished.size === children.length) process.exit(exitCode);
}

interruptSignals.forEach((signal) => process.on(signal, () => {
  exitCode ??= 0;
  stopAll();
}));

children.forEach((child) => {
  child.on('error', (error) => {
    console.error(error);
    settle(child, 1);
  });
  child.on('exit', (code, signal) => {
    const interrupted = interruptSignals.has(signal) || interruptCodes.has(code);
    settle(child, interrupted ? 0 : (code ?? 1));
  });
});
