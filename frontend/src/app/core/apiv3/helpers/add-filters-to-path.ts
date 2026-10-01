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

import {
  ApiV3Filter,
  ApiV3FilterBuilder,
} from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

/**
 * Add or append filters to a given base URL.
 * If the URL already had filters, it is appending them, overriding existing filters with the same key.
 *
 * @param basePath The base path to add filters to.
 * @param filters An ApiV3FilterBuilder object containing the filters to add.
 * @param params Additional query parameters to add, if any.
 */
export function addFiltersToPath(
  basePath:string,
  filters:ApiV3FilterBuilder,
  params:Record<string, string> = {},
):URL {
  const url = new URL(basePath, window.location.origin);

  if (url.searchParams.has('filters')) {
    const existingFilters = JSON.parse(url.searchParams.get('filters')!) as ApiV3Filter[];
    url.searchParams.set('filters', JSON.stringify(existingFilters.concat(filters.filters)));
  } else {
    url.searchParams.set('filters', filters.toJson());
  }

  Object
    .keys(params)
    .forEach((key) => {
      url.searchParams.set(key, params[key]);
    });

  return url;
}
