import {
  Component,
  ElementRef,
  Input,
  OnInit,
  ViewChild,
} from '@angular/core';
import {
  FullCalendarComponent,
  ToolbarInput,
} from '@fullcalendar/angular';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import * as moment from 'moment';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { StateService } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { DomSanitizer } from '@angular/platform-browser';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import dayGridPlugin from '@fullcalendar/daygrid';
import {
  CalendarOptions,
  DateSelectArg,
  EventDropArg,
  EventInput,
} from '@fullcalendar/core';
import { debounceTime } from 'rxjs/operators';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { Subject } from 'rxjs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import interactionPlugin, { EventResizeDoneArg } from '@fullcalendar/interaction';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';

@Component({
  templateUrl: './wp-calendar.template.html',
  styleUrls: ['./wp-calendar.sass'],
  selector: 'op-wp-calendar',
  providers: [
    OpCalendarService,
  ],
})
export class WorkPackagesCalendarComponent extends UntilDestroyedMixin implements OnInit {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('ucCalendar', { read: ElementRef })
  set ucCalendarElement(v:ElementRef|undefined) {
    this.calendar.resizeObserver(v);
  }

  @Input() static = false;

  calendarOptions$ = new Subject<CalendarOptions>();

  private alreadyLoaded = false;

  constructor(
    readonly states:States,
    readonly $state:StateService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly wpListService:WorkPackagesListService,
    readonly querySpace:IsolatedQuerySpace,
    readonly schemaCache:SchemaCacheService,
    readonly titleService:OpTitleService,
    private element:ElementRef,
    readonly i18n:I18nService,
    readonly toastService:ToastService,
    private sanitizer:DomSanitizer,
    private configuration:ConfigurationService,
    readonly calendar:OpCalendarService,
    readonly currentProject:CurrentProjectService,
    readonly halEditing:HalResourceEditingService,
    readonly halNotification:HalResourceNotificationService,
  ) {
    super();
  }

  ngOnInit():void {
    this.calendar.resize$
      .pipe(
        this.untilDestroyed(),
        debounceTime(50),
      )
      .subscribe(() => {
        this.ucCalendar.getApi().updateSize();
      });

    // Clear any old subscribers
    this.querySpace.stopAllSubscriptions.next();

    this.setupWorkPackagesListener();
    this.initializeCalendar();
  }

  public calendarEventsFunction(fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void):void|PromiseLike<EventInput[]> {
    if (this.alreadyLoaded) {
      this.alreadyLoaded = false;
      const events = this.updateResults(this.querySpace.results.value!);
      successCallback(events);
    } else {
      this
        .calendar
        .currentWorkPackages$
        .subscribe((collection:WorkPackageCollectionResource) => {
          const events = this.updateResults((collection));
          successCallback(events);
        });
    }

    void this.calendar.updateTimeframe(fetchInfo, this.currentProject.identifier || undefined);
  }

  // eslint-disable-next-line @angular-eslint/use-lifecycle-interface
  ngOnDestroy():void {
    super.ngOnDestroy();
    this.calendar.resizeObs?.disconnect();
  }

  private initializeCalendar() {
    const additionalOptions:{ [key:string]:unknown } = {
      height: '100%',
      headerToolbar: this.buildHeader(),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      events: this.calendarEventsFunction.bind(this),
      plugins: [
        dayGridPlugin,
        interactionPlugin,
      ],
      // DnD configuration
      selectable: true,
      select: this.handleDateClicked.bind(this) as unknown,
      eventResizableFromStart: true,
      editable: true,
      eventResize: (resizeInfo:EventResizeDoneArg) => this.updateEvent(resizeInfo),
      eventDrop: (dropInfo:EventDropArg) => this.updateEvent(dropInfo),
    };

    if (this.static) {
      additionalOptions.initialView = 'dayGridWeek';
    }

    void this.configuration.initialized
      .then(() => {
        this.calendarOptions$.next(
          this.calendar.calendarOptions(additionalOptions),
        );
      });
  }

  public buildHeader():false|ToolbarInput|undefined {
    if (this.static) {
      return false;
    }
    return {
      right: 'dayGridMonth,dayGridWeek',
      center: 'title',
      left: 'prev,next today',
    };
  }

  private setupWorkPackagesListener():void {
    this.calendar.workPackagesListener$(() => {
      this.alreadyLoaded = true;
      this.ucCalendar.getApi().refetchEvents();
    });
  }

  private updateResults(collection:WorkPackageCollectionResource) {
    this.calendar.warnOnTooManyResults(collection, this.static);
    return this.mapToCalendarEvents(collection.elements);
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]) {
    const events = workPackages.map((workPackage:WorkPackageResource) => {
      const startDate = this.calendar.eventDate(workPackage, 'start');
      const endDate = this.calendar.eventDate(workPackage, 'due');

      const exclusiveEnd = moment(endDate).add(1, 'days').format('YYYY-MM-DD');

      return {
        title: workPackage.subject,
        start: startDate,
        editable: this.calendar.eventDurationEditable(workPackage),
        end: exclusiveEnd,
        allDay: true,
        className: `__hl_background_type_${workPackage.type.id}`,
        workPackage,
      };
    });

    return events;
  }

  private get initialView():string|undefined {
    return this.static ? 'dayGridWeek' : undefined;
  }

  private async updateEvent(info:EventResizeDoneArg|EventDropArg):Promise<void> {
    const changeset = this.calendar.updateDates(info);

    try {
      const result = await this.halEditing.save(changeset);
      this.halNotification.showSave(result.resource, result.wasNew);
    } catch (e) {
      this.halNotification.handleRawError(e, changeset.projectedResource);
      info.revert();
    }
  }

  private handleDateClicked(info:DateSelectArg) {
    const defaults = {
      startDate: info.startStr,
      dueDate: this.calendar.getEndDateFromTimestamp(info.end),
    };

    void this.$state.go(
      splitViewRoute(this.$state, 'new'),
      {
        defaults,
        tabIdentifier: 'overview',
      },
    );
  }
}
