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

import {TimezoneService} from 'core-components/datetime/timezone.service';
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {HighlightableDisplayField} from "core-app/modules/fields/display/field-types/wp-display-highlightable-field.module";

export class DateDisplayField extends HighlightableDisplayField {
  private timezoneService = this.$injector.get(TimezoneService);

  public render(element:HTMLElement, displayText:string):void {
    super.render(element, displayText);

    // Highlight overdue tasks
    if (this.shouldHighlight && this.canOverdue) {
      const diff = this.timezoneService.daysFromToday(this.value);
      element.classList.add(Highlighting.overdueDate(diff));
    }
  }

  public get canOverdue():boolean {
    return ['dueDate', 'date'].indexOf(this.name) !== -1;
  }

  public get valueString() {
    if (this.value) {
      return this.timezoneService.formattedDate(this.value);
    } else {
      return '';
    }
  }
}
