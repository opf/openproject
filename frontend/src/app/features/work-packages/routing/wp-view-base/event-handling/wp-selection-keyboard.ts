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

import { closestInteractiveElement } from 'core-common/interactive-element-helper';
import { isApplePlatform } from 'core-common/platform';
import { isSelectAllShortcut } from 'core-common/selection-shortcuts';

export interface WorkPackageSelectAllOptions {
  root:HTMLElement;
  focusSelector:string;
  occurrenceSelector:string;
  rendered:() => RenderedWorkPackage[];
  selectAll:(rows:RenderedWorkPackage[], anchor:RenderedWorkPackage) => void;
}

const registrations = new WeakSet<HTMLElement>();

export function registerWorkPackageSelectAll(options:WorkPackageSelectAllOptions):() => void {
  const { root } = options;
  registrations.add(root);

  const handle = (event:KeyboardEvent) => {
    if (event.defaultPrevented || !isSelectAllShortcut(event, isApplePlatform())) return;

    const target = event.target;
    if (!(target instanceof HTMLElement)) return;

    let owner:HTMLElement|null = target;
    while (owner && !registrations.has(owner)) owner = owner.parentElement;
    if (owner !== root) return;

    const focus = target.closest<HTMLElement>(options.focusSelector);
    if (!focus || !root.contains(focus) || closestInteractiveElement(target, focus)) return;

    const element = focus.closest<HTMLElement>(options.occurrenceSelector);
    if (!element || !root.contains(element) || !element.dataset.workPackageId) return;

    const rows = options.rendered();
    const candidate = rows.find((row) => row.workPackageId === element.dataset.workPackageId
      && row.classIdentifier === element.dataset.classIdentifier);
    if (!candidate) return;

    const eligible = rows.filter((row) => Boolean(row.workPackageId));
    if (eligible.length === 0) return;

    const anchor = eligible.includes(candidate) ? candidate : eligible[0];
    event.preventDefault();
    options.selectAll(rows, anchor);
  };

  root.addEventListener('keydown', handle, true);

  return () => {
    root.removeEventListener('keydown', handle, true);
    registrations.delete(root);
  };
}
