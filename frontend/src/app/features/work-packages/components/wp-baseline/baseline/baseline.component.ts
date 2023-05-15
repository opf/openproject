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
  Component,
  EventEmitter,
  HostBinding,
  Input,
  OnInit,
  Output,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { Observable } from 'rxjs';
import {
  DEFAULT_TIMESTAMP,
  WorkPackageViewBaselineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { baselineFilterFromValue } from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';

@Component({
  selector: 'op-baseline',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './baseline.component.html',
  styleUrls: ['./baseline.component.sass'],
})
export class OpBaselineComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-baseline') className = true;

  @Output() submitted = new EventEmitter<void>();

  @Input() showActionBar? = false;

  @Input() visible = true;

  public dropDownDescription = '';

  public nonWorkingDays$:Observable<IDay[]> = this.wpTableBaseline.nonWorkingDays$;

  public selectedDates:string[];

  public selectedTimes:string[];

  public selectedFilter:string|null;

  public selectedTimezoneFormattedTime:string[];

  public daysNumber = 0;

  public tooltipPosition = SpotDropAlignmentOption.TopRight;

  public text = {
    toggle_title: this.I18n.t('js.baseline.toggle_title'),
    drop_down_none_option: this.I18n.t('js.baseline.drop_down.none'),
    header_description: this.I18n.t('js.baseline.header_description'),
    clear: this.I18n.t('js.baseline.clear'),
    apply: this.I18n.t('js.baseline.apply'),
    show_changes_since: this.I18n.t('js.baseline.show_changes_since'),
    from: this.I18n.t('js.baseline.from'),
    to: this.I18n.t('js.baseline.to'),
    date: this.I18n.t('js.label_date'),
    time: this.I18n.t('js.baseline.time'),
    help_description: this.I18n.t('js.baseline.help_description'),
    timeZone: this.configuration.isTimezoneSet() ? moment().tz(this.configuration.timezone()).zoneAbbr() : 'local',
    time_description: (i:number) => this.I18n.t('js.baseline.time_description', {
      time: this.selectedTimezoneFormattedTime[i],
      days: this.daysNumber,
    }),
  };

  public baselineAvailableValues = [
    {
      value: 'oneDayAgo',
      title: this.I18n.t('js.baseline.drop_down.yesterday'),
    },
    {
      value: 'lastWorkingDay',
      title: this.I18n.t('js.baseline.drop_down.last_working_day'),
    },
    {
      value: 'oneWeekAgo',
      title: this.I18n.t('js.baseline.drop_down.last_week'),
    },
    {
      value: 'oneMonthAgo',
      title: this.I18n.t('js.baseline.drop_down.last_month'),
    },
    {
      value: 'aSpecificDate',
      title: this.I18n.t('js.baseline.drop_down.a_specific_date'),
    },
    {
      value: 'betweenTwoSpecificDates',
      title: this.I18n.t('js.baseline.drop_down.between_two_specific_dates'),
    },
  ];

  constructor(
    readonly I18n:I18nService,
    readonly wpTableBaseline:WorkPackageViewBaselineService,
    readonly halResourceService:HalResourceService,
    readonly weekdaysService:WeekdayService,
    readonly daysService:DayResourceService,
    readonly timezoneService:TimezoneService,
    readonly configuration:ConfigurationService,
  ) {
    super();
  }

  public ngOnInit():void {
    this.resetSelection();

    if (this.wpTableBaseline.isActive()) {
      this.filterChange(baselineFilterFromValue(this.wpTableBaseline.current));

      this.wpTableBaseline.current.forEach((value, i) => {

        if (value.includes('@')) {
          const [, timeWithZone] = value.split(/[@]/);
          const time = timeWithZone.split(/[+-]/)[0];
          this.selectedTimes[i] = time || '00:00';
          this.selectedTimezoneFormattedTime[i] = timeWithZone || '00:00+00:00';
        } else if (value !== 'PT0S') {
          const date = moment(value);
          this.selectedDates[i] = date.format('YYYY-MM-DD');
          this.selectedTimes[i] = date.format('HH:MM');
          this.selectedTimezoneFormattedTime[i] = date.format('HH:MMZ');
        }
      });
    }
  }

  public resetSelection():void {
    this.selectedTimes = ['00:00', '00:00'];
    this.selectedTimezoneFormattedTime = this.selectedTimes.map((time) => `${time}+00:00`);
    this.selectedDates = ['', ''];
    this.selectedFilter = null;
    this.dropDownDescription = '';
  }

  public onSubmit(e:Event):void {
    e.preventDefault();
    this.onSave();
  }

  public onSave() {
    this.wpTableBaseline.update(this.buildBaselineFilter());
    this.submitted.emit();
  }

  public timesChange(value:string[]):void {
    this.selectedTimes = value;
    this.selectedTimezoneFormattedTime = this.selectedDates
      .map((el:string, i:number) => {
        const dateTime = `${el}  ${value[i]}`;
        return this.timezoneService.formattedTime(dateTime, 'HH:mmZ');
      });
  }

  public dateChange(values:string[]):void {
    if (_.every(values, validDate)) {
      this.selectedDates = values;
    }
  }

  public filterChange(value:string|null):void {
    this.selectedFilter = value;
    switch (value) {
      case 'oneDayAgo':
        [this.dropDownDescription, this.daysNumber] = this.wpTableBaseline.yesterdayDate();
        break;
      case 'lastWorkingDay':
        [this.dropDownDescription, this.daysNumber] = this.wpTableBaseline.lastWorkingDate();
        break;
      case 'oneWeekAgo':
        [this.dropDownDescription, this.daysNumber] = this.wpTableBaseline.lastweekDate();
        break;
      case 'oneMonthAgo':
        [this.dropDownDescription, this.daysNumber] = this.wpTableBaseline.lastMonthDate();
        break;
      default:
        this.dropDownDescription = '';
        this.daysNumber = 0;
        break;
    }
  }



  private buildBaselineFilter():string[] {
    switch (this.selectedFilter) {
      case 'oneDayAgo':
      case 'oneWeekAgo':
      case 'oneMonthAgo':
      case 'lastWorkingDay':
        return [`${this.selectedFilter}@${this.selectedTimezoneFormattedTime[0]}`, DEFAULT_TIMESTAMP];
      case 'aSpecificDate':
        return [`${this.selectedDates[0]}T${this.selectedTimezoneFormattedTime[0]}`, DEFAULT_TIMESTAMP];
      case 'betweenTwoSpecificDates':
        return [
          `${this.selectedDates[0]}T${this.selectedTimezoneFormattedTime[0]}`,
          `${this.selectedDates[1]}T${this.selectedTimezoneFormattedTime[1]}`,
        ];
      default:
        return [DEFAULT_TIMESTAMP];
    }
  }
}
