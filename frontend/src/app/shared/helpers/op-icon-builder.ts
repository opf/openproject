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

import { toDOMString } from '@openproject/octicons-angular';

/**
 * Return an <i> HTML element with the given icon classes
 * and aria-hidden=true set.
 */
export function opIconElement(...classes:string[]) {
  const icon = document.createElement('i');
  icon.setAttribute('aria-hidden', 'true');
  icon.classList.add(...classes);

  return icon;
}

/**
 * Return an <i> HTML element with the octicon SVG inside
 * aria-hidden=true is set
 */
export function octiconElement(iconData:any, size:'xsmall'|'small' = 'small', classes = '', title = '') {
  const iconString:string = toDOMString(
    iconData, // SVG data for the icon.
    size,
    { 'aria-hidden': 'true',
      class: classes,
      title: title},
  );
  const icon = document.createElement('i');
  icon.innerHTML = iconString;

  return icon;
}
