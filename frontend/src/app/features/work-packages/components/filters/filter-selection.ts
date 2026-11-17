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

import { isQueryFilterValue, queryFilterValueId, QueryFilterValue } from 'core-app/features/hal/helpers/query-filter-value';
import {
  compareByIdentity,
  invalidShape,
  readProperty,
} from 'core-app/shared/components/autocompleter/selection/entity-selection';
import {
  DecodeResult,
  Decoder,
  SelectionAdapter,
  decodeAll,
} from 'core-app/shared/components/autocompleter/selection/selection-adapter';
import { EntityReference, decodeEntityReference } from 'core-app/shared/types/entity-reference';

type QueryFilterProfile = 'searchable'|'toggled';

function isQueryFilterValues(entries:readonly unknown[]):entries is QueryFilterValue[] {
  return entries.every(isQueryFilterValue);
}

function queryFilterDecoder(profile:QueryFilterProfile):Decoder<QueryFilterValue[]> {
  return (raw) => {
    if (Array.isArray(raw)) {
      const entries:unknown[] = raw;
      return isQueryFilterValues(entries)
        ? { ok: true, value: entries }
        : { ok: false, issue: { code: 'invalid-shape', index: entries.findIndex((entry) => !isQueryFilterValue(entry)) } };
    }
    if (profile === 'searchable' && raw === '') {
      return { ok: true, value: [] };
    }

    return isQueryFilterValue(raw) ? { ok: true, value: [raw] } : invalidShape;
  };
}

function trackable(value:unknown):string|number|undefined {
  return typeof value === 'string' || typeof value === 'number' ? value : undefined;
}

function truthy(value:unknown):string|number|undefined {
  return value ? trackable(value) : undefined;
}

function trackFilterValue(profile:QueryFilterProfile):(raw:unknown) => string|number|undefined {
  return (raw) => {
    if (typeof raw !== 'object' || raw === null) {
      return undefined;
    }

    const [href, id, name] = ['href', 'id', 'name'].map((key) => readProperty(raw, key));
    return profile === 'toggled'
      ? truthy(href) ?? truthy(id) ?? trackable(name)
      : trackable(href) ?? trackable(id) ?? trackable(name);
  };
}

function compareFilterValues(a:unknown, b:unknown):boolean {
  return (a == null && b == null) || a === b || compareByIdentity(a, b);
}

export function createQueryFilterSelectionAdapter(profile:QueryFilterProfile):SelectionAdapter<QueryFilterValue[]> {
  return new SelectionAdapter<QueryFilterValue[]>(
    queryFilterDecoder(profile),
    [],
    (values) => values,
    compareFilterValues,
    trackFilterValue(profile),
  );
}

function decodeProjectReferences(raw:unknown):DecodeResult<EntityReference[]> {
  if (!Array.isArray(raw)) {
    return { ok: false, issue: { code: 'wrong-cardinality' } };
  }

  const entries:unknown[] = raw;
  return decodeAll<EntityReference>(entries, (entry, index) => {
    const reference = decodeEntityReference(entry);
    const id = reference === null ? null : queryFilterValueId(reference);
    return reference !== null && id !== null && id !== ''
      ? { ok: true, value: reference }
      : { ok: false, issue: { code: 'invalid-shape', index } };
  });
}

export function createProjectFilterSelectionAdapter():SelectionAdapter<EntityReference[]> {
  return new SelectionAdapter<EntityReference[]>(
    decodeProjectReferences,
    [],
    (references) => references,
    compareFilterValues,
    trackFilterValue('toggled'),
  );
}
