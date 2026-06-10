import { ElementRef, Injectable, inject } from '@angular/core';
import { Subject } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import moment from 'moment-timezone';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { DayHeaderContentArg } from '@fullcalendar/core';

@Injectable()
export class OpCalendarService extends UntilDestroyedMixin {
  readonly weekdayService = inject(WeekdayService);
  readonly dayService = inject(DayResourceService);
  readonly configurationService = inject(ConfigurationService);

  resize$ = new Subject<void>();

  resizeObs:ResizeObserver;

  resizeObserver(v:ElementRef|undefined):void {
    if (!v) {
      return;
    }

    if (!this.resizeObs) {
      this.resizeObs = new ResizeObserver(() => this.resize$.next());
    }

    this.resizeObs.observe(v.nativeElement as Element);
  }

  applyNonWorkingDay({ date }:{ date?:Date }, nonWorkingDays:IDay[]):string[] {
    const utcDate = moment(date).utc();
    const formatted = utcDate.format('YYYY-MM-DD');
    if (date && (this.weekdayService.isNonWorkingDay(utcDate) || nonWorkingDays.find((el) => el.date === formatted))) {
      return ['fc-non-working-day'];
    }
    return [];
  }

  dayHeaderContent(event:DayHeaderContentArg):string {
    // When the user did not configure a custom date format, we can always return the default content for the
    // fullcalendar day header.
    if (!this.configurationService.dateFormatPresent()) {
      return event.text;
    }

    // Additionally, we must use the default in dayGridMonth view, as it displays the day of the week:
    if (event.view.type === 'dayGridMonth') {
      return event.text;
    }

    // We are not in month grid view and there is a date format configured => return a formatted date according to
    // the settings. Prefix the day of the week name for better readability.
    const configuredDateFormat = this.configurationService.dateFormat();
    const formatWithoutYear = this.stripYearFromDateFormat(configuredDateFormat);
    const utcDate = moment(event.date).utc();

    return utcDate.format(`ddd ${formatWithoutYear}`);
  }

  stripYearFromDateFormat(format:string):string {
    return format.replace(/(\/|-|,?\s?)Y{3,4}$/, '').replace(/^Y{4}-/, '');
  }
}
