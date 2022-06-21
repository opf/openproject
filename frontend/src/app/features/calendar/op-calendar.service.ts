import {
  ElementRef,
  Injectable,
} from '@angular/core';
import { Subject } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WeekdayService } from 'core-app/core/days/weekday.service';

@Injectable()
export class OpCalendarService extends UntilDestroyedMixin {
  resize$ = new Subject<void>();

  resizeObs:ResizeObserver;

  weekdaysPromise = this.weekdayService.loadWeekdays().toPromise();

  constructor(
    readonly weekdayService:WeekdayService,
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

  async applyNonWorkingDay(data:{ date?:Date, el:HTMLElement }) {
    await this.weekdaysPromise;

    if (data.date && this.weekdayService.isNonWorkingDay(data.date)) {
      data.el.classList.add('fc-non-working-day');
    }
  }
}
