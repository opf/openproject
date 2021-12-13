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
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import dayGridPlugin from '@fullcalendar/daygrid';
import {
  CalendarOptions,
  EventInput,
} from '@fullcalendar/core';
import { debounceTime } from 'rxjs/operators';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  CalendarViewEvent,
  OpCalendarService,
} from 'core-app/features/calendar/op-calendar.service';

@Component({
  templateUrl: './wp-calendar.template.html',
  styleUrls: ['./wp-calendar.sass'],
  selector: 'wp-calendar',
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

  @Input() projectIdentifier:string;

  @Input() static = false;

  calendarOptions:CalendarOptions|undefined;

  private alreadyLoaded = false;

  constructor(
    readonly states:States,
    readonly $state:StateService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly wpListService:WorkPackagesListService,
    readonly querySpace:IsolatedQuerySpace,
    readonly wpListChecksumService:WorkPackagesListChecksumService,
    readonly schemaCache:SchemaCacheService,
    readonly titleService:OpTitleService,
    private element:ElementRef,
    readonly i18n:I18nService,
    readonly toastService:ToastService,
    private sanitizer:DomSanitizer,
    private configuration:ConfigurationService,
    readonly calendar:OpCalendarService,
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

    this.calendar.updateTimeframe(fetchInfo, this.projectIdentifier);
  }

  // eslint-disable-next-line @angular-eslint/use-lifecycle-interface
  ngOnDestroy():void {
    super.ngOnDestroy();
    this.calendar.resizeObs?.disconnect();
  }

  private initializeCalendar() {
    void this.configuration.initialized
      .then(() => {
        this.calendarOptions = this.calendar.calendarOptions({
          height: this.calendarHeight(),
          headerToolbar: this.buildHeader(),
          eventClick: this.toWPFullView.bind(this),
          events: this.calendarEventsFunction.bind(this),
          plugins: [dayGridPlugin],
          initialView: (() => {
            if (this.static) {
              return 'dayGridWeek';
            }
            return undefined;
          })(),
        });
      });
  }

  toWPFullView(event:CalendarViewEvent):void {
    const { workPackage } = event.event.extendedProps;

    if (event.el) {
      // do not display the tooltip on the wp show page
      this.calendar.removeTooltip(event.el);
    }

    // Ensure checksum is removed to allow queries to load
    this.wpListChecksumService.clear();

    // Ensure current calendar URL is pushed to history
    window.history.pushState({}, this.titleService.current, window.location.href);

    void this.$state.go(
      'work-packages.show',
      { workPackageId: workPackage.id },
      { inherit: false },
    );
  }

  private get calendarElement() {
    return jQuery(this.element.nativeElement).find('[data-qa-selector="op-wp-calendar"]');
  }

  private calendarHeight():number {
    if (this.static) {
      let heightElement = jQuery(this.element.nativeElement);

      while (!heightElement.height() && heightElement.parent()) {
        heightElement = heightElement.parent();
      }

      const topOfCalendar = jQuery(this.element.nativeElement).position().top;
      const topOfHeightElement = heightElement.position().top;

      return heightElement.height()! - (topOfCalendar - topOfHeightElement);
    }
    // -12 for the bottom padding
    return jQuery(window).height()! - this.calendarElement.offset()!.top - 12;
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

  private setCalendarsDate():void {
    const query = this.querySpace.query.value;
    if (!query) {
      return;
    }

    const datesIntervalFilter = _.find(query.filters || [], { id: 'datesInterval' }) as any;

    let calendarDate:any = null;
    let calendarUnit = 'dayGridMonth';

    if (datesIntervalFilter) {
      const lower = moment(datesIntervalFilter.values[0] as string);
      const upper = moment(datesIntervalFilter.values[1] as string);
      const diff = upper.diff(lower, 'days');

      calendarDate = lower.add(diff / 2, 'days');

      if (diff === 7) {
        calendarUnit = 'dayGridWeek';
      }
    }

    if (calendarDate) {
     this.ucCalendar.getApi().changeView(calendarUnit, calendarDate.toDate());
    } else {
     this.ucCalendar.getApi().changeView(calendarUnit);
    }
  }

  private setupWorkPackagesListener():void {
    this.calendar.workPackagesListener$(() => {
      this.alreadyLoaded = true;
      this.setCalendarsDate();
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
        end: exclusiveEnd,
        allDay: true,
        className: `__hl_background_type_${workPackage.type.id}`,
        workPackage,
      };
    });

    return events;
  }
}
