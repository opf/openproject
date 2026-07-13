import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { DisplayedDays } from 'core-app/features/calendar/te-calendar/te-calendar.component';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

@Component({
  selector: 'op-time-entries-current-user-widget',
  templateUrl: './time-entries-current-user.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WidgetTimeEntriesCurrentUserComponent extends AbstractWidgetComponent implements OnInit {
  readonly timezone = inject(TimezoneService);
  readonly pathHelper = inject(PathHelperService);
  protected readonly cdr = inject(ChangeDetectorRef);

  public entries:TimeEntryResource[] = [];

  public displayedDays:DisplayedDays;

  public ngOnInit() {
    this.displayedDays = this.resource.options.days as DisplayedDays;
  }

  public updateEntries(entries:CollectionResource<TimeEntryResource>) {
    this.entries = entries.elements;

    this.cdr.detectChanges();
  }

  public get total() {
    const duration = this
      .entries
      .reduce((current, entry) => current + this.timezone.toHours(entry.hours), 0);

    if (duration > 0) {
      const amount = this.i18n.t('js.units.hour_string', { hours: duration.toFixed(2)});
      return this.i18n.t('js.label_total_amount', { amount });
    }
    return this.i18n.t('js.placeholders.default');
  }

  public get isEditable() {
    return false;
  }

  public updateConfiguration(options:{ days:DisplayedDays }) {
    this.resourceChanged.emit(this.setChangesetOptions(options));
    // Need to copy to trigger change detection
    this.displayedDays = [...options.days] as DisplayedDays;
  }

  protected formatNumber(value:number):string {
    return this.i18n.toNumber(value, { precision: 2 });
  }
}
