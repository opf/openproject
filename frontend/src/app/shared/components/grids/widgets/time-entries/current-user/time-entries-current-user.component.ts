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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { DisplayedDays } from 'core-app/features/calendar/te-calendar/te-calendar.component';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

@Component({
  selector: 'op-time-entries-current-user-widget',
  templateUrl: './time-entries-current-user.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WidgetTimeEntriesCurrentUserComponent extends AbstractWidgetComponent implements OnInit {
  readonly timezone = inject(TimezoneService);
  readonly pathHelper = inject(PathHelperService);
  protected readonly cdr = inject(ChangeDetectorRef);

  public entries:TimeEntryResource[] = [];

  public displayedDays:DisplayedDays;

  public ngOnInit() {
    this.displayedDays = this.resource.options.days as DisplayedDays;
  }

  public updateEntries(entries:CollectionResource<TimeEntryResource>) {
    this.entries = entries.elements;

    this.cdr.detectChanges();
  }

  public get total() {
    const duration = this
      .entries
      .reduce((current, entry) => current + this.timezone.toHours(entry.hours), 0);

    if (duration > 0) {
      const amount = this.i18n.t('js.units.hour_string', { hours: duration.toFixed(2)});
      return this.i18n.t('js.label_total_amount', { amount });
    }
    return this.i18n.t('js.placeholders.default');
  }

  public get isEditable() {
    return false;
  }

  public updateConfiguration(options:{ days:DisplayedDays }) {
    this.resourceChanged.emit(this.setChangesetOptions(options));
    // Need to copy to trigger change detection
    this.displayedDays = [...options.days] as DisplayedDays;
  }

  protected formatNumber(value:number):string {
    return this.i18n.toNumber(value, { precision: 2 });
  }
}
