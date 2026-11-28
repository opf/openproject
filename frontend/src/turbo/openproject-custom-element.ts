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

export function isOpenProjectCustomElement(node:EventTarget | null):node is HTMLElement{
  return node instanceof HTMLElement && node.tagName.startsWith('OPCE-');
}

// populateInputsFromDataset reads the data attributes only on construction. Elements listed
// here re-render on input changes, so changed data attributes are assigned to their inputs.
// Other elements are left as they are.
// TODO: Signal inputs rendered as plain attributes (e.g. chart-data on opce-velocity-chart) are
// still not refreshed. Copying the attributes named in customElements.get(tag).observedAttributes
// with setAttribute is enough for them, as Angular Elements passes those to setInput.
// TODO: Migrate the @Input fields read by populateInputsFromDataset (e.g. OpPrincipalComponent)
// to signal inputs rendered as plain attributes. That removes the need for
// ALLOWED_OPENPROJECT_CUSTOM_ELEMENTS and the JSON.parse assignment below.
const ALLOWED_OPENPROJECT_CUSTOM_ELEMENTS = ['opce-principal'];

export function refreshOpenProjectCustomElement(element:HTMLElement, newElement:HTMLElement):void {
  if (!ALLOWED_OPENPROJECT_CUSTOM_ELEMENTS.includes(element.localName)) return;

  Object.keys(element.dataset).forEach((key) => {
    if (!(key in newElement.dataset)) delete element.dataset[key];
  });

  // Angular elements define their inputs as accessors on the element prototype.
  const inputs = Object.getPrototypeOf(element) as object;
  Object.entries(newElement.dataset).forEach(([key, value]) => {
    if (element.dataset[key] === value) return;

    element.dataset[key] = value;
    if (Object.hasOwn(inputs, key)) {
      try {
        (element as unknown as Record<string, unknown>)[key] = JSON.parse(value!);
      } catch (error) {
        console.error(`Couldn't parse the ${key} input of ${element.localName}:`, value, error);
      }
    }
  });
}
