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

import { booleanAttribute, numberAttribute } from '@angular/core';

export function stringAttribute(fallback:string):(value:string|null|undefined) => string {
  return (value) => value ?? fallback;
}

export function optionalStringAttribute():(value:string|null|undefined) => string|undefined {
  return (value) => value ?? undefined;
}

export function booleanAttributeOr(fallback:boolean):(value:boolean|string|null|undefined) => boolean {
  return (value) => (value === null || value === undefined ? fallback : booleanAttribute(value));
}

export function numberAttributeOr(fallback:number):(value:number|string|null|undefined) => number {
  return (value) => (value === null || value === undefined ? fallback : numberAttribute(value, fallback));
}

export function jsonAttribute<T extends object|number|boolean|null>(fallback:T):(value:T|string|null|undefined) => T {
  return (value) => {
    if (value === null || value === undefined) {
      return fallback;
    }

    if (typeof value !== 'string') {
      return value;
    }

    if (value.trim() === '') {
      return fallback;
    }

    try {
      return JSON.parse(value) as T;
    } catch {
      throw new Error(`Invalid JSON attribute value: ${value}`);
    }
  };
}
