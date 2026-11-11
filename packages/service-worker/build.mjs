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

import { build, context } from 'esbuild';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const packageDir = path.dirname(fileURLToPath(import.meta.url));
const devOutdir = path.resolve(packageDir, '../../frontend/tmp/service-worker');
const releaseOutdir = path.resolve(packageDir, '../../public/assets/frontend');
const args = process.argv.slice(2);
const dev = args.includes('--dev');
const watch = args.includes('--watch');
const outdirArg = args.find((arg) => arg.startsWith('--outdir='))?.slice('--outdir='.length);

if (watch && !dev) {
  console.error('--watch requires --dev');
  process.exit(1);
}

const unhashed = dev || outdirArg !== undefined;
const outdir = outdirArg
  ? path.resolve(process.cwd(), outdirArg)
  : dev
    ? devOutdir
    : releaseOutdir;

if (!dev && !outdirArg && !existsSync(outdir)) {
  console.error(`${outdir} does not exist. Run the Angular build (ng build) before building the service worker.`);
  process.exit(1);
}

const options = {
  entryPoints: [path.join(packageDir, 'src/main.ts')],
  bundle: true,
  format: 'iife',
  platform: 'browser',
  target: 'es2022',
  tsconfig: path.join(packageDir, 'tsconfig.app.json'),
  outdir,
  entryNames: unhashed ? 'service-worker' : 'service-worker-[hash]',
  minify: !dev,
  sourcemap: dev ? 'inline' : false,
  logLevel: 'info',
};

if (watch) {
  const ctx = await context(options);
  await ctx.watch();
} else {
  await build(options);
}
