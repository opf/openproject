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

import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { HighlightableDisplayField } from 'core-app/shared/components/fields/display/field-types/highlightable-display-field.module';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import {
  toDOMString,
  opAutoDateIconData,
} from '@openproject/octicons-angular';

export class DateDisplayField extends HighlightableDisplayField {
  @LazyInject() timezoneService:TimezoneService;

  @LazyInject() apiV3Service:ApiV3Service;

  public render(element:HTMLElement, displayText:string):void {
    super.render(element, displayText);

    // Show scheduling mode in front of the start date field
    if (this.showSchedulingMode()) {
      element.prepend(this.schedulingIcon());
    }

    // Highlight overdue tasks
    if (this.shouldHighlight && this.canOverdue && !!this.resource.status) {
      const diff = this.timezoneService.daysFromToday(this.value);

      this
        .apiV3Service
        .statuses
        .id(this.resource.status.id)
        .get()
        .subscribe((status) => {
          if (!status.isClosed) {
            element.classList.add(Highlighting.overdueDate(diff));
          }
        });
    }
  }

  public get canOverdue():boolean {
    return ['dueDate', 'date'].includes(this.name);
  }

  public get valueString() {
    if (this.value) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      return this.timezoneService.formattedDate(this.value, this.context.options.dateFormat);
    }
    return '';
  }

  protected schedulingIcon():HTMLElement {
    const schedulingIcon = document.createElement('span');

    const autoDateIconString:string = toDOMString(
      opAutoDateIconData,
      'xsmall',
      { 'aria-hidden': 'true', class: 'display-field--scheduling-icon' },
    );

    schedulingIcon.innerHTML = autoDateIconString;
    return schedulingIcon;
  }

  private showSchedulingMode():boolean {
    return !this.resource.scheduleManually && (this.name === 'startDate' || this.name === 'date');
  }
}
