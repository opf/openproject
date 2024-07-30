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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import { IPrincipal } from 'core-app/core/state/principals/principal.model';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';

export type PrincipalType = 'user'|'placeholder_user'|'group'|'external_user';

/*
 * This function is a helper that wraps around the old HalResource based principal type and the new interface based one.
 *
 * TODO: Remove old HalResource stuff :P
 */
export function hrefFromPrincipal(p:IPrincipal|PrincipalLike):string {
  if ((p as PrincipalLike).href) {
    return (p as PrincipalLike).href || '';
  }

  if ((p as IPrincipal)._links) {
    const self = (p as IPrincipal)._links.self as HalSourceLink;
    return self.href || '';
  }

  return '';
}
export function typeFromHref(href:string):PrincipalType|null {
  const match = /\/(user|group|placeholder_user|external_user)s\/\d+$/.exec(href);

  if (!match) {
    return null;
  }

  return match[1] as PrincipalType;
}
