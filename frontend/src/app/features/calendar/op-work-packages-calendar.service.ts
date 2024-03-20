import { Injectable, Injector } from '@angular/core';
import {
  CalendarOptions,
  DatesSetArg,
  DayCellContentArg,
  DayCellMountArg,
  DayHeaderContentArg,
  EventApi,
  EventDropArg,
  SlotLabelContentArg,
  SlotLaneContentArg,
} from '@fullcalendar/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { DomSanitizer } from '@angular/platform-browser';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { StateService } from '@uirouter/angular';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { firstValueFrom, Observable } from 'rxjs';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { take } from 'rxjs/operators';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import {
  QueryPropsFilter,
  UrlParamsHelperService,
} from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { UIRouterGlobals } from '@uirouter/core';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import {
  WorkPackagesListChecksumService,
} from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { EventReceiveArg, EventResizeDoneArg } from '@fullcalendar/interaction';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import * as moment from 'moment';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import {
  uiStateLinkClass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import {
  WorkPackageViewContextMenu,
} from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import allLocales from '@fullcalendar/core/locales-all';

export interface CalendarViewEvent {
  el:HTMLElement;
  event:EventApi;
}

// The CalenderOptions typings are missing daygrid hooks
interface CalendarOptionsWithDayGrid extends CalendarOptions {
  dayGridClassNames:(data:DayCellMountArg) => void;
}

@Injectable()
export class OpWorkPackagesCalendarService extends UntilDestroyedMixin {
  static MAX_DISPLAYED = 500;

  tooManyResultsText:string|null;

  public nonWorkingDays:IDay[] = [];

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
    private $state:StateService,
    readonly injector:Injector,
    readonly schemaCache:SchemaCacheService,
    readonly toastService:ToastService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly wpListService:WorkPackagesListService,
    readonly wpListChecksumService:WorkPackagesListChecksumService,
    readonly urlParamsHelper:UrlParamsHelperService,
    readonly querySpace:IsolatedQuerySpace,
    readonly apiV3Service:ApiV3Service,
    readonly halResourceService:HalResourceService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly timezoneService:TimezoneService,
    readonly halEditing:HalResourceEditingService,
    readonly wpTableSelection:WorkPackageViewSelectionService,
    readonly contextMenuService:OPContextMenuService,
    readonly calendarService:OpCalendarService,
    readonly weekdayService:WeekdayService,
    readonly dayService:DayResourceService,
  ) {
    super();
  }

  calendarOptions(additionalOptions:CalendarOptions):CalendarOptions {
    return { ...this.defaultOptions(), ...additionalOptions };
  }

  eventDate(workPackage:WorkPackageResource, type:'start'|'due'):string {
    if (this.isMilestone(workPackage)) {
      return workPackage.date;
    }
    return workPackage[`${type}Date`] as string;
  }

  isMilestone(workPackage:WorkPackageResource):boolean {
    return this.schemaCache.of(workPackage).isMilestone as boolean;
  }

  warnOnTooManyResults(collection:WorkPackageCollectionResource, isStatic = false):void {
    if (collection.count < collection.total) {
      this.tooManyResultsText = this.I18n.t('js.calendar.too_many',
        {
          count: collection.total,
          max: OpWorkPackagesCalendarService.MAX_DISPLAYED,
        });
    } else {
      this.tooManyResultsText = null;
    }

    if (this.tooManyResultsText && !isStatic) {
      this.toastService.addNotice(this.tooManyResultsText);
    }
  }

  async requireNonWorkingDays(date:Date|string) {
    this.nonWorkingDays = await firstValueFrom(this.dayService.requireNonWorkingYear$(date));
  }

  isNonWorkingDay(date:Date|string):boolean {
    const formatted = moment(date).format('YYYY-MM-DD');
    return (this.nonWorkingDays.findIndex((el) => el.date === formatted) !== -1);
  }

  async updateTimeframe(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    projectIdentifier:string|undefined,
  ):Promise<unknown> {
    await this.requireNonWorkingDays(fetchInfo.start);
    await this.requireNonWorkingDays(fetchInfo.end);

    if (this.areFiltersEmpty && this.querySpace.query.value) {
      // nothing to do
      return Promise.resolve();
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    let queryId:string|null = null;
    if (this.urlParams.query_id) {
      queryId = this.urlParams.query_id as string;
    }
    // We derive the necessary props in the following cases
    // 1. We load a queryId with no props
    // 2. We load visible query props or empty
    // 3. We are already loaded and are refetching data (for changed dates, e.g.)
    let queryProps:string|undefined;


    if (this.initializingWithQuery) {
      // This is the case on initially loading the calendar with a query_id present in the url params but no
      // query props to overwrite the query settings.
      // We want to always use the currently displayed time interval to be filtered for
      // so we need to adapt any eventually existing dateInterval filter to have that time interval. If no
      // such filter exists yet, we need to add it to the existing filter set.
      // In order to do both, we first need to fetch the query as we cannot signal
      // to the backend yet to only add this one filter but leave the rest unchanged.
      const initialQuery = await firstValueFrom(this.apiV3Service.queries.find({ pageSize: 0 }, queryId));

      queryProps = this.generateQueryProps(
        initialQuery,
        startDate,
        endDate,
      );
    } else if (this.initializingWithQueryProps) {
      // This is the case on initially loading the calendar with query_props present in the url params.
      // There might also be a query_id but the settings persisted in it are overwritten by the props.
      if (this.urlParams.query_props) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        const oldQueryProps:{ [key:string]:unknown } = JSON.parse(this.urlParams.query_props);

        // Update the date period of the calendar in the filter
        const newQueryProps = {
          ...oldQueryProps,
          f: [
            ...(oldQueryProps.f as QueryPropsFilter[]).filter((filter:QueryPropsFilter) => filter.n !== 'datesInterval'),
            OpWorkPackagesCalendarService.dateFilter(startDate, endDate),
          ],
          pp: OpWorkPackagesCalendarService.MAX_DISPLAYED,
          pa: 1,
        };

        queryProps = JSON.stringify(newQueryProps);
      } else {
        queryProps = OpWorkPackagesCalendarService.defaultQueryProps(startDate, endDate);
      }
    } else {
      queryProps = this.generateQueryProps(
        this.querySpace.query.value as QueryResource,
        startDate,
        endDate,
      );

      // There are no query props, ensure that they are not being shown the next load
      this.wpListChecksumService.set(queryId, queryProps);
    }

    return Promise.all([this
      .wpListService
      .fromQueryParams({ query_id: queryId, query_props: queryProps, }, projectIdentifier || undefined)
      .toPromise(),
    ])
  }

  public generateQueryProps(
    query:QueryResource,
    startDate:string,
    endDate:string,
  ):string {
    return this.urlParamsHelper.encodeQueryJsonParams(
      query,
      (props) => ({
        ...props,
        pp: OpWorkPackagesCalendarService.MAX_DISPLAYED,
        pa: 1,
        f: [
          ...props.f.filter((filter) => filter.n !== 'datesInterval'),
          OpWorkPackagesCalendarService.dateFilter(startDate, endDate),
        ],
      }),
    );
  }

  public get initialView():string|undefined {
    return this.urlParams.cview as string|undefined;
  }

  dateEditable(wp:WorkPackageResource):boolean {
    const schema = this.schemaCache.of(wp);
    const schemaEditable = schema.isAttributeEditable('startDate') && schema.isAttributeEditable('dueDate');
    return (wp.isLeaf || wp.scheduleManually) && schemaEditable;
  }

  eventDurationEditable(wp:WorkPackageResource):boolean {
    return this.dateEditable(wp) && !this.isMilestone(wp);
  }

  /**
   * The end date from fullcalendar is open, which means it targets
   * the next day instead of current day 23:59:59.
   * @param end A string representation of the end date
   */
  public getEndDateFromTimestamp(end:string):string {
    return moment(end).subtract(1, 'd').format('YYYY-MM-DD');
  }

  public openSplitView(id:string, onlyWhenOpen = false):void {
    this.wpTableSelection.setSelection(id, -1);

    // Only open the split view if already open, otherwise only clicking the details opens
    if (onlyWhenOpen && !this.$state.includes('**.details.*')) {
      return;
    }

    void this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: id, tabIdentifier: 'overview' },
    );
  }

  public openFullView(id:string):void {
    this.wpTableSelection.setSelection(id, -1);

    void this.$state.go(
      'work-packages.show',
      { workPackageId: id },
    );
  }

  public onCardClicked({ workPackageId, event }:{ workPackageId:string, event:MouseEvent }):void {
    if (isClickedWithModifier(event)) {
      return;
    }

    this.openSplitView(workPackageId, true);
  }

  public onCardDblClicked({ workPackageId, event }:{ workPackageId:string, event:MouseEvent }):void {
    if (isClickedWithModifier(event)) {
      return;
    }

    this.openFullView(workPackageId);
  }

  public showEventContextMenu({ workPackageId, event }:{ workPackageId:string, event:MouseEvent }):void {
    if (isClickedWithModifier(event)) {
      return;
    }

    // We want to keep the original context menu on hrefs
    // (currently, this is only the id)
    if ((event.target as HTMLElement).closest(`.${uiStateLinkClass}`)) {
      debugLog('Allowing original context menu on state link');
      return;
    }

    // Set the selection to single
    this.wpTableSelection.setSelection(workPackageId, -1);

    event.preventDefault();

    const handler = new WorkPackageViewContextMenu(this.injector, workPackageId, jQuery(event.target as HTMLElement));
    this.contextMenuService.show(handler, event);
  }

  private defaultOptions():CalendarOptionsWithDayGrid {
    return {
      editable: false,
      locales: allLocales,
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
      initialDate: this.initialDate,
      initialView: this.initialView,
      datesSet: (dates) => this.updateDateParam(dates),
      dayHeaderClassNames: (data:DayHeaderContentArg) => this.calendarService.applyNonWorkingDay(data, this.nonWorkingDays),
      dayCellClassNames: (data:DayCellContentArg) => this.calendarService.applyNonWorkingDay(data, this.nonWorkingDays),
      dayGridClassNames: (data:DayCellContentArg) => this.calendarService.applyNonWorkingDay(data, this.nonWorkingDays),
      slotLaneClassNames: (data:SlotLaneContentArg) => this.calendarService.applyNonWorkingDay(data, this.nonWorkingDays),
      slotLabelClassNames: (data:SlotLabelContentArg) => this.calendarService.applyNonWorkingDay(data, this.nonWorkingDays),
    };
  }

  private static defaultQueryProps(startDate:string, endDate:string) {
    const props = {
      c: ['id'],
      t:
        'id:asc',
      f: [
        { n: 'status', o: '*', v: [] },
        this.dateFilter(startDate, endDate),
      ],
      dr: 'cards',
      hi: false,
      pp: OpWorkPackagesCalendarService.MAX_DISPLAYED,
      pa: 1,
    };

    return JSON.stringify(props);
  }

  private static dateFilter(startDate:string, endDate:string):QueryPropsFilter {
    return { n: 'datesInterval', o: '<>d', v: [startDate, endDate] };
  }

  private get initializingWithQueryProps():boolean {
    // Initialise with current query props
    // If the filters are empty, they still need to be initialised (with empty props)
    return (this.areFiltersEmpty || this.urlParams.query_props) as boolean;
  }

  private get initializingWithQuery():boolean {
    return this.areFiltersEmpty
      && !!this.urlParams.query_id
      && !this.urlParams.query_props;
  }

  public get urlParams() {
    return this.uiRouterGlobals.params;
  }

  private get areFiltersEmpty():boolean {
    return this.wpTableFilters.isEmpty;
  }

  private get initialDate():string|undefined {
    const date = this.urlParams.cdate as string|undefined;
    if (date) {
      return this.timezoneService.formattedISODate(date);
    }

    return undefined;
  }

  private updateDateParam(dates:DatesSetArg) {
    void this.$state.go(
      '.',
      {
        cdate: this.timezoneService.formattedISODate(dates.view.calendar.getDate()),
        // v6.beta3 fails to have type on the ViewAPI
        cview: (dates.view as unknown as { type:string }).type,
      },
      {
        custom: { notify: false },
      },
    );
  }

  updateDates(resizeInfo:EventResizeDoneArg|EventDropArg|EventReceiveArg, dragged?:boolean):ResourceChangeset<WorkPackageResource> {
    const workPackage = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
    const changeset = this.halEditing.edit(workPackage);
    if (!workPackage.ignoreNonWorkingDays && workPackage.duration && dragged) {
      changeset.setValue('duration', workPackage.duration);
    } else {
      const due = moment(resizeInfo.event.endStr)
        .subtract(1, 'day')
        .format('YYYY-MM-DD');
      changeset.setValue('dueDate', due);
    }
    changeset.setValue('startDate', resizeInfo.event.startStr);
    return changeset;
  }
}
