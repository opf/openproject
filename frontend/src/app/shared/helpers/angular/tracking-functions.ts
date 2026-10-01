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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export function halHref<T extends HalResource>(_index:number, item:T):string|null {
  return item.href;
}

export function compareByAttribute(...attributes:string[]) {
  return (a:any, b:any) => {
    const bothNil = !a && !b;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    const same = !!a && !!b && attributes.every((attribute) => a[attribute] === b[attribute]);
    return bothNil || (!!a && !!b && same);
  };
}

export function compareByName<T extends HalResource>(a:T|undefined|null, b:T|undefined|null):boolean {
  return compareByAttribute('name')(a, b);
}

export function trackByHrefAndProperty(propertyName:string) {
  return (i:number, item:HalResource) => {
    const href:string = item.href ?? '';
    const prop:string = (item as Record<string, string|undefined>)[propertyName] ?? 'none';

    return `${href}#${propertyName}=${prop}`;
  };
}

export function compareByHref<T extends HalResource>(a:T|undefined|null, b:T|undefined|null):boolean {
  const bothNil = !a && !b;
  return bothNil || (!!a && !!b && a.href === b.href);
}

export function compareByHrefOrString<T extends HalResource>(a:T|string|undefined|null|unknown, b:T|string|undefined|null|unknown):boolean {
  if (a instanceof HalResource && b instanceof HalResource) {
    return compareByHref(a, b);
  }

  const bothNil = !a && !b;
  return bothNil || a === b;
}
