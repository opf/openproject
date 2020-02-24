// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class DurationDisplayField extends DisplayField {
  @InjectField() timezoneService:TimezoneService;

  private derivedText = this.I18n.t('js.label_value_derived_from_children');

  public get valueString() {
    return this.timezoneService.formattedDuration(this.value);
  }

  /**
   * Duration fields may have an additional derived value
   */
  public get derivedPropertyName() {
    return "derived" + this.name.charAt(0).toUpperCase() + this.name.slice(1);
  }

  public get derivedValue():string|null {
    return this.resource[this.derivedPropertyName];
  }

  public get derivedValueString():string {
    const value = this.derivedValue;

    if (value) {
      return this.timezoneService.formattedDuration(value);
    } else {
      return this.placeholder;
    }
  }

  public render(element:HTMLElement, displayText:string):void {
    if (this.isEmpty()) {
      element.textContent = this.placeholder;
      return;
    }

    element.classList.add('split-time-field');
    let value = this.value;
    let actual:number = (value && this.timezoneService.toHours(value)) || 0;

    if (actual !== 0) {
      this.renderActual(element, displayText);
    }

    let derived = this.derivedValue;
    if (derived && this.timezoneService.toHours(derived) !== 0) {
      this.renderDerived(element, this.derivedValueString, actual !== 0);
    }
  }

  public renderActual(element:HTMLElement, displayText:string):void {
    const span = document.createElement('span');

    span.textContent = displayText;
    span.title = this.valueString;
    span.classList.add('-actual-value');

    element.appendChild(span);
  }

  public renderDerived(element:HTMLElement, displayText:string, actualPresent:boolean):void {
    const span = document.createElement('span');

    span.setAttribute('title', this.texts.empty);
    span.textContent = '(' + (actualPresent ? '+' : '') + displayText + ')';
    span.title = `${this.derivedValueString} ${this.derivedText}`;
    span.classList.add('-derived-value');

    if (actualPresent) {
      span.classList.add('-with-actual-value');
    }

    element.appendChild(span);
  }

  public get title():string|null {
    return null; // we want to render separate titles ourselves
  }

  public isEmpty():boolean {
    const value = this.value;
    const derived = this.derivedValue;

    const valueEmpty = !value || this.timezoneService.toHours(value) === 0;
    const derivedEmpty = !derived || this.timezoneService.toHours(derived) === 0;


    return valueEmpty && derivedEmpty;
  }
}
