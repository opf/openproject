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

/**
 * Return the row html id attribute for the given work package ID.
 */
import { collapsedGroupClass } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';

export function rowId(workPackageId:string):string {
  return `wp-row-${workPackageId}-table`;
}

export function relationRowClass():string {
  return 'wp-table--relations-additional-row';
}

export function locateTableRow(workPackageId:string) {
  return document.querySelector<HTMLTableRowElement>(`.${rowId(workPackageId)}`);
}

export function locateTableRowByIdentifier(identifier:string) {
  return document.querySelector<HTMLTableRowElement>(`.${identifier}-table`);
}

export function isInsideCollapsedGroup(el?:Element | null) {
  if (!el) {
    return false;
  }

  return Array.from(el.classList).find((listClass) => listClass.includes(collapsedGroupClass())) != null;
}

export function locatePredecessorBySelector(el:HTMLElement, selector:string):HTMLElement|null {
  let previous = el.previousElementSibling;

  while (previous) {
    if (previous.matches(selector)) {
      return previous as HTMLElement;
    }
    previous = previous.previousElementSibling;
  }

  return null;
}

export function scrollTableRowIntoView(workPackageId:string):void {
  try {
    const element = locateTableRow(workPackageId)!;
    const container = getScrollParent(element);
    const containerTop = container.scrollTop;
    const containerBottom = containerTop + container.clientHeight;

    const elemTop = element.offsetTop;
    const elemBottom = elemTop + element.offsetHeight;

    if (elemTop < containerTop) {
      container.scrollTop = elemTop;
    } else if (elemBottom > containerBottom) {
      container.scrollTop = elemBottom - container.clientHeight;
    }
  } catch (e) {
    console.warn(`Can't scroll row element into view: ${e}`);
  }
}

function getScrollParent(element:HTMLElement, includeHidden = false) {
  const overflowRegex = includeHidden ? /(auto|scroll|hidden)/ : /(auto|scroll)/;

  let parent:HTMLElement|null = element.parentElement;

  while (parent && parent !== document.body) {
    const style = getComputedStyle(parent);
    const overflow = style.overflow + style.overflowY + style.overflowX;

    if (overflowRegex.test(overflow)) {
      return parent;
    }

    parent = parent.parentElement;
  }

  return document.scrollingElement || document.documentElement;
}
