// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  HostBinding,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { IWorkPackageTimestamp } from 'core-app/features/hal/resources/work-package-timestamp-resource';
import { ISchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { baselineFilterFromValue } from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import * as moment from 'moment-timezone';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Component({
  templateUrl: './baseline-legends.component.html',
  styleUrls: ['./baseline-legends.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-baseline-legends',
  encapsulation: ViewEncapsulation.None,
})
export class OpBaselineLegendsComponent {
  @HostBinding('class.op-baseline-legends') className = true;

  public numAdded = 0;

  public numRemoved = 0;

  public numUpdated = 0;

  public text = {
    time_description: '',
    now_meets_filter_criteria: this.I18n.t('js.baseline.legends.now_meets_filter_criteria'),
    no_longer_meets_filter_criteria: this.I18n.t('js.baseline.legends.no_longer_meets_filter_criteria'),
    maintained_with_changes: this.I18n.t('js.baseline.legends.maintained_with_changes'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly wpTableBaseline:WorkPackageViewBaselineService,
    readonly querySpace:IsolatedQuerySpace,
    readonly schemaCache:SchemaCacheService,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly timezoneService:TimezoneService,
    readonly configuration:ConfigurationService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    this.getBaselineDetails();
    this.getFilterName();
  }

  public getFilterName() {
    const timestamps = this.wpTableBaseline.current.map((el) => el.split(/[@T]/));
    const filter = baselineFilterFromValue(this.wpTableBaseline.current);
    const changesSince = this.I18n.t('js.baseline.legends.changes_since');
    let dateTime = '';

    switch (filter) {
      case 'oneDayAgo':
        dateTime = this.I18n.t('js.baseline.drop_down.yesterday');
        dateTime += ` (${this.getFormattedDate(this.wpTableBaseline.yesterdayDate(), timestamps[0][1])})`;
        break;
      case 'lastWorkingDay':
        dateTime = this.I18n.t('js.baseline.drop_down.last_working_day');
        dateTime += ` (${this.getFormattedDate(this.wpTableBaseline.lastWorkingDate(), timestamps[0][1])})`;
        break;
      case 'oneWeekAgo':
        dateTime = this.I18n.t('js.baseline.drop_down.last_week');
        dateTime += ` (${this.getFormattedDate(this.wpTableBaseline.lastweekDate(), timestamps[0][1])})`;
        break;
      case 'oneMonthAgo':
        dateTime = this.I18n.t('js.baseline.drop_down.last_month');
        dateTime += ` (${this.getFormattedDate(this.wpTableBaseline.lastMonthDate(), timestamps[0][1])})`;
        break;
      case 'aSpecificDate':
        dateTime = this.I18n.t('js.baseline.drop_down.a_specific_date');
        dateTime += ` (${this.getFormattedDate(timestamps[0][0], timestamps[0][1])})`;
        break;
      case 'betweenTwoSpecificDates':
        dateTime = this.I18n.t('js.baseline.drop_down.between_two_specific_dates');
        dateTime += ` (${this.getFormattedDate(timestamps[0][0], timestamps[0][1])} - ${this.getFormattedDate(timestamps[1][0], timestamps[1][1])})`;
        break;
      default:
        dateTime = '';
        break;
    }
    dateTime = `${changesSince} ${dateTime}`;
    this.text.time_description = dateTime;
    return dateTime;
  }

  public getBaselineDetails() {
    this.numAdded = 0;
    this.numRemoved = 0;
    this.numUpdated = 0;
    const results = this.querySpace.results.value;
    if (results && results.elements.length > 0) {
      results.elements.forEach((workPackage:WorkPackageResource) => {
        const schema = this.schemaCache.of(workPackage);
        const timestamps = workPackage.attributesByTimestamp || [];
        if (timestamps.length > 1) {
          const base = timestamps[0];
          const compare = timestamps[1];
          if ((!base._meta.exists && compare._meta.exists) || (!base._meta.matchesFilters && compare._meta.matchesFilters)) {
            this.numAdded += 1;
          } else if ((base._meta.exists && !compare._meta.exists) || (base._meta.matchesFilters && !compare._meta.matchesFilters)) {
            this.numRemoved += 1;
          } else if (this.visibleAttributeChanged(base, schema)) {
            this.numUpdated += 1;
          }
        }
      });
      this.text.maintained_with_changes = `${this.I18n.t('js.baseline.legends.maintained_with_changes')} (${this.numUpdated})`;
      this.text.no_longer_meets_filter_criteria = `${this.I18n.t('js.baseline.legends.no_longer_meets_filter_criteria')} (${this.numRemoved})`;
      this.text.now_meets_filter_criteria = `${this.I18n.t('js.baseline.legends.now_meets_filter_criteria')} (${this.numAdded})`;
    }
  }

  private getFormattedDate(date:string, time:string):string {
    const combined = moment
      .tz(`${date}T${time}`, this.configuration.defaultTimezone())
      .tz(this.configuration.timezone());

    return `${combined.format(this.timezoneService.getDateFormat())} ${combined.format(this.timezoneService.getTimeFormat())}`;
  }

  private visibleAttributeChanged(base:IWorkPackageTimestamp, schema:ISchemaProxy):boolean {
    return !!this
      .wpTableColumns
      .getColumns()
      .find((column) => {
        const name = schema.mappedName(column.id);
        return Object.prototype.hasOwnProperty.call(base, name) || Object.prototype.hasOwnProperty.call(base.$links, name);
      });
  }

  public refresh() {
    this.getBaselineDetails();
    this.getFilterName();
    this.cdRef.detectChanges();
  }
}
