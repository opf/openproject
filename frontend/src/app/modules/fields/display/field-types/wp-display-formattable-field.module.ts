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

import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {ExpressionService} from "../../../../../../common/expression.service";

export class FormattableDisplayField extends DisplayField {

  public render(element:HTMLElement, displayText:string):void {
    element.classList.add('read-value--html', 'wiki', 'highlight', '-multiline');

    let span = document.createElement('span');
    span.innerHTML = displayText;

    element.innerHTML = '';
    element.appendChild(span);
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
    } else {
      return '';
    }
  }
}
