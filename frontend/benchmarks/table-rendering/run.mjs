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

import { createServer } from 'node:http';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import { resolve, extname } from 'node:path';
import { createHash } from 'node:crypto';
import { chromium } from 'playwright';

const output = resolve(process.env.TABLE_BENCHMARK_BUILD_DIRECTORY ?? 'dist/table-rendering-benchmark');
const workspace = JSON.parse(await readFile('angular.json', 'utf8'));
const options = workspace.projects.OpenProject.architect['table-benchmark'].options;
if (!options.aot || !options.optimization.scripts) throw new Error('Benchmark requires AOT and script optimization');
const bundles = await Promise.all((await readdir(output)).filter((name) => name.endsWith('.js')).map(async (name) => ({
  name, sha256: createHash('sha256').update(await readFile(resolve(output, name))).digest('hex'),
})));
const server = createServer(async (request, response) => {
  const pathname = new URL(request.url, 'http://localhost').pathname;
  const file = resolve(output, `.${pathname === '/' ? '/index.html' : pathname}`);
  if (!file.startsWith(`${output}/`)) { response.writeHead(403).end(); return; }
  try {
    const content = await readFile(file);
    response.setHeader('Content-Type', ({ '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css' })[extname(file)] ?? 'application/octet-stream');
    response.end(content);
  } catch { response.writeHead(404).end(); }
});
await new Promise((done) => server.listen(0, '127.0.0.1', done));
let browser;
try {
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto(`http://127.0.0.1:${server.address().port}`);
  await page.waitForFunction(() => typeof window.runBenchmark === 'function');
  const session = await page.context().newCDPSession(page);
  if (process.env.TABLE_BENCHMARK_PROFILE) {
    await session.send('Profiler.enable');
    await session.send('Profiler.start');
  }
  let timeout;
  const benchmark = await Promise.race([
    page.evaluate(() => window.runBenchmark()),
    new Promise((_, reject) => { timeout = setTimeout(() => reject(new Error('Benchmark timed out')), 120_000); }),
  ]).finally(() => clearTimeout(timeout));
  if (process.env.TABLE_BENCHMARK_PROFILE) {
    const { profile } = await session.send('Profiler.stop');
    await writeFile(process.env.TABLE_BENCHMARK_PROFILE, JSON.stringify(profile));
  }
  if (errors.length) throw new Error(errors.join('\n'));
  if (benchmark.isDevMode !== false) throw new Error('Expected optimized Angular production mode');
  const result = { buildDirectory: output, bundles, node: process.version, profiled: !!process.env.TABLE_BENCHMARK_PROFILE, browser: browser.version(), capturedAt: new Date().toISOString(), buildTarget: 'OpenProject:table-benchmark', aot: true, optimization: true, ...benchmark };
  const destination = process.env.TABLE_BENCHMARK_OUTPUT ?? `${output}/results.json`;
  await writeFile(destination, JSON.stringify(result, null, 2) + '\n');
  console.table(benchmark.results.map(({ renderer, rowCount, relationParents, initialMs, redrawMs, refreshMs, stages }) => ({ renderer, rowCount, relationParents, initialMs, redrawMs, refreshMs, refreshRenderCalls: stages.refresh.renderCalls })));
  console.log(`Saved ${destination}`);
} finally {
  await browser?.close();
  await new Promise((done) => server.close(done));
}
