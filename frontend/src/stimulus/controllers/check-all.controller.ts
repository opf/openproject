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

import { Controller } from '@hotwired/stimulus';
import CheckableController from './checkable.controller';
import { attributeTokenList, ensureId } from 'core-app/shared/helpers/dom-helpers';

type ExtractElement<T> = T extends Controller<infer U> ? U : never;
type CheckableElement = ExtractElement<CheckableController>;

/**
 * A Stimulus Controller providing behavior for "Check all" / "Uncheck all"
 * links and buttons.
 *
 * This controller does not provide functionality to toggle checkboxes itself,
 * but rather uses outlets to communicate (and delegate to) instances of
 * {@link CheckableController}. This is designed for scenarios where the "Check
 * all" links and buttons are outside scope of a `CheckableController`, i.e. in
 * another part of the DOM that is not a descendant.
 *
 * @see https://stimulus.hotwired.dev/reference/outlets
 *
 * This controller also handles setting `aria-controls` on its HTML element.
 *
 * Rather than using targets, it is up to the implementer to "wire up" events
 * using descriptors. This is designed for maximum flexibility.
 *
 * @example
 * ```html
 *  <div data-controller="check-all">
 *    <button data-action="check-all#checkAll">Check all</button>
 *    <button data-action="check-all#uncheckAll">Uncheck all</button>
 *  </div>
 * ```
 */
export default class CheckAllController extends Controller<HTMLElement> {
  static outlets = ['checkable'];

  declare readonly checkableOutlets:CheckableController[];

  checkableOutletConnected(_outlet:CheckableController, element:CheckableElement) {
    attributeTokenList(this.element, 'aria-controls').add(ensureId(element));
  }

  checkableOutletDisconnected(_outlet:CheckableController, element:CheckableElement) {
    attributeTokenList(this.element, 'aria-controls').remove(element.id);
  }

  /**
   * Checks all checkboxes in connected checkable outlets.
   *
   * @param event - The triggering event
   * @see {@link CheckableController#checkAll}
   */
  checkAll(event:Event) {
    this.checkableOutlets.forEach((outlet) => { outlet.checkAll(event); });
  }

  /**
   * Unchecks all checkboxes in connected checkable outlets.
   *
   * @param event - The triggering event
   * @see {@link CheckableController#uncheckAll}
   */
  uncheckAll(event:Event) {
    this.checkableOutlets.forEach((outlet) => { outlet.uncheckAll(event); });
  }

  /**
   * Toggles all checkboxes in connected checkable outlets.
   *
   * @param event - The triggering event
   * @see {@link CheckableController#toggleAll}
   */
  toggleAll(event:Event) {
    this.checkableOutlets.forEach((outlet) => { outlet.toggleAll(event); });
  }
}
