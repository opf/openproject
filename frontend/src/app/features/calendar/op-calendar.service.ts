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
    const formatted = moment(date).format('YYYY-MM-DD');
    if (date && (this.weekdayService.isNonWorkingDay(date) || nonWorkingDays.find((el) => el.date === formatted))) {
      return ['fc-non-working-day'];
    }

    return [];
  }
}
