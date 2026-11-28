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

export const ATTRIBUTE_INPUTS_MARKER = 'opAttributeInputs';

interface AttributeInputsElementClass extends CustomElementConstructor {
  [ATTRIBUTE_INPUTS_MARKER]:true;
  observedAttributes:readonly string[];
}

export function markAttributeInputs(constructor:CustomElementConstructor):void {
  Object.defineProperty(constructor, ATTRIBUTE_INPUTS_MARKER, { value: true });
}

export function hasAttributeInputs(constructor:CustomElementConstructor | undefined):constructor is AttributeInputsElementClass {
  return !!constructor
    && ATTRIBUTE_INPUTS_MARKER in constructor
    && constructor[ATTRIBUTE_INPUTS_MARKER] === true
    && 'observedAttributes' in constructor
    && Array.isArray(constructor.observedAttributes);
}

export function refreshAttributeInputs(element:HTMLElement, newElement:HTMLElement):void {
  const constructor = customElements.get(element.localName);
  if (!hasAttributeInputs(constructor)) return;

  constructor.observedAttributes.forEach((name) => {
    const value = newElement.getAttribute(name);

    if (value === null) {
      element.removeAttribute(name);
    } else if (element.getAttribute(name) !== value) {
      element.setAttribute(name, value);
    }
  });
}
