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

export default class MembersFormController extends Controller {
  static targets = [
    'filterContainer',
    'filterMemberButton',
    'statusSelect',
    'addMemberForm',
    'search',
    'addMemberButton',
    'membershipEditForm',
    'errorExplanation',
  ];

  declare readonly filterContainerTarget:HTMLElement;

  declare readonly filterMemberButtonTarget:HTMLButtonElement;

  declare readonly statusSelectTarget:HTMLInputElement;

  declare readonly addMemberFormTarget:HTMLElement;

  declare readonly addMemberButtonTarget:HTMLButtonElement;

  declare readonly membershipEditFormTargets:HTMLElement[];

  declare readonly errorExplanationTarget:HTMLElement;

  declare readonly hasErrorExplanationTarget:HTMLElement;

  private autocompleter:HTMLElement;

  connect() {
    // Show/Hide content when page is loaded
    if (window.OpenProject.guardedLocalStorage('showFilter') === 'true') {
      this.showFilter();
    } else {
      this.hideFilter();
      // In case showFilter is not set yet
      window.OpenProject.guardedLocalStorage('showFilter', 'false');
    }

    this.autocompleter = this.addMemberFormTarget.querySelector('opce-members-autocompleter') as HTMLElement;

    if (this.hasErrorExplanationTarget && this.errorExplanationTarget.textContent !== '') {
      this.showAddMemberForm();
    }

    if (this.addMemberButtonTarget.getAttribute('data-trigger-initially')) {
      this.showAddMemberForm();
    }
  }

  hideFilter() {
    this.filterContainerTarget.classList.add('collapsed');
  }

  showFilter() {
    this.filterContainerTarget.classList.remove('collapsed');
  }

  hideAddMemberForm() {
    this.addMemberFormTarget.style.display = 'none';
    this.addMemberButtonTarget.focus();
    this.addMemberButtonTarget.removeAttribute('disabled');
  }

  showAddMemberForm() {
    this.addMemberFormTarget.style.display = 'block';
    this.hideFilter();
    this.filterMemberButtonTarget.classList.remove('-active');
    window.OpenProject.guardedLocalStorage('showFilter', 'false');
    this.addMemberButtonTarget.setAttribute('disabled', 'true');

    this.focusAutocompleter();
  }

  toggleMemberFilter() {
    if (window.OpenProject.guardedLocalStorage('showFilter') === 'true') {
      window.OpenProject.guardedLocalStorage('showFilter', 'false');
      this.hideFilter();
      this.filterMemberButtonTarget.classList.remove('-active');
    } else {
      window.OpenProject.guardedLocalStorage('showFilter', 'true');
      this.showFilter();
      this.filterMemberButtonTarget.classList.add('-active');
      this.hideAddMemberForm();
      this.statusSelectTarget.focus();
    }
  }

  toggleMembershipEdit({ params: { togglingClass } }:{ params:{ togglingClass:string } }) {
    this.membershipEditFormTargets.forEach((form:HTMLElement) => {
      if (form.className === togglingClass) {
        form.style.display = form.style.display === 'none' ? '' : 'none';
      }
    });
  }

  focusAutocompleter():void {
    const input = this.autocompleter.querySelector<HTMLInputElement>('.ng-input input');
    input?.focus();
  }
}
