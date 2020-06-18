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

import {DateDisplayField} from "core-app/modules/fields/display/field-types/date-display-field.module";

export class CombinedDateDisplayField extends DateDisplayField {
  text = {
    placeholder: {
      startDate: this.I18n.t('js.label_no_start_date'),
      dueDate: this.I18n.t('js.label_no_due_date')
    },
  };

  public render(element:HTMLElement, displayText:string):void {
    var startDateElement = this.createDateDisplayField('startDate');
    var dueDateElement = this.createDateDisplayField('dueDate');

    var separator = document.createElement('span');
    separator.textContent = ' - ';

    element.appendChild(startDateElement);
    element.appendChild(separator);
    element.appendChild(dueDateElement);
  }

  private createDateDisplayField(date:'dueDate'|'startDate'):HTMLElement {
    var dateElement = document.createElement('span');
    var dateDisplayField = new DateDisplayField(date, this.context);
    var text = this.resource[date] ?
      this.timezoneService.formattedDate(this.resource[date]) :
      this.text.placeholder[date];

    dateDisplayField.apply(this.resource, this.schema);
    dateDisplayField.render(dateElement, text);

    return dateElement;
  }
}
