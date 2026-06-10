import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostBinding, Injector, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { TimeEntryTimerService } from 'core-app/shared/components/time_entries/services/time-entry-timer.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { firstValueFrom, Observable, switchMap, timer } from 'rxjs';
import { filter, map } from 'rxjs/operators';
import { formatElapsedTime } from 'core-app/features/work-packages/components/wp-timer-button/time-formatter.helper';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

export const timerAccountSelector = 'op-timer-account-menu';

@Component({
  selector: timerAccountSelector,
  templateUrl: './timer-account-menu.component.html',
  styleUrls: ['./timer-account-menu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class TimerAccountMenuComponent extends UntilDestroyedMixin implements OnInit {
  readonly injector = inject(Injector);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly timeEntryService = inject(TimeEntryTimerService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly I18n = inject(I18nService);
  readonly toastService = inject(ToastService);

  @HostBinding('class.op-timer-account-menu') className = true;
  readonly PathHelper = inject(PathHelperService);
  readonly TurboRequests = inject(TurboRequestsService);

  timer$ = this.timeEntryService.activeTimer$;

  elapsed$:Observable<string> = timer(0, 1000)
    .pipe(
      switchMap(() => this.timer$),
      filter((timeEntry) => timeEntry !== null),
      map((timeEntry:TimeEntryResource) => formatElapsedTime(timeEntry.createdAt as string)),
    );

  text = {
    tracking: this.I18n.t('js.time_entry.tracking'),
    stop: this.I18n.t('js.time_entry.stop'),
    timer_already_stopped: this.I18n.t('js.timer.timer_already_stopped'),
  };

  ngOnInit() {
    const parent = this.elementRef.nativeElement.parentElement!;
    parent.hidden = true;

    this.timer$
      .subscribe((active) => {
        parent.hidden = !active;
        this.cdRef.detectChanges();
      });
  }

  public async stopTimer():Promise<unknown> {
    const active = await firstValueFrom(this.timeEntryService.refresh());

    if (!active) {
      return this.toastService.addWarning(this.text.timer_already_stopped);
    }

    return this.TurboRequests.request(
      this.PathHelper.timeEntryEditDialog(active.id!),
      { method: 'GET' },
    );
  }
}
