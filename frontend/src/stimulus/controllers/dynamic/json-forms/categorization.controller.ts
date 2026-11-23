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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';

// Switches the tabs of a JSON Forms categorization rendered by JsonForms::InputForm. The selected index is kept
// in a hidden input, so the server renders the same tab again when the form is refreshed.
export default class CategorizationController extends Controller<HTMLElement> {
  static targets = ['tab', 'panel', 'input'];

  declare readonly tabTargets:HTMLElement[];
  declare readonly panelTargets:HTMLElement[];
  declare readonly inputTarget:HTMLInputElement;

  select(event:Event) {
    const index = Number((event.currentTarget as HTMLElement).dataset.index);
    this.tabTargets.forEach((tab, i) => tab.setAttribute('aria-selected', String(i === index)));
    this.panelTargets.forEach((panel, i) => { panel.hidden = i !== index; });
    this.inputTarget.value = String(index);
  }
}
