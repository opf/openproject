import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  OnInit,
  ViewEncapsulation,
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
import { TimeEntryChangeset } from 'core-app/features/work-packages/helpers/time-entries/time-entry-changeset';
import * as moment from 'moment';
import { TimeEntryEditService } from '../edit/edit.service';
import { HalResourceEditingService } from '../../fields/edit/services/hal-resource-editing.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

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
  timer:TimeEntryResource|null = null;

  elapsed$:Observable<string> = timer(0, 1000)
    .pipe(
      map(() => this.timer),
      filter((timeEntry) => timeEntry !== null),
      map((timeEntry:TimeEntryResource) => formatElapsedTime(timeEntry.createdAt as string)),
    );

  text = {
    tracking: this.I18n.t('js.time_entry.tracking'),
    stop: this.I18n.t('js.time_entry.stop'),
  };

  constructor(
    readonly elementRef:ElementRef<HTMLElement>,
    readonly timeEntryService:TimeEntryService,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly timeEntryEditService:TimeEntryEditService,
    readonly halEditing:HalResourceEditingService,
    readonly schemaCache:SchemaCacheService,
    readonly timezoneService:TimezoneService,
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

  public async stopTimer() {
    const active = this.timer;
    if (!active) {
      return;
    }

    await this.schemaCache.ensureLoaded(active);
    const change = new TimeEntryChangeset(active);
    const hours = moment().diff(moment(active.createdAt), 'hours', true);
    const formatted = this.timezoneService.toISODuration(hours, 'hours');
    change.setValue('hours', formatted);
    change.setValue('ongoing', false);

    // eslint-disable-next-line consistent-return
    return this
      .halEditing
      .save(change)
      .then((commit) => {
        this.timeEntryService.activeTimer$.next(null);
        this.cdRef.detectChanges();
        return this.timeEntryEditService.edit(commit.resource as TimeEntryResource);
      });
  }
}
