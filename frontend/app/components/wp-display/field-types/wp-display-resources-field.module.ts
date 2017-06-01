// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {DisplayField} from "../wp-display-field/wp-display-field.module";
import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';

export const cssClassCustomOption = 'custom-option';

export class ResourcesDisplayField extends DisplayField {
  private text:{ empty:string, placeholder:string };

  constructor(public resource:HalResource,
              public name:string,
              public schema:op.FieldSchema) {
    super(resource, name, schema);
    this.text = {
      empty: this.I18n.t('js.work_packages.no_value'),
      placeholder: this.I18n.t('js.placeholders.default')
    };
  }

  public isEmpty():boolean {
    return _.isEmpty(this.value);
  }

  public get value() {
    if (this.schema) {
      var cf = this.resource[this.name];

      if (cf.elements) {
        return cf.elements.map((e:any) => e.name);
      } else if (cf.map) {
        return cf.map((e:any) => e.name);
      } else if (cf.name) {
        return [cf.name];
      } else {
        return ["error: " + JSON.stringify(cf)];
      }
    } else {
      return null;
    }
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
   * Render an empty placeholder if no values are present
   */
  protected renderEmpty(element:HTMLElement) {
    const emptyDiv = document.createElement('div');
    emptyDiv.setAttribute('title', this.text.empty);
    emptyDiv.textContent = this.text.placeholder;
    emptyDiv.classList.add(cssClassCustomOption, '-empty');

    element.appendChild(emptyDiv);
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
  private optionDiv(text:string, ...classes:string[]) {
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
  private valueAbridged(values:any[]) {
    const valueForDisplay = _.take(values, 2);

    if (values.length > 2) {
      valueForDisplay.push('... ');
    }

    return valueForDisplay.join(', ');
  }
}
