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

import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';

export function groupIdentifier(group:GroupObject) {
  let value = group.value || 'nullValue';

  if (group.href) {
    try {
      value += group.href.map((el) => el.href).join('-');
    } catch (e) {
      console.error(`Failed to extract group identifier for ${group.value}`);
    }
  }

  value = value.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  return `${groupByProperty(group)}-${value}`;
}

export function groupName(group:GroupObject) {
  const { value } = group;
  if (value === null) {
    return '-';
  }
  return value;
}

export function groupByProperty(group:GroupObject):string {
  return group._links.groupBy.href.split('/').pop()!;
}

/**
 * Get the row group class name for the given group id.
 */
export function groupedRowClassName(groupIndex:number) {
  return `__row-group-${groupIndex}`;
}

/**
 * Get the group type from its identifier.
 */
export function groupTypeFromIdentifier(groupIdentifier:string) {
  return groupIdentifier.split('-')[0];
}

/**
 * Get the group id from its identifier.
 */
export function groupIdFromIdentifier(groupIdentifier:string) {
  return groupIdentifier.split('-').pop();
}
