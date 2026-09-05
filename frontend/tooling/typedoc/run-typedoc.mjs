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
import { Application, PackageJsonReader, TSConfigReader, TypeDocReader } from 'typedoc';

const fixturesRoot = fileURLToPath(new URL('./__fixtures__/', import.meta.url));
const toolingTsconfig = fileURLToPath(new URL('./tsconfig.json', import.meta.url));
const frontendRoot = fileURLToPath(new URL('../../', import.meta.url));

// Skip TypeDocReader so the repo's own `typedoc.json` (scoped to
// `src/stimulus/**`) never leaks into fixture conversions.
const readers = [new PackageJsonReader(), new TSConfigReader()];

/**
 * Converts a fixture directory with TypeDoc and returns the reflection model.
 *
 * @param options - Fixture name, plugins to load, and TypeDoc option overrides
 * @returns The converted project reflection
 */
export async function buildFixtureProject({ fixture, plugins = [], options = {} }) {
  const app = await Application.bootstrapWithPlugins({
    entryPoints: [`${fixturesRoot}${fixture}`],
    entryPointStrategy: 'expand',
    plugin: plugins,
    logLevel: 'Error',
    tsconfig: toolingTsconfig,
    ...options,
  }, readers);

  const project = await app.convert();
  if (!project) {
    throw new Error(`TypeDoc failed to convert fixture "${fixture}"`);
  }

  return project;
}

/**
 * Converts real sources using the repository's own `typedoc.json`.
 *
 * `buildFixtureProject` deliberately omits `TypeDocReader`, so a test using it
 * proves nothing about the shipped configuration — a plugin dropped from
 * `typedoc.json` would still be loaded if the test passed it explicitly. This
 * helper reads that file the way CI and `npm run generate-docs` do, overriding
 * only what a test needs to stay fast and deterministic.
 *
 * @param options - Entry points to convert and the revision for source links
 * @returns The converted project reflection
 */
export async function buildFromRepoConfig({ entryPoints, gitRevision }) {
  const app = await Application.bootstrapWithPlugins({
    options: frontendRoot,
    entryPoints: entryPoints.map((entry) => `${frontendRoot}${entry}`),
    gitRevision,
    logLevel: 'Error',
  }, [new TypeDocReader(), new PackageJsonReader(), new TSConfigReader()]);

  const project = await app.convert();
  if (!project) {
    throw new Error(`TypeDoc failed to convert ${entryPoints.join(', ')}`);
  }

  return project;
}
