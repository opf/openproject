import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { TimeEntryService } from 'core-app/shared/components/time_entries/services/time_entry.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import {
  Observable,
  timer,
} from 'rxjs';
import {
  filter,
  map,
} from 'rxjs/operators';
import { formatElapsedTime } from 'core-app/features/work-packages/components/wp-timer-button/time-formatter.helper';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';

export const timerAccountSelector = 'op-timer-account-menu';

@Component({
  selector: timerAccountSelector,
  templateUrl: './timer-account-menu.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    TimeEntryEditService,
    TimeEntryService,
  ]
})
export class TimerAccountMenuComponent extends UntilDestroyedMixin implements OnInit {
  timer:TimeEntryResource|null = null;

  elapsed$:Observable<string> = timer(0, 1000)
    .pipe(
      map(() => this.timer),
      filter((timeEntry) => timeEntry !== null),
      map((timeEntry:TimeEntryResource) => formatElapsedTime(timeEntry.createdAt as string)),
    );

  text = {
    tracking: this.I18n.t('js.time_entry.tracking'),
  };

  constructor(
    readonly elementRef:ElementRef<HTMLElement>,
    readonly timeEntryService:TimeEntryService,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) {
    super();
  }

  ngOnInit() {
    const parent = this.elementRef.nativeElement.parentElement as HTMLElement;
    parent.hidden = true;

    this
      .timeEntryService
      .activeTimer$
      .subscribe((active) => {
        this.timer = active;
        parent.hidden = !active;

        this.cdRef.detectChanges();
      });
  }
}
