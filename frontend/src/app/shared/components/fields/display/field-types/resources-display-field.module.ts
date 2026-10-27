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

import { take } from 'lodash-es';
import { cssClassCustomOption, DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  isUndisclosed,
  undisclosedValueNode,
} from 'core-app/shared/components/fields/display/field-types/undisclosed-value';

export class ResourcesDisplayField extends DisplayField {
  public isEmpty():boolean {
    return this.value == null || (Array.isArray(this.value) ? this.value.length === 0 : Object.keys(this.value as Record<string, unknown>).length === 0);
  }

  public get stringValue():string[] {
    const cf = this.resource[this.name] as { elements?:HalResource[], map?:HalResource[]['map'], name?:string }|null|undefined;
    if (this.schema && cf) {
      if (cf.elements) {
        return cf.elements.map((e) => e.name);
      } if (cf.map) {
        return cf.map((e) => e.name);
      } if (cf.name) {
        return [cf.name];
      }
      return [`error: ${JSON.stringify(cf)}`];
    }

    return [];
  }

  public get valueString():string {
    return this.stringValue.join(', ');
  }

  public render(element:HTMLElement, displayText:string):void {
    const values = this.stringValue;
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
  protected renderValues(values:unknown[], element:HTMLElement) {
    const content = document.createDocumentFragment();

    content.appendChild(this.abridgedDiv());

    if (values.length > 2) {
      const badge = this.optionDiv(values.length.toString(), 'badge');
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
   * Build a .custom-option div with the first two values, if any.
   */
  protected abridgedDiv() {
    const div = this.optionDiv('');
    const span = div.firstElementChild as HTMLSpanElement;
    const { resources } = this;

    take(resources, 2).forEach((resource, index) => {
      if (index > 0) {
        span.append(', ');
      }
      span.append(isUndisclosed(resource) ? undisclosedValueNode(resource.name) : resource.name);
    });

    if (resources.length > 2) {
      span.append(', ... ');
    }

    return div;
  }

  protected get resources():HalResource[] {
    const cf = this.resource[this.name] as { elements?:HalResource[] }|HalResource[]|null|undefined;

    if (!this.schema || !cf) {
      return [];
    }
    if (Array.isArray(cf)) {
      return cf;
    }

    return cf.elements ?? [cf as HalResource];
  }
}
