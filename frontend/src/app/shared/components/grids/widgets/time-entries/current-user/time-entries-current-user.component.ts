import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector,
} from '@angular/core';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { DisplayedDays } from 'core-app/features/calendar/te-calendar/te-calendar.component';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

@Component({
  templateUrl: './time-entries-current-user.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetTimeEntriesCurrentUserComponent extends AbstractWidgetComponent {
  public entries:TimeEntryResource[] = [];

  public displayedDays:DisplayedDays;

  constructor(protected readonly injector:Injector,
    readonly timezone:TimezoneService,
    readonly i18n:I18nService,
    readonly pathHelper:PathHelperService,
    protected readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  public ngOnInit() {
    this.displayedDays = this.resource.options.days as DisplayedDays;
  }

  public updateEntries(entries:CollectionResource<TimeEntryResource>) {
    this.entries = entries.elements;

    this.cdr.detectChanges();
  }

  public get total() {
    const duration = this.entries.reduce((current, entry) => current + this.timezone.toHours(entry.hours), 0);

    if (duration > 0) {
      return this.i18n.t('js.units.hour', { count: duration });
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
