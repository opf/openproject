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

import { DateDisplayField } from 'core-app/shared/components/fields/display/field-types/date-display-field.module';

export class CombinedDateDisplayField extends DateDisplayField {
  text = {
    placeholder: {
      startDate: this.I18n.t('js.label_no_start_date'),
      dueDate: this.I18n.t('js.label_no_due_date'),
      date: this.I18n.t('js.label_no_date'),
    },
  };

  public render(element:HTMLElement):void {
    if (this.name === 'date') {
      this.renderSingleDate('date', element);
      return;
    }

    if (this.startDate && (this.startDate === this.dueDate)) {
      this.renderSingleDate('startDate', element);
      return;
    }

    if (!this.resource.scheduleManually && !this.startDate && !this.dueDate) {
      element.innerHTML = this.customPlaceholder(`${this.text.placeholder.startDate} - ${this.text.placeholder.dueDate}`);

      element.prepend(this.schedulingIcon());
      return;
    }

    this.renderDates(element);
  }

  isEmpty():boolean {
    return false;
  }

  customPlaceholder(fallback:string):string {
    if (typeof this.context.options.placeholder === 'string') {
      return this.context.options.placeholder;
    }

    return fallback;
  }

  private get startDate():string|null {
    return this.resource.startDate as string|null;
  }

  private get dueDate():string|null {
    return this.resource.dueDate as string|null;
  }

  private renderSingleDate(field:'date'|'startDate'|'dueDate', element:HTMLElement):void {
    element.innerHTML = '';

    const dateElement = this.createDateDisplayField(field);

    element.appendChild(dateElement);
  }

  private renderDates(element:HTMLElement):void {
    element.innerHTML = '';

    const startDateElement = this.createDateDisplayField('startDate');
    const dueDateElement = this.createDateDisplayField('dueDate');

    const separator = document.createElement('span');
    separator.textContent = ' - ';

    element.appendChild(startDateElement);
    element.appendChild(separator);
    element.appendChild(dueDateElement);
  }

  private createDateDisplayField(date:'dueDate'|'startDate'|'date'):HTMLElement {
    const dateElement = document.createElement('span');
    const dateDisplayField = new DateDisplayField(date, this.context);
    dateDisplayField.apply(this.resource, this.schema);

    const text = this.resource[date]
      ? dateDisplayField.valueString
      : this.customPlaceholder(this.text.placeholder[date]);
    dateDisplayField.render(dateElement, text);

    return dateElement;
  }
}
