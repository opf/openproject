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

import { toggleEnabled } from 'core-app/shared/helpers/dom-helpers';
import { ApplicationController } from 'stimulus-use';

export default class OpDisableWhenValueSelectedController extends ApplicationController {
  static targets = ['cause', 'effect'];

  declare readonly effectTargets:(HTMLInputElement|HTMLFieldSetElement)[];

  private boundListener = this.toggleDisabled.bind(this);

  causeTargetConnected(target:HTMLElement) {
    target.addEventListener('change', this.boundListener);
  }

  causeTargetDisconnected(target:HTMLElement) {
    target.removeEventListener('change', this.boundListener);
  }

  private toggleDisabled(evt:Event):void {
    const input = evt.target as HTMLInputElement;
    const targetName = input.dataset.targetName;

    this
      .effectTargets
      .filter((el) => targetName === el.dataset.targetName)
      .forEach((el) => {
        const disabled = this.willDisable(el, input.value);
        toggleEnabled(el, !disabled);
      });
  }

  private willDisable(el:HTMLElement, value:string):boolean {
    if (el.dataset.notValue) {
      return el.dataset.notValue === value;
    }

    return !(el.dataset.value === value);
  }
}
