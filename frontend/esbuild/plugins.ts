/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import type { Plugin } from 'esbuild';
import * as fs from 'fs';
import * as path from 'node:path';

const customConfigPlugin:Plugin = {
  name: 'custom-config',
  setup({ initialOptions: options }) {
    if (options.chunkNames === '[name]-[hash]') { // named chunks
      options.chunkNames = '[dir]/[name]-[hash]';
    }
  },
};

const jqueryInjectionPlugin:Plugin = {
  name: 'jquery-injection',
  setup(build) {
    // Intercept legacy jQuery plugins that need the ESM jQuery instance.
    build.onResolve({ filter: /^(core-vendor\/enjoyhint|tablesorter)$/ }, (args) => {
      return {
        path: args.path,
        namespace: 'jquery-wrapper',
      };
    });

    // Provide the wrapper content
    build.onLoad({ filter: /.*/, namespace: 'jquery-wrapper' }, async (args) => {
      const workingDir = build.initialOptions.absWorkingDir ?? process.cwd();
      const modulePath = args.path === 'tablesorter'
        ? path.join(workingDir, 'node_modules', 'tablesorter', 'dist', 'js', 'jquery.tablesorter.combined.js')
        : path.join(workingDir, 'src', 'vendor', 'enjoyhint.js');
      const contents = await fs.promises.readFile(modulePath, 'utf8');

      // Wrap with jQuery import
      const wrappedCode = `
import jQuery from 'jquery';
import 'jquery-migrate';

const previousJQuery = window.jQuery;
const previousDollar = window.$;
const hadPreviousJQuery = 'jQuery' in window;
const hadPreviousDollar = '$' in window;

// Legacy jQuery plugins expect global jQuery while they load.
window.jQuery = jQuery;
window.$ = jQuery;

const define = undefined;
const module = undefined;
const exports = undefined;

${contents}

if (hadPreviousJQuery) {
  window.jQuery = previousJQuery;
} else {
  delete window.jQuery;
}

if (hadPreviousDollar) {
  window.$ = previousDollar;
} else {
  delete window.$;
}
`;

      return {
        contents: wrappedCode,
        loader: 'js',
        resolveDir: path.join(workingDir, 'src'),
      };
    });
  },
};

export default [customConfigPlugin, jqueryInjectionPlugin];
