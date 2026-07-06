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

import { Controller, ActionEvent } from '@hotwired/stimulus';
import invariant from 'tiny-invariant';

/**
 * A Stimulus Controller providing checkbox group behavior, enabling bulk
 * checking/unchecking of multiple checkboxes within a scoped element.
 *
 * This controller manages a collection of checkbox inputs marked with
 * `data-checkable-target="checkbox"`. It provides methods to check all,
 * uncheck all, toggle all, or toggle a filtered subset of checkboxes.
 *
 * Rather than defining event handlers within the controller, this controller
 * uses Stimulus actions. The implementer is responsible for adding appropriate
 * {@link https://stimulus.hotwired.dev/reference/actions#descriptors action descriptors}
 * to HTML elements that should trigger the controller's methods.
 *
 * Can be used standalone or in combination with {@link CheckAllController}
 * when the "Check all" / "Uncheck all" controls are outside the scope of this
 * controller (i.e. in another part of the DOM that is not a descendant).
 *
 * @example Basic usage with targets
 * ```html
 *  <div data-controller="checkable">
 *    <button data-action="checkable#checkAll">Check all</button>
 *    <button data-action="checkable#uncheckAll">Uncheck all</button>
 *    <button data-action="checkable#toggleAll">Toggle all</button>
 *
 *    <input type="checkbox" data-checkable-target="checkbox">
 *    <input type="checkbox" data-checkable-target="checkbox">
 *    <input type="checkbox" data-checkable-target="checkbox">
 *  </div>
 * ```
 *
 * @example Filtering with toggleSelection using action params
 * ```html
 *  <div data-controller="checkable">
 *    <button data-action="checkable#toggleSelection"
 *            data-checkable-key-param="role"
 *            data-checkable-value-param="admin">Toggle admins</button>
 *
 *    <input type="checkbox" data-checkable-target="checkbox" data-role="admin">
 *    <input type="checkbox" data-checkable-target="checkbox" data-role="member">
 *    <input type="checkbox" data-checkable-target="checkbox" data-role="admin">
 *  </div>
 * ```
 *
 * @see {@link CheckAllController} for controlling from outside the DOM scope
 */
export default class CheckableController extends Controller<HTMLElement> {
  static targets = ['checkbox'];

  declare readonly checkboxTargets:HTMLInputElement[];

  /**
   * Checks all checkbox targets.
   *
   * @param event - The triggering event (will be prevented)
   */
  checkAll(event:Event) {
    event.preventDefault();
    this.toggleChecked(this.checkboxTargets, true);
  }

  /**
   * Unchecks all checkbox targets.
   *
   * @param event - The triggering event (will be prevented)
   */
  uncheckAll(event:Event) {
    event.preventDefault();
    this.toggleChecked(this.checkboxTargets, false);
  }

  /**
   * Toggles all checkbox targets. If all are checked, unchecks all.
   * If any are unchecked (mixed state or none checked), checks all.
   *
   * @param event - The triggering event (will be prevented)
   */
  toggleAll(event:Event) {
    event.preventDefault();

    this.toggleChecked(this.checkboxTargets);
  }

  /**
   * Toggles a filtered subset of checkboxes based on data attributes.
   *
   * This method filters checkboxes by matching a `data-*` attribute (specified
   * by `key`) against a value (specified by `value`). Useful for table-like
   * UIs where you want to toggle checkboxes by row or column.
   *
   * @param event - The ActionEvent containing params
   * @param event.params.key - The data attribute name to filter by (camelCase)
   * @param event.params.value - The value to match (will be converted to string)
   *
   * @throws {Error} If key or value params are missing
   *
   * @example Toggle all checkboxes where data-column-id="3"
   * ```html
   *  <button data-action="checkable#toggleSelection"
   *          data-checkable-key-param="columnId"
   *          data-checkable-value-param="3">Toggle column</button>
   * ```
   */
  toggleSelection(event:ActionEvent) {
    event.preventDefault();

    const { key, value } = event.params as { key:string; value:unknown };
    invariant(key, 'toggleSelection requires a key param');
    invariant(value, 'toggleSelection requires value param');

    // eslint-disable-next-line @typescript-eslint/no-base-to-string
    const checkboxes = this.checkboxTargets.filter((checkbox) => checkbox.dataset[key] === value.toString());
    this.toggleChecked(checkboxes);
  }

  private toggleChecked(checkboxes:HTMLInputElement[], checked?:boolean) {
    // If all are checked -> uncheck all.
    // If mixed, indeterminate or none checked -> check all.
    const allChecked = checkboxes.every((checkbox) => checkbox.checked && !checkbox.indeterminate);
    checked ??= !allChecked;

    checkboxes.forEach((checkbox) => {
      // Programmatically setting `checked` does not clear the indeterminate
      // flag the way a native click does, so clear it explicitly.
      checkbox.indeterminate = false;
      checkbox.checked = checked;
      // Dispatch a bubbling `change` so form-level listeners
      // react just as they would to a native checkbox toggle.
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));
    });
  }
}
