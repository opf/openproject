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

export default class GeneratePdfController extends Controller {
  static targets = ['templates', 'inputGroups', 'submit'];

  declare inputGroupsTargets:HTMLElement[];

  declare readonly submitTarget:HTMLElement;

  templatesChanged(event:Event) {
    const target = event.target as HTMLSelectElement;
    const data = target.options[target.selectedIndex].dataset;
    const template = target.options[target.selectedIndex].value;

    const formControl = target.closest<HTMLElement>('.FormControl');
    const captionElement = formControl?.querySelector<HTMLElement>('.FormControl-caption');
    if (captionElement) {
      captionElement.innerText = (data.caption ?? '');
    }
    this.inputGroupsTargets.forEach((inputGroup:HTMLElement) => {
      if (inputGroup.dataset.template === template) {
        inputGroup.classList.remove('d-none');
        this.adjustFormSubmitTarget(inputGroup);
      } else {
        inputGroup.classList.add('d-none');
      }
    });
  }

  // point the dialog submit button at whichever form is currently visible
  private adjustFormSubmitTarget(inputGroup:HTMLElement) {
    const form = inputGroup.querySelector('form');
    const formID = form?.getAttribute('id');
    if (formID) {
      this.submitTarget.setAttribute('form', formID);
    }
  }
}
