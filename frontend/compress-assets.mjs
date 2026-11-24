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

import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { promisify } from 'node:util';
import zlib from 'node:zlib';

const gzip = promisify(zlib.gzip);
const brotli = promisify(zlib.brotliCompress);

const root = process.argv[2];
const compressible = /\.(js|css|svg)$/;

async function writeIfSmaller(file, original, compressed) {
  if (compressed.length < original.length) {
    await writeFile(file, compressed);
  }
}

async function compress(file) {
  const content = await readFile(file);

  await Promise.all([
    gzip(content, { level: zlib.constants.Z_BEST_COMPRESSION })
      .then((result) => writeIfSmaller(`${file}.gz`, content, result)),
    brotli(content, {
      params: {
        [zlib.constants.BROTLI_PARAM_QUALITY]: zlib.constants.BROTLI_MAX_QUALITY,
        [zlib.constants.BROTLI_PARAM_SIZE_HINT]: content.length,
      },
    }).then((result) => writeIfSmaller(`${file}.br`, content, result)),
  ]);
}

const files = (await readdir(root, { recursive: true, withFileTypes: true }))
  .filter((entry) => entry.isFile() && compressible.test(entry.name))
  .map((entry) => path.join(entry.parentPath, entry.name));

await Promise.all(files.map(compress));

console.log(`Compressed ${files.length} frontend assets`);
