//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { cssClassCustomOption, DisplayField } from "core-app/modules/fields/display/display-field.module";

export class ResourcesDisplayField extends DisplayField {
  public isEmpty():boolean {
    return _.isEmpty(this.value);
  }

  public get value() {
    const cf = this.resource[this.name];
    if (this.schema && cf) {

      if (cf.elements) {
        return cf.elements.map((e:any) => e.name);
      } else if (cf.map) {
        return cf.map((e:any) => e.name);
      } else if (cf.name) {
        return [cf.name];
      } else {
        return ["error: " + JSON.stringify(cf)];
      }
    }

    return [];
  }

  public render(element:HTMLElement, displayText:string):void {
    const values = this.value;
    element.innerHTML = '';
    element.setAttribute('title', values.join(', '));

    if (values.length === 0) {
      this.renderEmpty(element);
    } else {
      this.renderValues(values, element);
    }
  }

  /**
   * Renders at most the first two values, followed by a badge indicating
   * the total count.
   */
  protected renderValues(values:any[], element:HTMLElement) {
    const content = document.createDocumentFragment();
    const abridged = this.optionDiv(this.valueAbridged(values));

    content.appendChild(abridged);

    if (values.length > 2) {
      const badge = this.optionDiv(values.length.toString(), 'badge', '-secondary');
      content.appendChild(badge);
    }

    element.appendChild(content);
  }

  /**
   * Build .custom-option div/span nodes with the given text
   */
  protected optionDiv(text:string, ...classes:string[]) {
    const div = document.createElement('div');
    const span = document.createElement('span');
    div.classList.add(cssClassCustomOption);
    span.classList.add(...classes);
    span.textContent = text;

    div.appendChild(span);

    return div;
  }

  /**
   * Return the first two joined values, if any.
   */
  protected valueAbridged(values:any[]) {
    const valueForDisplay = _.take(values, 2);

    if (values.length > 2) {
      valueForDisplay.push('... ');
    }

    return valueForDisplay.join(', ');
  }
}
