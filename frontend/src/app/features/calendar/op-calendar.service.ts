import {
  ElementRef,
  Injectable,
} from '@angular/core';
import {
  CalendarOptions,
  DatesSetArg,
  EventApi,
  EventDropArg,
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
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import {
  QueryPropsFilter,
  UrlParamsHelperService,
} from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { UIRouterGlobals } from '@uirouter/core';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import {
  EventReceiveArg,
  EventResizeDoneArg,
} from '@fullcalendar/interaction';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import * as moment from 'moment';

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
    readonly wpListChecksumService:WorkPackagesListChecksumService,
    readonly urlParamsHelper:UrlParamsHelperService,
    readonly querySpace:IsolatedQuerySpace,
    readonly apiV3Service:ApiV3Service,
    readonly halResourceService:HalResourceService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly timezoneService:TimezoneService,
    readonly halEditing:HalResourceEditingService,
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

  async updateTimeframe(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    projectIdentifier:string|undefined,
  ):Promise<unknown> {
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
      const initialQuery = await this
        .apiV3Service
        .queries
        .find({ perPage: 0 }, queryId)
        .toPromise();

      queryProps = this.urlParamsHelper.encodeQueryJsonParams(
        initialQuery,
        { pp: OpCalendarService.MAX_DISPLAYED, pa: 1 },
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
            OpCalendarService.dateFilter(startDate, endDate),
          ],
        };

        queryProps = JSON.stringify(newQueryProps);
      } else {
        queryProps = OpCalendarService.defaultQueryProps(startDate, endDate);
      }
    } else {
      queryProps = this.urlParamsHelper.encodeQueryJsonParams(
        this.querySpace.query.value as QueryResource,
        (props) => ({
          ...props,
          pp: OpCalendarService.MAX_DISPLAYED,
          pa: 1,
          f: [
            ...props.f.filter((filter) => filter.n !== 'datesInterval'),
            OpCalendarService.dateFilter(startDate, endDate),
          ],
        }),
      );

      // There are no query props, ensure that they are not being shown the next load
      this.wpListChecksumService.set(queryId, queryProps);
    }

    return this
      .wpListService
      .fromQueryParams({ query_id: queryId, query_props: queryProps }, projectIdentifier || undefined)
      .toPromise();
  }

  public get initialView():string|undefined {
    return this.urlParams.cview as string|undefined;
  }

  public eventDurationEditable(wp:WorkPackageResource):boolean {
    const schema = this.schemaCache.of(wp);
    const schemaEditable = schema.isAttributeEditable('startDate') && schema.isAttributeEditable('dueDate');
    return (wp.isLeaf || wp.scheduleManually) && schemaEditable && !this.isMilestone(wp);
  }

  /**
   * The end date from fullcalendar is open, which means it targets
   * the next day instead of current day 23:59:59.
   * @param end
   */
  public getEndDateFromTimestamp(end:Date):string {
    return moment(end).subtract(1, 'd').format('YYYY-MM-DD');
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
      initialDate: this.initialDate,
      initialView: this.initialView,
      datesSet: (dates) => this.updateDateParam(dates),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      eventClick: this.openSplitView.bind(this),
    };
  }

  private openSplitView(event:EventClickArg) {
    const workPackage = event.event.extendedProps.workPackage as WorkPackageResource;
    void this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: workPackage.id, tabIdentifier: 'overview' },
    );
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
      pp: OpCalendarService.MAX_DISPLAYED,
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
    return (this.areFiltersEmpty && this.urlParams.query_id && !this.urlParams.query_props) as boolean;
  }

  private get urlParams() {
    return this.uiRouterGlobals.params;
  }

  private get areFiltersEmpty() {
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
        cdate: this.timezoneService.formattedISODate(dates.view.currentStart),
        cview: dates.view.type,
      },
      {
        custom: { notify: false },
      },
    );
  }

  updateDates(resizeInfo:EventResizeDoneArg|EventDropArg|EventReceiveArg):ResourceChangeset<WorkPackageResource> {
    const workPackage = resizeInfo.event.extendedProps.workPackage as WorkPackageResource;

    const changeset = this.halEditing.edit(workPackage);
    changeset.setValue('startDate', resizeInfo.event.startStr);
    const due = moment(resizeInfo.event.endStr)
      .subtract(1, 'day')
      .format('YYYY-MM-DD');
    changeset.setValue('dueDate', due);

    return changeset;
  }
}
