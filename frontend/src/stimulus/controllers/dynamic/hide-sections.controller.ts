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

import { Controller } from '@hotwired/stimulus';
import { navigator } from '@hotwired/turbo';

export default class extends Controller {
  static targets = ['section', 'select', 'form'];

  declare readonly sectionTargets:HTMLElement[];

  declare readonly selectTarget:HTMLSelectElement;

  declare readonly formTarget:HTMLFormElement;

  private boundSubmitListener = this.onSubmit.bind(this);

  formTargetConnected(target:HTMLFormElement) {
    target.addEventListener('submit', this.boundSubmitListener);
  }

  formTargetDisconnected(target:HTMLFormElement) {
    target.removeEventListener('submit', this.boundSubmitListener);
  }

  add(event:Event) {
    const selectedValue = (event.target as HTMLSelectElement).value;
    if (!selectedValue) {
      return;
    }

    const section = this.sectionTargets.find((s) => s.dataset.sectionName === selectedValue);
    if (section) {
      section.hidden = false;
    }

    this.toggleOption(selectedValue);
    this.selectTarget.selectedIndex = 0;
  }

  hide(event:MouseEvent) {
    const section = (event.target as HTMLElement).closest<HTMLElement>('.hide-section');
    if (!section) { return; }

    section.hidden = true;
    const name = section.dataset.name!;
    this.toggleOption(name);
  }

  toggleOption(name:string) {
    const option = Array
      .from(this.selectTarget.options)
      .find((opt:HTMLOptionElement) => opt.value === name);

    if (!option) {
      return;
    }

    option.disabled = !option.disabled;
  }

  // Remove hidden sections on submit
  onSubmit(event:SubmitEvent) {
    if (this.formTarget.dataset.confirmed === 'true' || this.sectionTargets.length === 0) {
      return true;
    }

    this.formTarget.dataset.confirmed = 'true';
    this.sectionTargets.forEach((section) => {
      if (section.hidden) {
        section.remove();
      }
    });

    event.preventDefault();
    navigator.submitForm(this.formTarget, event?.submitter || undefined);
    return false;
  }
}
