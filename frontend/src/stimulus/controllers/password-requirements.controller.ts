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

const RULE_PATTERNS:Record<string, RegExp> = {
  uppercase: /[A-Z]/u,
  lowercase: /[a-z]/u,
  numeric: /\d/,
  special: /[^\da-zA-Z]/u,
};

export default class PasswordRequirementsController extends Controller {
  static targets = ['requirement', 'passwordInput'];

  declare readonly requirementTargets:HTMLElement[];
  declare readonly passwordInputTarget:HTMLInputElement;
  declare readonly hasPasswordInputTarget:boolean;

  private boundCheck:EventListener = this.check.bind(this);

  connect() {
    if (this.hasPasswordInputTarget) {
      this.passwordInputTarget.addEventListener('input', this.boundCheck);
    }
  }

  disconnect() {
    if (this.hasPasswordInputTarget) {
      this.passwordInputTarget.removeEventListener('input', this.boundCheck);
    }
  }

  check() {
    const password = this.hasPasswordInputTarget ? this.passwordInputTarget.value : '';

    if (password === '') {
      this.requirementTargets.forEach((target) => {
        target.classList.remove('op-password-requirements--item_met', 'op-password-requirements--item_unmet');
      });
      return;
    }

    this.requirementTargets.forEach((target) => {
      const type = target.dataset.requirementType;
      if (type === 'length') {
        const min = parseInt(target.dataset.minLength ?? '0', 10);
        this.setMet(target, password.length >= min);
      } else if (type === 'rule') {
        const pattern = RULE_PATTERNS[target.dataset.rule ?? ''];
        this.setMet(target, pattern ? pattern.test(password) : false);
      }
    });
  }

  private setMet(element:HTMLElement, met:boolean):void {
    element.classList.toggle('op-password-requirements--item_met', met);
    element.classList.toggle('op-password-requirements--item_unmet', !met);
  }
}
