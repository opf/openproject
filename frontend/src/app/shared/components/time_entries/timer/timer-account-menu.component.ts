import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { TimeEntryTimerService } from 'core-app/shared/components/time_entries/services/time-entry-timer.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import {
  firstValueFrom,
  Observable,
  switchMap,
  timer,
} from 'rxjs';
import {
  filter,
  map,
} from 'rxjs/operators';
import { formatElapsedTime } from 'core-app/features/work-packages/components/wp-timer-button/time-formatter.helper';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimeEntryEditService } from '../edit/edit.service';
import { HalResourceEditingService } from '../../fields/edit/services/hal-resource-editing.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

export const timerAccountSelector = 'op-timer-account-menu';

@Component({
  selector: timerAccountSelector,
  templateUrl: './timer-account-menu.component.html',
  styleUrls: ['./timer-account-menu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [TimeEntryEditService,
    HalResourceEditingService],
})
export class TimerAccountMenuComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-timer-account-menu') className = true;

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

  constructor(
    readonly elementRef:ElementRef<HTMLElement>,
    readonly timeEntryService:TimeEntryTimerService,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly timeEntryEditService:TimeEntryEditService,
    readonly halEditing:HalResourceEditingService,
    readonly schemaCache:SchemaCacheService,
    readonly timezoneService:TimezoneService,
    readonly toastService:ToastService,
  ) {
    super();
  }

  ngOnInit() {
    const parent = this.elementRef.nativeElement.parentElement as HTMLElement;
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

    return this.timeEntryEditService.stopTimerAndEdit(active);
  }
}
