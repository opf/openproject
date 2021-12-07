import {
  ElementRef,
  Injectable,
  SecurityContext,
} from '@angular/core';
import {
  CalendarOptions,
  EventApi,
} from '@fullcalendar/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { DomSanitizer } from '@angular/platform-browser';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { EventClickArg } from '@fullcalendar/common';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { StateService } from '@uirouter/angular';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  Observable,
  Subject,
} from 'rxjs';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { take } from 'rxjs/operators';

export interface CalendarViewEvent {
  el:HTMLElement;
  event:EventApi;
}

@Injectable()
export class OpCalendarService extends UntilDestroyedMixin {
  static MAX_DISPLAYED = 100;

  resize$ = new Subject<void>();

  resizeObs:ResizeObserver;

  tooManyResultsText:string|null;

  currentWorkPackages$:Observable<WorkPackageCollectionResource> = this
    .querySpace
    .results
    .values$()
    .pipe(
      take(1),
    );

  constructor(
    private I18n:I18nService,
    private configuration:ConfigurationService,
    private sanitizer:DomSanitizer,
    readonly schemaCache:SchemaCacheService,
    private $state:StateService,
    readonly toastService:ToastService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly wpListService:WorkPackagesListService,
    readonly querySpace:IsolatedQuerySpace,
  ) {
    super();
  }

  workPackagesListener$(callbackFn:() => void):void {
    this
      .querySpace
      .results
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => {
        callbackFn();
      });
  }

  calendarOptions(additionalOptions:CalendarOptions):CalendarOptions {
    return { ...this.defaultOptions(), ...additionalOptions };
  }

  addTooltip(event:CalendarViewEvent):void {
    jQuery(event.el).tooltip({
      content: this.tooltipContentString(event.event.extendedProps.workPackage),
      items: '.fc-event',
      close() {
        jQuery('.ui-helper-hidden-accessible').remove();
      },
      track: true,
    });
  }

  removeTooltip(element:HTMLElement):void {
    // deactivate tooltip so that it is not displayed on the wp show page
    jQuery(element).tooltip({
      close() {
        jQuery('.ui-helper-hidden-accessible').remove();
      },
      disabled: true,
    });
  }

  eventDate(workPackage:WorkPackageResource, type:'start'|'due'):string {
    if (this.schemaCache.of(workPackage).isMilestone) {
      return workPackage.date;
    }
    return workPackage[`${type}Date`];
  }

  warnOnTooManyResults(collection:WorkPackageCollectionResource, isStatic = false):void {
    if (collection.count < collection.total) {
      this.tooManyResultsText = this.I18n.t('js.calendar.too_many',
        {
          count: collection.total,
          max: OpCalendarService.MAX_DISPLAYED,
        });
    } else {
      this.tooManyResultsText = null;
    }

    if (this.tooManyResultsText && !isStatic) {
      this.toastService.addNotice(this.tooManyResultsText);
    }
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

  updateTimeframe(fetchInfo:{ start:Date, end:Date, timeZone:string }, projectIdentifier:string|undefined):void {
    const filtersEmpty = this.wpTableFilters.isEmpty;

    if (filtersEmpty && this.querySpace.query.value) {
      // nothing to do
      return;
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    if (filtersEmpty) {
      let queryProps = OpCalendarService.defaultQueryProps(startDate, endDate);

      if (this.$state.params.query_props) {
        queryProps = decodeURIComponent(this.$state.params.query_props || '');
      }

      void this
        .wpListService
        .fromQueryParams({ query_props: queryProps }, projectIdentifier || undefined)
        .toPromise();
    } else {
      this.wpTableFilters.modify('datesInterval', (datesIntervalFilter) => {
        // eslint-disable-next-line no-param-reassign
        datesIntervalFilter.values[0] = startDate;
        // eslint-disable-next-line no-param-reassign
        datesIntervalFilter.values[1] = endDate;
      });
    }
  }

  private defaultOptions():CalendarOptions {
    return {
      editable: false,
      locale: this.I18n.locale,
      fixedWeekCount: false,
      firstDay: this.configuration.startOfWeek(),
      timeZone: this.configuration.isTimezoneSet() ? this.configuration.timezone() : 'local',
      height: 'auto',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: '',
      },
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      eventClick: this.openSplitView.bind(this),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      eventDidMount: this.addTooltip.bind(this),
    };
  }

  private openSplitView(event:EventClickArg) {
    const workPackage = event.event.extendedProps.workPackage as WorkPackageResource;

    void this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: workPackage.id, tabIdentifier: 'overview' },
    );
  }

  private sanitizedValue(workPackage:WorkPackageResource, attribute:string, toStringMethod:string|null = 'name'):string {
    let value = workPackage[attribute];
    value = toStringMethod && value ? value[toStringMethod] : value;
    value = value || this.I18n.t('js.placeholders.default');

    return this.sanitizer.sanitize(SecurityContext.HTML, value) || '';
  }

  private tooltipContentString(workPackage:WorkPackageResource) {
    return `
        ${this.sanitizedValue(workPackage, 'type')} #${workPackage.id}: ${this.sanitizedValue(workPackage, 'subject', null)}
        <ul class="tooltip--map">
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.I18n.t('js.work_packages.properties.projectName')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'project')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.I18n.t('js.work_packages.properties.status')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'status')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.I18n.t('js.work_packages.properties.startDate')}:</span>
            <span class="tooltip--map--value">${this.eventDate(workPackage, 'start')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.I18n.t('js.work_packages.properties.dueDate')}:</span>
            <span class="tooltip--map--value">${this.eventDate(workPackage, 'due')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.I18n.t('js.work_packages.properties.assignee')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'assignee')}</span>
          </li>
          <li class="tooltip--map--item">
            <span class="tooltip--map--key">${this.I18n.t('js.work_packages.properties.priority')}:</span>
            <span class="tooltip--map--value">${this.sanitizedValue(workPackage, 'priority')}</span>
          </li>
        </ul>
        `;
  }

  private static defaultQueryProps(startDate:string, endDate:string) {
    const props = {
      c: ['id'],
      t:
        'id:asc',
      f: [{ n: 'status', o: 'o', v: [] },
        { n: 'datesInterval', o: '<>d', v: [startDate, endDate] }],
      pp: OpCalendarService.MAX_DISPLAYED,
    };

    return JSON.stringify(props);
  }
}
