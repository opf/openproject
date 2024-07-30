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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  HostBinding,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  baselineFilterFromValue,
  getPartsFromTimestamp,
  getBaselineState,
  offsetToUtcString,
} from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import * as moment from 'moment-timezone';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { Moment } from 'moment';
import { filter } from 'rxjs/operators';

@Component({
  templateUrl: './baseline-legends.component.html',
  styleUrls: ['./baseline-legends.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-baseline-legends',
  encapsulation: ViewEncapsulation.None,
})
export class OpBaselineLegendsComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-baseline-legends') className = true;

  public numAdded = 0;

  public numRemoved = 0;

  public numUpdated = 0;

  public offset:string|null;

  public userOffset:string;

  public userTimezone:string;

  public localDate:string;

  public legendDescription:string;

  public text = {
    now_meets_filter_criteria: this.I18n.t('js.baseline.legends.now_meets_filter_criteria'),
    no_longer_meets_filter_criteria: this.I18n.t('js.baseline.legends.no_longer_meets_filter_criteria'),
    maintained_with_changes: this.I18n.t('js.baseline.legends.maintained_with_changes'),
    in_your_timezone: this.I18n.t('js.baseline.legends.in_your_timezone'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly wpTableBaseline:WorkPackageViewBaselineService,
    readonly querySpace:IsolatedQuerySpace,
    readonly schemaCache:SchemaCacheService,
    readonly timezoneService:TimezoneService,
    readonly configuration:ConfigurationService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  ngOnInit() {
    this
      .wpTableBaseline
      .live$()
      .pipe(
        this.untilDestroyed(),
        filter(() => this.wpTableBaseline.isActive()),
      )
      .subscribe((timestamps) => {
        this.userTimezone = this.timezoneService.userTimezone();
        this.userOffset = moment.tz(this.userTimezone).format('Z');

        const parts = getPartsFromTimestamp(timestamps[0]);
        if (parts) {
          this.offset = parts.offset;
        }

        this.getBaselineDetails();
        this.getFilterName(timestamps);
        this.cdRef.detectChanges();
      });
  }

  public getFilterName(timestamps:string[]) {
    const datesAndTimes = timestamps.map((el) => el.split(/[@T]/));
    const baselineValue = baselineFilterFromValue(this.wpTableBaseline.current);
    const changesSinceOrBetween = this.deriveChangesSinceOrBetween(baselineValue);
    let description = '';
    let upstreamDate = '';
    let localDate = '';

    switch (baselineValue) {
      case 'oneDayAgo':
        [upstreamDate, localDate] = this.deriveSingleDate(this.wpTableBaseline.yesterdayDate(), datesAndTimes[0][1]);
        description = this.I18n.t('js.baseline.drop_down.yesterday');
        description += ` (${upstreamDate})`;
        break;
      case 'lastWorkingDay':
        [upstreamDate, localDate] = this.deriveSingleDate(this.wpTableBaseline.lastWorkingDate(), datesAndTimes[0][1]);
        description = this.I18n.t('js.baseline.drop_down.last_working_day');
        description += ` (${upstreamDate})`;
        break;
      case 'oneWeekAgo':
        [upstreamDate, localDate] = this.deriveSingleDate(this.wpTableBaseline.lastweekDate(), datesAndTimes[0][1]);
        description = this.I18n.t('js.baseline.drop_down.last_week');
        description += ` (${upstreamDate})`;
        break;
      case 'oneMonthAgo':
        [upstreamDate, localDate] = this.deriveSingleDate(this.wpTableBaseline.lastMonthDate(), datesAndTimes[0][1]);
        description = this.I18n.t('js.baseline.drop_down.last_month');
        description += ` (${upstreamDate})`;
        break;
      case 'aSpecificDate':
        [upstreamDate, localDate] = this.formatUpstreamAndLocal(moment.parseZone(timestamps[0]));
        description += upstreamDate;
        break;
      case 'betweenTwoSpecificDates':
        [upstreamDate, localDate] = this.deriveDateRange(moment.parseZone(timestamps[0]), moment.parseZone(timestamps[1]));
        description += upstreamDate;
        break;
      default:
        break;
    }
    description = `${changesSinceOrBetween} ${description}`;
    this.legendDescription = description;
    this.localDate = localDate;
    return description;
  }

  private deriveChangesSinceOrBetween(baselineValue:string|null) {
    if (baselineValue === 'betweenTwoSpecificDates') {
      return this.I18n.t('js.baseline.legends.changes_between');
    }

    return this.I18n.t('js.baseline.legends.changes_since');
  }

  private deriveSingleDate(date:string, timestamp:string):[string, string] {
    const parsedDate:Moment = moment.parseZone(`${date}T${timestamp}`);
    return this.formatUpstreamAndLocal(parsedDate);
  }

  private deriveDateRange(start:Moment, end:Moment):[string, string] {
    const startRange = this.formatUpstreamAndLocal(start);
    const endRange = this.formatUpstreamAndLocal(end);

    return [
      `${startRange[0]} ${this.I18n.t('js.label_and')} ${endRange[0]}`,
      `${startRange[1]} - ${endRange[1]}`,
    ];
  }

  private formatUpstreamAndLocal(date:Moment):[string, string] {
    return [
      this.formatDate(date),
      this.formatDate(date.tz(this.userTimezone)),
    ];
  }

  public getBaselineDetails() {
    this.numAdded = 0;
    this.numRemoved = 0;
    this.numUpdated = 0;
    let state = '';
    const baselineIsActive= this.wpTableBaseline.isActive();
    const results = this.querySpace.results.value;
    if (baselineIsActive && results && results.elements.length > 0) {
      results.elements.forEach((workPackage:WorkPackageResource) => {
        state = getBaselineState(workPackage, this.schemaCache);
        if (state === 'added') {
          this.numAdded += 1;
        } else if (state === 'removed') {
          this.numRemoved += 1;
        } else if (state === 'updated') {
          this.numUpdated += 1;
        }
      });
      this.text.maintained_with_changes = `${this.I18n.t('js.baseline.legends.maintained_with_changes')} (${this.numUpdated})`;
      this.text.no_longer_meets_filter_criteria = `${this.I18n.t('js.baseline.legends.no_longer_meets_filter_criteria')} (${this.numRemoved})`;
      this.text.now_meets_filter_criteria = `${this.I18n.t('js.baseline.legends.now_meets_filter_criteria')} (${this.numAdded})`;
    }
  }

  private formatDate(date:Moment):string {
    const formattedDate = date.format(this.timezoneService.getDateFormat());
    const formattedTime = date.format(this.timezoneService.getTimeFormat());
    const offset = offsetToUtcString(date.format('Z'));

    return `${formattedDate} ${formattedTime} ${offset}`;
  }
}
