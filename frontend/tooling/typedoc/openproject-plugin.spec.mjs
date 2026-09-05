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
import { buildFixtureProject, buildFromRepoConfig } from './run-typedoc.mjs';

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

describe('shipped typedoc.json', () => {
  const revision = '0123456789abcdef0123456789abcdef01234567';
  // Two entry points in different subdirectories, so TypeDoc infers the same
  // base path (`src/stimulus`) that the full build does. A single entry point
  // would shift it and silently drop a path segment from every source link.
  const entryPoints = ['src/stimulus/controllers/check-all.controller.ts', 'src/stimulus/helpers/url-helpers.ts'];

  it('names default-exported controllers after their class', async () => {
    const project = await buildFromRepoConfig({ entryPoints, gitRevision: revision });
    const names = Object.values(project.reflections).map((reflection) => reflection.name);

    expect(names).toContain('CheckAllController');
    expect(names).not.toContain('default');
  });

  it('builds source links from the given revision and repository-relative path', async () => {
    const project = await buildFromRepoConfig({ entryPoints, gitRevision: revision });
    const urls = allSources(project).map((source) => source.url).filter(Boolean);

    expect(urls.length).toBeGreaterThan(0);
    for (const url of urls) {
      expect(url).toMatch(
        new RegExp(`/blob/${revision}/frontend/src/stimulus/[\\w./-]+\\.ts#L\\d+$`),
      );
    }

    expect(urls).toContainEqual(
      expect.stringContaining('frontend/src/stimulus/controllers/check-all.controller.ts'),
    );
  });
});
