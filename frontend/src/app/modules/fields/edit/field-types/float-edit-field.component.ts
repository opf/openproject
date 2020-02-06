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

import {Component} from "@angular/core";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {keyCodes} from "core-app/modules/common/keyCodes.enum";

@Component({
  template: `
    <input type="text"
           class="inline-edit--field"
           [attr.aria-required]="required"
           [attr.required]="required"
           [disabled]="inFlight"
           [ngModel]="formatter(value)"
           [attr.placeholder]="placeholder"
           (ngModelChange)="value = parser($event);"
           (keydown)="handleUserKeydown($event)"
           (focusout)="handler.onFocusOut()"
           [id]="handler.htmlId" />
  `
})
export class FloatEditFieldComponent extends EditFieldComponent {

  /** There's no builtin function to PARSE a locale string
   * but one to produce one so we can simply explode the string by the decimal separator
   * */
  public decimalSeparator:string = '.';
  public thousandSeparator:string = ',';

  private pattern:RegExp;

  ngOnInit() {
    super.ngOnInit();
    let testNumber = this.formatter(1234.56);
    this.decimalSeparator = testNumber.charAt(testNumber.length - 3);

    // set the thousand separator if it is used by toLocaleString
    if (testNumber.charAt(1) !== '2') {
      this.thousandSeparator = testNumber.charAt(1);
    }

    this.pattern = new RegExp(`^[\\d\\${this.decimalSeparator}\\${this.thousandSeparator}]*$`);
  }

  public handleUserKeydown(event:JQuery.TriggeredEvent) {
    if (event.which && event.which < 65) {
      this.handler.handleUserKeydown(event);
      return true;
    }

    // Avoid meta events
    if (event.metaKey || event.ctrlKey) {
      return true;
    }

    // Test if key matches our number pattern
    if (event.key && !event.key.match(this.pattern)) {
      return false;
    }

    return true;
  }

  public parser(value:string|null):number|null {
    if (!value) {
      return null;
    }

    if (!value.match(this.pattern)) {
      return null;
    }

    // Remove decimal separator
    let parts = value.split(this.decimalSeparator);

    // Replace thousands separator if any
    parts[0] = parts[0].replace(/[^\d]/g, '');

    // Parseable number
    return parseFloat(parts.join('.'));
  }

  public formatter(value:number|null):string {
    if (!value) {
      return '';
    }

    return value.toLocaleString(
      this.I18n.locale,
      { useGrouping: true, maximumFractionDigits: 20 }
    );
  }

  public get placeholder() {
    return this.I18n.t('js.placeholders.float');
  }
}
