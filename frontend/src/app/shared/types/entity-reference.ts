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

export type EntityId = string|number;

export type EntityReference =
  | { id:EntityId; href?:string|null; name?:string }
  | { id?:EntityId|null; href:string; name?:string };

export function isEntityId(value:unknown):value is EntityId {
  return typeof value === 'string' || (typeof value === 'number' && Number.isFinite(value));
}

export function decodeEntityReference(value:unknown):EntityReference|null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return null;
  }

  const id = 'id' in value ? value.id : undefined;
  const href = 'href' in value ? value.href : undefined;
  const name = 'name' in value ? value.name : undefined;

  const valid = (id == null || isEntityId(id))
    && (href == null || typeof href === 'string')
    && (name === undefined || typeof name === 'string')
    && (isEntityId(id) || (typeof href === 'string' && href.length > 0));

  return valid ? value as EntityReference : null;
}
