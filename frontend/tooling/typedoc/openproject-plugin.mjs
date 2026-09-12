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

import { Converter } from 'typedoc';

/**
 * Members inherited from vendored base classes carry the source path of their
 * `.d.ts` file. With `sourceLinkTemplate` configured those render as links to
 * paths that do not exist in the repository, so they are dropped entirely.
 *
 * @param project - The converted project reflection
 * @returns The number of source entries removed
 */
function stripVendoredSources(project) {
  let stripped = 0;

  for (const reflection of Object.values(project.reflections)) {
    const { sources } = reflection;
    if (!sources) {
      continue;
    }

    const kept = sources.filter((source) => !source.fileName.includes('node_modules'));
    if (kept.length !== sources.length) {
      stripped += sources.length - kept.length;
      reflection.sources = kept.length > 0 ? kept : undefined;
    }
  }

  return stripped;
}

/**
 * TypeDoc plugin entry point.
 *
 * @param app - The TypeDoc application to extend
 */
export function load(app) {
  app.converter.on(Converter.EVENT_END, (context) => {
    const stripped = stripVendoredSources(context.project);
    app.logger.verbose(`Stripped ${stripped} vendored source entries`);
  });
}
