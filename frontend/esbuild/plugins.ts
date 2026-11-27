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

import type { Plugin } from 'esbuild';
import * as fs from 'fs';
import * as path from 'node:path';
import rebundle from '@rx-angular/rebundle';

const customConfigPlugin:Plugin = {
  name: 'custom-config',
  setup({ initialOptions: options }) {
    if (options.minifySyntax) {
      // Primer elements use Catalyst which gets their tag names from their class names.
      // Minification changes the class names and will break those imports.
      options.keepNames = true;
    } else if (options.chunkNames === '[name]-[hash]') {
      // Do not use subdirectories in minified builds. The Angular chunk optimizer
      // moves the chunks to the output root. Then their relative imports fail.
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

// SPIKE: Propshaft leaves files named `-[hash].digested` alone, so imports between chunks keep
// resolving. Runs after rebundle, whose chunk file names cannot be configured.
const digestedChunkNamesPlugin:Plugin = {
  name: 'digested-chunk-names',
  setup(build) {
    build.onEnd((result) => {
      const { entryPoints, define } = build.initialOptions;
      if (!result.outputFiles || !result.metafile || define?.ngDevMode !== 'false') {
        return;
      }
      if (!entryPoints || Array.isArray(entryPoints)) {
        return;
      }

      const entryFiles = new Set(Object.keys(entryPoints).map((name) => `${name}.js`));
      const isChunk = (file:string) => file.endsWith('.js') && !entryFiles.has(path.basename(file));
      const renamed = new Set(result.outputFiles.map((file) => path.basename(file.path)).filter(isChunk));
      const rename = (file:string) => file.replace(/\.js(\.map)?$/, '.digested.js$1');
      const rewrite = (text:string) => text.replace(
        /([\w.-]+\.js)(\.map)?(?![\w.-])/g,
        (match, file:string, map = '') => (renamed.has(file) ? rename(file) + (map as string) : match),
      );
      const isRenamed = (file:string) => renamed.has(path.basename(file).replace(/\.map$/, ''));

      result.outputFiles = result.outputFiles.map((file) => {
        if (!/\.js(\.map)?$/.test(file.path)) {
          return file;
        }
        const text = rewrite(file.text);
        return {
          path: isRenamed(file.path) ? rename(file.path) : file.path,
          contents: new TextEncoder().encode(text),
          hash: file.hash,
          text,
        };
      });

      result.metafile.outputs = Object.fromEntries(
        Object.entries(result.metafile.outputs).map(([file, output]) => [
          isRenamed(file) ? rename(file) : file,
          {
            ...output,
            imports: output.imports.map((imported) => ({
              ...imported,
              path: isRenamed(imported.path) ? rename(imported.path) : imported.path,
            })),
          },
        ]),
      );
    });
  },
};

export default [rebundle(), digestedChunkNamesPlugin, customConfigPlugin, jqueryInjectionPlugin];
