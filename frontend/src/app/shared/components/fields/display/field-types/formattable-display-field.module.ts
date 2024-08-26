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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { ApplicationRef } from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { ExpressionService } from 'core-app/core/expression/expression.service';

export class FormattableDisplayField extends DisplayField {
  @InjectField() readonly appRef:ApplicationRef;

  public render(element:HTMLElement, displayText:string, options:any = {}):void {
    const div = document.createElement('div');

    div.classList.add(
      'read-value--html',
      'highlight',
      'op-uc-container',
      'op-uc-container_reduced-headings',
      '-multiline',
    );
    if (options.rtl) {
      div.classList.add('-rtl');
    }

    div.innerHTML = displayText;

    element.innerHTML = '';
    element.appendChild(div);
  }

  get placeholder():string {
    if (this.name === 'description') {
      return this.I18n.t('js.placeholders.description');
    }

    return super.placeholder;
  }

  public get isFormattable():boolean {
    return true;
  }

  public get value() {
    if (!this.schema) {
      return null;
    }
    const element = this.resource[this.name];
    if (!(element && element.html)) {
      return '';
    }

    return this.unescape(element.html);
  }

  // Escape the given HTML string from the backend, which contains escaped Angular expressions.
  // Since formattable fields are only binded to but never evaluated, we can safely remove these expressions.
  protected unescape(html:string) {
    if (html) {
      return ExpressionService.unescape(html);
    }
    return '';
  }
}
