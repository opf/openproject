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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { buildFixtureProject } from './run-typedoc.mjs';

const plugin = fileURLToPath(new URL('./openproject-plugin.mjs', import.meta.url));

function allSources(project) {
  const sources = [];
  for (const reflection of Object.values(project.reflections)) {
    sources.push(...(reflection.sources ?? []));
  }
  return sources;
}

describe('vendored source stripping', () => {
  it('leaves no source entries pointing into node_modules', async () => {
    const project = await buildFixtureProject({ fixture: 'vendored', plugins: [plugin] });
    const vendored = allSources(project).filter((s) => s.fileName.includes('node_modules'));

    expect(vendored).toHaveLength(0);
  });

  it('keeps source entries for first-party code', async () => {
    const project = await buildFixtureProject({ fixture: 'vendored', plugins: [plugin] });
    const firstParty = allSources(project).filter((s) => s.fileName.includes('uses-vendored'));

    expect(firstParty.length).toBeGreaterThan(0);
  });
});
