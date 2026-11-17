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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import {
  decodeEntityReference,
  EntityId,
  EntityReference,
  isEntityId,
} from 'core-app/shared/types/entity-reference';

export type QueryFilterValue = HalResource|string|number|EntityReference;

export type FilterParamResult =
  | { ok:true; param:string }
  | { ok:false; code:'missing-identity' };

export function isQueryFilterValue(value:unknown):value is QueryFilterValue {
  return isEntityId(value) || value instanceof HalResource || decodeEntityReference(value) !== null;
}

export function queryFilterValueId(value:QueryFilterValue):EntityId|null {
  if (typeof value === 'string' || typeof value === 'number') {
    return value;
  }

  if (value instanceof HalResource) {
    return value.id ?? (value.href ? idFromLink(value.href) : null);
  }

  if (value.id !== undefined && value.id !== null) {
    return value.id;
  }

  return value.href ? idFromLink(value.href) : null;
}

export function serializeQueryFilterValue(value:QueryFilterValue|boolean):FilterParamResult {
  if (typeof value === 'boolean') {
    return { ok: true, param: value ? 't' : 'f' };
  }

  if (typeof value === 'string' || typeof value === 'number') {
    return { ok: true, param: String(value) };
  }

  if (value.id !== undefined && value.id !== null) {
    return { ok: true, param: String(value.id) };
  }

  const { href } = value;
  const param = href ? href.split('/').at(-1) : undefined;

  return param === undefined ? { ok: false, code: 'missing-identity' } : { ok: true, param };
}
