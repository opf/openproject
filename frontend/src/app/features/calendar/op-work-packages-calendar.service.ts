import { inject, Injectable, Injector } from '@angular/core';
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
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
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
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import {
  WorkPackagesListChecksumService,
} from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { EventReceiveArg, EventResizeDoneArg } from '@fullcalendar/interaction';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import moment from 'moment';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import {
  uiStateLinkClass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { States } from 'core-app/core/states/states.service';
import { resolveRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';
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
  private I18n = inject(I18nService);
  private configuration = inject(ConfigurationService);
  private sanitizer = inject(DomSanitizer);
  readonly injector = inject(Injector);
  readonly schemaCache = inject(SchemaCacheService);
  readonly toastService = inject(ToastService);
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpListService = inject(WorkPackagesListService);
  readonly wpListChecksumService = inject(WorkPackagesListChecksumService);
  readonly urlParamsHelper = inject(UrlParamsHelperService);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly apiV3Service = inject(ApiV3Service);
  readonly halResourceService = inject(HalResourceService);
  readonly timezoneService = inject(TimezoneService);
  readonly pathHelper = inject(PathHelperService);
  readonly halEditing = inject(HalResourceEditingService);
  readonly wpTableSelection = inject(WorkPackageViewSelectionService);
  readonly contextMenuService = inject(OPContextMenuService);
  readonly calendarService = inject(OpCalendarService);
  readonly weekdayService = inject(WeekdayService);
  readonly dayService = inject(DayResourceService);

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

  private readonly states = inject(States);

  calendarOptions(additionalOptions:CalendarOptions):CalendarOptions {
    return { ...this.defaultOptions(), ...additionalOptions };
  }

  eventDate(workPackage:WorkPackageResource, type:'start'|'due'):string {
    if (this.isMilestone(workPackage)) {
      return workPackage.date;
    }
    return workPackage[`${type}Date`];
  }

  isMilestone(workPackage:WorkPackageResource):boolean {
    return this.schemaCache.of(workPackage).isMilestone as boolean;
  }

  warnOnTooManyResults(collection:WorkPackageCollectionResource, isStatic = false):void {
    if (collection.count < collection.total) {
      this.tooManyResultsText = this.I18n.t(
        'js.calendar.too_many',
        {
          count: collection.total,
          max: OpWorkPackagesCalendarService.MAX_DISPLAYED,
        },
      );
    } else {
      this.tooManyResultsText = null;
    }

    if (this.tooManyResultsText && !isStatic) {
      this.toastService.addNotice(this.tooManyResultsText);
    }
  }

  async requireNonWorkingDays(start:Date|string, end:Date|string) {
    this.nonWorkingDays = await firstValueFrom(this.dayService.requireNonWorkingYears$(start, end));
  }

  isNonWorkingDay(date:Date|string):boolean {
    const formatted = moment(date).format('YYYY-MM-DD');
    return (this.nonWorkingDays.findIndex((el) => el.date === formatted) !== -1);
  }

  async updateTimeframe(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    projectIdentifier:string|undefined,
  ):Promise<unknown> {
    await this.requireNonWorkingDays(fetchInfo.start, fetchInfo.end);

    if (this.areFiltersEmpty && this.querySpace.query.value) {
      // nothing to do
      return Promise.resolve();
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    let queryId:string|null = null;
    if (this.urlParams.query_id) {
      queryId = this.urlParams.query_id;
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
        const oldQueryProps:Record<string, unknown> = JSON.parse(this.urlParams.query_props);

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
        this.querySpace.query.value!,
        startDate,
        endDate,
      );

      // There are no query props, ensure that they are not being shown the next load
      this.wpListChecksumService.set(queryId, queryProps);
    }

    return Promise.all([this
      .wpListService
      .fromQueryParams({ query_id: queryId, query_props: queryProps }, projectIdentifier || undefined)
      .toPromise(),
    ]);
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
    return this.urlParams.cview;
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
    if (onlyWhenOpen && !window.location.pathname.includes('/details/')) {
      return;
    }

    this.visitSplitViewLink(resolveRoutingId(this.states, id));
  }

  public openSplitCreate(extraParams?:Record<string, string>):void {
    this.visitSplitViewLink('new', extraParams);
  }

  private visitSplitViewLink(id:string, extraParams?:Record<string, string>):void {
    const basePath = window.location.pathname.replace(/\/details\/.*$/, '');
    const params = new URLSearchParams(window.location.search);
    if (extraParams) {
      Object.entries(extraParams).forEach(([key, value]) => params.set(key, value));
    }
    Turbo.visit(`${basePath}/details/${id}?${params.toString()}`, { frame: 'content-bodyRight', action: 'advance' });
  }

  public openFullView(id:string):void {
    this.wpTableSelection.setSelection(id, -1);
    Turbo.visit(this.pathHelper.workPackagePath(resolveRoutingId(this.states, id)));
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

    const handler = new WorkPackageViewContextMenu(this.injector, workPackageId, event.target as HTMLElement);
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
      dayHeaderContent: (data:DayHeaderContentArg) => this.calendarService.dayHeaderContent(data),
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

  public get urlParams():{
    query_id?:string;
    query_props?:string;
    cdate?:string;
    cview?:string;
  } {
    const search = new URLSearchParams(window.location.search);
    // Extract query_id from path-based routing (e.g. /calendars/<id>, /team_planners/<id>).
    const match = /\/(?:calendars|team_planners)\/([^/]+)/.exec(window.location.pathname);
    const rawId = match?.[1];
    return {
      query_id: rawId === 'new' ? undefined : rawId,
      query_props: search.get('query_props') ?? undefined,
      cdate: search.get('cdate') ?? undefined,
      cview: search.get('cview') ?? undefined,
    };
  }

  private get areFiltersEmpty():boolean {
    return this.wpTableFilters.isEmpty;
  }

  private get initialDate():string|undefined {
    const date = this.urlParams.cdate;
    if (date) {
      return this.timezoneService.formattedISODate(date);
    }

    return undefined;
  }

  private updateDateParam(dates:DatesSetArg) {
    const url = new URL(window.location.href);

    // Don't push a history entry when a split view is open: the date params are already
    // encoded in the details URL, and pushing here would add a spurious details-URL entry
    // that browser-back would restore (with the split view still visible).
    if (url.pathname.includes('/details/')) {
      return;
    }

    const newDate = this.timezoneService.formattedISODate(dates.view.calendar.getDate());
    const newView = (dates.view as unknown as { type:string }).type;

    if (url.searchParams.get('cdate') === newDate && url.searchParams.get('cview') === newView) {
      return;
    }

    url.searchParams.set('cdate', newDate);
    url.searchParams.set('cview', newView);
    // Use a Turbo-compatible state so that browser history.back() triggers Turbo's
    // restoration visit (full page reload), which correctly resets any open split view frame.
    window.history.pushState({ turbo: { restorationIdentifier: crypto.randomUUID() } }, '', url);
  }

  updateDates(resizeInfo:EventResizeDoneArg|EventDropArg|EventReceiveArg, dragged?:boolean):ResourceChangeset<WorkPackageResource> {
    const workPackage = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;
    const startDate = resizeInfo.event.startStr;
    const endDate = moment(resizeInfo.event.endStr).subtract(1, 'day').format('YYYY-MM-DD');

    // When resizing an event, or if it's a milestone, set work package dates to
    // event dates
    if (!dragged || this.isMilestone(workPackage)) {
      return this.changeToDates(workPackage, startDate, endDate);
    }

    // When drag&drop, adjust existing dates and duration of work package,
    //
    // In TeamPlanner, work packages can be moved from a work package list to
    // the calendar. In this case, there is no `delta` property (EventReceiveArg
    // event type) and dates need to set, even if not set initially.
    //
    // When moving inside the calendar, event is an EventDropArg and `delta`
    // property is present. Dates must be changed only if they are already set.
    const isMovingInSameCalendar = !!(resizeInfo as EventDropArg).delta;
    if (isMovingInSameCalendar) {
      return this.moveToDates(workPackage, startDate, endDate);
    }
    return this.moveToStartDate(workPackage, startDate);
  }

  private changeToDates(workPackage:WorkPackageResource, startDate:string, endDate:string):ResourceChangeset<WorkPackageResource> {
    const changeset = this.halEditing.edit(workPackage);
    changeset.setValue('startDate', startDate);
    changeset.setValue('dueDate', endDate);

    return changeset;
  }

  private moveToDates(workPackage:WorkPackageResource, startDate:string, endDate:string):ResourceChangeset<WorkPackageResource> {
    const changeset = this.halEditing.edit(workPackage);

    // Due to non-working days, we can't directly set start and due date when
    // drag-n-dropping work packages. Instead set duration (if present) and
    // start date to get due date recomputed.
    if (workPackage.duration) {
      changeset.setValue('duration', workPackage.duration);
    }

    // Keep dates unset if they are not set
    if (workPackage.startDate) {
      changeset.setValue('startDate', startDate);
    } else {
      changeset.setValue('dueDate', endDate);
    }

    return changeset;
  }

  private moveToStartDate(workPackage:WorkPackageResource, startDate:string):ResourceChangeset<WorkPackageResource> {
    const changeset = this.halEditing.edit(workPackage);

    changeset.setValue('startDate', startDate);
    // keep duration if present to deal with non-working days, or defaults to 1 day
    changeset.setValue('duration', workPackage.duration || 'P1D');

    return changeset;
  }
}
