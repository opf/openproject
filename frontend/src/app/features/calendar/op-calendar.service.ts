import {
  ElementRef,
  Injectable,
} from '@angular/core';
import { Subject } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';

@Injectable()
export class OpCalendarService extends UntilDestroyedMixin {
  resize$ = new Subject<void>();

  resizeObs:ResizeObserver;

  constructor(
    readonly weekdayService:WeekdayService,
    readonly dayService:DayResourceService,
  ) {
    super();
  }

  resizeObserver(v:ElementRef|undefined):void {
    if (!v) {
      return;
    }

    if (!this.resizeObs) {
      this.resizeObs = new ResizeObserver(() => this.resize$.next());
    }

    this.resizeObs.observe(v.nativeElement);
  }

  applyNonWorkingDay({ date }:{ date?:Date }, nonWorkingDays:IDay[]):string[] {
    if (date) {
      // we need to find the UTC date for each date while highlighting non-wrking days on full-calendar
      const utcDate = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds(), date.getUTCMilliseconds());
      const formatted = moment(utcDate).format('YYYY-MM-DD');
      if (this.weekdayService.isNonWorkingDay(utcDate) || nonWorkingDays.find((el) => el.date === formatted)) {
        return ['fc-non-working-day'];
      }
    }
    return [];
  }
}
