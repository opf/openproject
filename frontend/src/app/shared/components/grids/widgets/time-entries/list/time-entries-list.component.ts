import { AfterViewInit, ChangeDetectorRef, Directive, Injector, OnDestroy, OnInit, inject } from '@angular/core';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { TimeEntryResource, formatTimeEntryEntityName } from 'core-app/features/hal/resources/time-entry-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { MeetingResource } from 'core-app/features/hal/resources/meeting-resource';

@Directive()
export abstract class WidgetTimeEntriesListComponent extends AbstractWidgetComponent implements OnInit, AfterViewInit, OnDestroy {
  readonly injector = inject(Injector);
  readonly timezone = inject(TimezoneService);
  readonly i18n = inject(I18nService);
  readonly pathHelper = inject(PathHelperService);
  readonly confirmDialog = inject(ConfirmDialogService);
  protected readonly cdr = inject(ChangeDetectorRef);

  public text = {
    edit: this.i18n.t('js.button_edit'),
    delete: this.i18n.t('js.button_delete'),
    confirmDelete: {
      text: this.i18n.t('js.modals.destroy_time_entry.text'),
      title: this.i18n.t('js.modals.destroy_time_entry.title'),
    },
    noResults: this.i18n.t('js.grid.widgets.time_entries_list.no_results'),
    placeholder: this.i18n.t('js.placeholders.default'),
  };

  public entries:TimeEntryResource[] = [];

  public schema:SchemaResource;

  private entriesLoaded = false;

  public rows:{ date:string, sum?:string, entry?:TimeEntryResource }[] = [];

  private closeDialogHandler:EventListener = this.handleDialogClose.bind(this);

  public readonly apiV3Service = inject(ApiV3Service);
  public readonly turboRequests = inject(TurboRequestsService);

  ngOnInit():void {
    this.loadTimeEntries();
  }

  ngAfterViewInit():void {
    document.addEventListener('dialog:close', this.closeDialogHandler);
  }

  ngOnDestroy():void {
    document.removeEventListener('dialog:close', this.closeDialogHandler);
  }

  public loadTimeEntries() {
    this
      .apiV3Service
      .time_entries
      .list({ filters: this.dmFilters(), pageSize: 500 })
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      .subscribe(async (collection) => {
        this.buildEntries(collection.elements);

        if (collection.count > 0) {
          this.schema = await firstValueFrom(this.loadSchema());
        }

        this.entriesLoaded = true;

        this.cdr.detectChanges();
      });
  }

  public get total():string {
    const duration = this.entries.reduce((current, entry) => current + this.timezone.toHours(entry.hours), 0);
    const amount = this.i18n.t('js.units.hour', { count: duration });
    return this.i18n.t('js.label_total_amount', { amount });
  }

  public get anyEntries():boolean {
    return !!this.entries.length;
  }

  public activityName(entry:TimeEntryResource):string {
    return entry.activity ? entry.activity.name : this.text.placeholder;
  }

  public projectName(entry:TimeEntryResource):string {
    return entry.project.name;
  }

  public entityName(entry:TimeEntryResource):string {
    return formatTimeEntryEntityName(entry.entity);
  }

  public entityId(entry:TimeEntryResource):string {
    return entry.entity.id!;
  }

  public comment(entry:TimeEntryResource):string | undefined {
    return entry.comment && entry.comment.raw;
  }

  public hours(entry:TimeEntryResource):string {
    return this.formatNumber(this.timezone.toHours(entry.hours));
  }

  public entityPath(entry:TimeEntryResource):string {
    if (entry.entity instanceof WorkPackageResource) {
      return this.pathHelper.workPackagePath(idFromLink(entry.entity.href));
    } if (entry.entity instanceof MeetingResource) {
      return this.pathHelper.meetingPath(idFromLink(entry.entity.href));
    }

    return '';
  }

  public get isEditable():boolean {
    return false;
  }

  public editTimeEntry(entry:TimeEntryResource):void {
    void this.turboRequests.request(
      `${this.pathHelper.timeEntryEditDialog(entry.id!)}`,
      { method: 'GET' },
    );
  }

  public deleteIfConfirmed(event:Event, entry:TimeEntryResource):void {
    event.preventDefault();
    this.confirmDialog.confirm({
      text: this.text.confirmDelete,
      closeByEscape: true,
      showClose: true,
      closeByDocument: true,
      passedData: [
        entry.entity ? this.entityName(entry) : '',
        `${this.i18n.t(
          'js.units.hour',
          { count: this.timezone.toHours(entry.hours) },
        )} (${entry.activity?.name})`,
      ],
      dangerHighlighting: true,
    }).then(() => {
      void entry.delete().then(() => {
        const newEntries = this.entries.filter((anEntry) => entry.id !== anEntry.id);

        this.buildEntries(newEntries);
      });
    })
      .catch(() => {
        // nothing
      });
  }

  protected abstract dmFilters():[string, FilterOperator, [string]][];

  private buildEntries(entries:TimeEntryResource[]) {
    this.entries = entries;
    const sumsByDateSpent:Record<string, number> = {};

    entries.forEach((entry) => {
      const date = entry.spentOn;

      if (!sumsByDateSpent[date]) {
        sumsByDateSpent[date] = 0;
      }

      sumsByDateSpent[date] += this.timezone.toHours(entry.hours);
    });

    const sortedEntries = entries.sort((a, b) => b.spentOn.localeCompare(a.spentOn));

    this.rows = [];
    let currentDate:string | null = null;
    sortedEntries.forEach((entry) => {
      if (entry.spentOn !== currentDate) {
        currentDate = entry.spentOn;
        this.rows.push({
          date: this.timezone.formattedDate(currentDate),
          sum: this.formatNumber(sumsByDateSpent[currentDate]),
        });
      }

      this.rows.push({ date: currentDate, entry });
    });
    // entries
  }

  protected formatNumber(value:number):string {
    return this.i18n.toNumber(value, { precision: 2 });
  }

  public get noEntries():boolean {
    return !this.entries.length && this.entriesLoaded;
  }

  private loadSchema():Observable<SchemaResource> {
    return this
      .apiV3Service
      .time_entries
      .schema
      .get();
  }

  private handleDialogClose(event:CustomEvent):void {
    const { detail: { dialog, submitted } } = event as { detail:{ dialog:HTMLDialogElement; submitted:boolean } };
    if (dialog.id === 'time-entry-dialog' && submitted) {
      this.loadTimeEntries();
    }
  }
}
