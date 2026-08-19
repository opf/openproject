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

export default class RevisionsFormController extends Controller<HTMLFormElement> {
  static targets = ['rev', 'revTo'];

  declare readonly revTargets:HTMLInputElement[];
  declare readonly revToTargets:HTMLInputElement[];

  private onRevChange = this.updateRevToTargets.bind(this);
  private onRevToChange = this.updateRevTargets.bind(this);

  revTargetConnected(target:HTMLInputElement) {
    target.addEventListener('change', this.onRevChange);
  }

  revTargetDisconnected(target:HTMLInputElement) {
    target.removeEventListener('change', this.onRevChange);
  }

  revToTargetConnected(target:HTMLInputElement) {
    target.addEventListener('change', this.onRevToChange);
  }

  revToTargetDisconnected(target:HTMLInputElement) {
    target.removeEventListener('change', this.onRevToChange);
  }

  private updateRevTargets() {
    const revIndex = this.revTargetCheckedIndex;
    const revToIndex = this.revToTargetCheckedIndex;
    if (revIndex === -1 || revToIndex === -1) {
      // Do not update if either index is invalid
      return;
    }
    const newIndex = Math.min(revIndex, revToIndex);
    this.revTargets.at(newIndex)!.checked = true;
  }

  private updateRevToTargets() {
    const revIndex = this.revTargetCheckedIndex;
    const revToIndex = this.revToTargetCheckedIndex;
    if (revIndex === -1 || revToIndex === -1) {
      // Do not update if either index is invalid
      return;
    }
    const newIndex = Math.max(revIndex, revToIndex);
    this.revToTargets.at(newIndex)!.checked = true;
  }

  private get revTargetCheckedIndex() {
    return this.revTargets.findIndex((t) => t.checked);
  }

  private get revToTargetCheckedIndex() {
    return this.revToTargets.findIndex((t) => t.checked);
  }
}
