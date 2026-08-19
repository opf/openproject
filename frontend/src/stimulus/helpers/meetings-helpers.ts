/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

export function appendCollapsedState(
  target:URLSearchParams | FormData,
  headerSelector = '.CollapsibleHeader',
):void {
  const header = document.querySelector(headerSelector);

  if (header) {
    const collapsed = header.hasAttribute('data-collapsed');
    target.append('collapsed', collapsed.toString());
  }
}

export function hasUnsavedChanges():boolean {
  let hasTextChanges = false;

  document.querySelectorAll('input[type="text"], input[type="number"]').forEach((input) => {
    const currentValue = (input as HTMLInputElement).value;
    const initialValue = (input as HTMLInputElement).dataset.initialValue;

    if (initialValue === undefined) {
      if (currentValue.trim().length > 0) {
        hasTextChanges = true;
      }
    } else if (currentValue !== initialValue) {
      hasTextChanges = true;
    }
  });

  return hasTextChanges || window.OpenProject.pageWasEdited;
}
