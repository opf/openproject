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

import { SVGData, toDOMString } from '@openproject/octicons-angular';
import { withTooltip } from './tooltip-helper';

export interface PrimerIconButtonOptions {
  icon:SVGData;
  label:string;
  classes?:string[];
}

/**
 * Plain-DOM counterpart of `<primer-icon-button scheme="invisible">` for
 * imperatively built markup such as fast-table rows, where mounting a
 * component per row would need its own lifecycle.
 */
export function primerIconButton({ icon, label, classes = [] }:PrimerIconButtonOptions):DocumentFragment {
  const button = document.createElement('button');
  button.type = 'button';
  button.classList.add('Button', 'Button--iconOnly', 'Button--invisible', 'Button--medium', ...classes);
  button.innerHTML = toDOMString(icon, 'small', { 'aria-hidden': 'true', class: 'Button-visual', fill: 'currentColor' });

  return withTooltip(button, label, 'label');
}
