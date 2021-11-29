import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  SecurityContext,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import {
  CalendarOptions,
  EventInput,
} from '@fullcalendar/core';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { FullCalendarComponent } from '@fullcalendar/angular';
import { EventViewLookupService } from 'core-app/features/team-planner/team-planner/planner/event-view-lookup.service';
import { States } from 'core-app/core/states/states.service';
import { StateService } from '@uirouter/angular';
import { DomSanitizer } from '@angular/platform-browser';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import { Subject } from 'rxjs';
import { take } from 'rxjs/internal/operators/take';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { EventClickArg } from '@fullcalendar/common';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';

@Component({
  selector: 'op-team-planner',
  templateUrl: './team-planner.component.html',
  styleUrls: ['./team-planner.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    EventViewLookupService,
  ],
})
export class TeamPlannerComponent extends UntilDestroyedMixin {
  @ViewChild(FullCalendarComponent) ucCalendar:FullCalendarComponent;

  @ViewChild('resourceContent') resourceContent:TemplateRef<unknown>;

  calendarOptions$ = new Subject<CalendarOptions>();

  projectIdentifier:string|null = null;

  constructor(
    private elementRef:ElementRef,
    private states:States,
    private $state:StateService,
    private sanitizer:DomSanitizer,
    private configuration:ConfigurationService,
    private wpTableFilters:WorkPackageViewFiltersService,
    private wpListService:WorkPackagesListService,
    private querySpace:IsolatedQuerySpace,
    private wpListChecksumService:WorkPackagesListChecksumService,
    private schemaCache:SchemaCacheService,
    private currentProject:CurrentProjectService,
    private titleService:OpTitleService,
    private viewLookup:EventViewLookupService,
    private I18n:I18nService,
  ) {
    super();
  }

  ngOnInit() {
    this.setupWorkPackagesListener();
    this.initializeCalendar();
    this.projectIdentifier = this.currentProject.identifier;
  }

  public calendarResourcesFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    this.querySpace.results.values$().pipe(
      take(1),
    ).subscribe((collection:WorkPackageCollectionResource) => {
      const resources = this.mapToCalendarResources(collection.elements);
      successCallback(resources);
    });
  }

  public calendarEventsFunction(
    fetchInfo:{ start:Date, end:Date, timeZone:string },
    successCallback:(events:EventInput[]) => void,
    failureCallback:(error:unknown) => void,
  ):void|PromiseLike<EventInput[]> {
    this.querySpace.results.values$().pipe(
      take(1),
    ).subscribe((collection:WorkPackageCollectionResource) => {
      const events = this.mapToCalendarEvents(collection.elements);
      successCallback(events);
    });

    this.updateTimeframe(fetchInfo);
  }

  private initializeCalendar() {
    this.configuration.initialized
      .then(() => {
        this.calendarOptions$.next({
          schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
          editable: false,
          locale: this.I18n.locale,
          fixedWeekCount: false,
          firstDay: this.configuration.startOfWeek(),
          // toolbar: this.buildHeader(),
          plugins: [
            resourceTimelinePlugin,
          ],
          initialView: 'resourceTimelineWeekDaysOnly',
          height: 500,
          views: {
            resourceTimelineWeekDaysOnly: {
              type: 'resourceTimeline',
              duration: { weeks: 1 },
              slotDuration: { days: 1 },
            },
          },
          events: this.calendarEventsFunction.bind(this) as any,
          resources: this.calendarResourcesFunction.bind(this),
          eventClick: this.openSplitView.bind(this),
          resourceLabelContent: (data:any) => this.renderTemplate(this.resourceContent, data.resource.id, data),
          resourceLabelWillUnmount: (data:any) => this.unrenderTemplate(data.resource.id),
        } as CalendarOptions);
      });
  }

  renderTemplate(template:TemplateRef<any>, id:string, data:any):{ domNodes:unknown[] } {
    const ref = this.viewLookup.getView(template, id, data);
    return { domNodes: ref.rootNodes };
  }

  unrenderTemplate(id:string):void {
    this.viewLookup.destroyView(id);
  }

  public updateTimeframe(fetchInfo:{ start:Date, end:Date, timeZone:string }) {
    const filtersEmpty = this.wpTableFilters.isEmpty;

    if (filtersEmpty && this.querySpace.query.value) {
      // nothing to do
      return;
    }

    const startDate = moment(fetchInfo.start).format('YYYY-MM-DD');
    const endDate = moment(fetchInfo.end).format('YYYY-MM-DD');

    if (filtersEmpty) {
      let queryProps = this.defaultQueryProps(startDate, endDate);

      if (this.$state.params.query_props) {
        queryProps = decodeURIComponent(this.$state.params.query_props || '');
      }

      this.wpListService.fromQueryParams({ query_props: queryProps }, this.projectIdentifier || undefined).toPromise();
    } else {
      const { params } = this.$state;

      this.wpTableFilters.modify('datesInterval', (datesIntervalFilter) => {
        datesIntervalFilter.values[0] = startDate;
        datesIntervalFilter.values[1] = endDate;
      });
    }
  }

  private openSplitView(event:EventClickArg) {
    const { workPackage } = event.event.extendedProps;

    this.$state.go(
      `${splitViewRoute(this.$state)}.tabs`,
      { workPackageId: workPackage.id, tabIdentifier: 'overview' },
    );
  }

  private setupWorkPackagesListener() {
    this.querySpace.results.values$().pipe(
      this.untilDestroyed(),
    ).subscribe((collection:WorkPackageCollectionResource) => {
      this.ucCalendar.getApi().refetchEvents();
    });
  }

  private mapToCalendarEvents(workPackages:WorkPackageResource[]):EventInput[] {
    return workPackages
      .map((workPackage:WorkPackageResource) => {
        if (!workPackage.assignee) {
          return;
        }

        const startDate = this.eventDate(workPackage, 'start');
        const endDate = this.eventDate(workPackage, 'due');

        const exclusiveEnd = moment(endDate).add(1, 'days').format('YYYY-MM-DD');

        return {
          id: workPackage.href + (workPackage.assignee?.href || 'no-assignee'),
          resourceId: workPackage.assignee?.href,
          title: workPackage.subject,
          start: startDate,
          end: exclusiveEnd,
          allDay: true,
          className: `__hl_background_type_${workPackage.type.id}`,
          workPackage,
        };
      })
      .filter((event) => !!event) as EventInput[];
  }

  private mapToCalendarResources(workPackages:WorkPackageResource[]) {
    const resources:{ id:string, title:string, user:HalResource }[] = [];

    workPackages.forEach((workPackage:WorkPackageResource) => {
      if (!workPackage.assignee) {
        return;
      }

      resources.push({
        id: workPackage.assignee.href,
        title: workPackage.assignee.name,
        user: workPackage.assignee,
      });
    });

    return resources;
  }

  private defaultQueryProps(startDate:string, endDate:string) {
    const props = {
      c: ['id'],
      t:
        'id:asc',
      f: [{ n: 'status', o: 'o', v: [] },
        { n: 'datesInterval', o: '<>d', v: [startDate, endDate] }],
      pp: 100,
    };

    return JSON.stringify(props);
  }

  private eventDate(workPackage:WorkPackageResource, type:'start'|'due') {
    if (this.schemaCache.of(workPackage).isMilestone) {
      return workPackage.date;
    }
    return workPackage[`${type}Date`];
  }

  private calendarHeight():number {
    let heightElement = jQuery(this.elementRef.nativeElement);

    while (!heightElement.height() && heightElement.parent()) {
      heightElement = heightElement.parent();
    }

    const topOfCalendar = jQuery(this.elementRef.nativeElement).position().top;
    const topOfHeightElement = heightElement.position().top;

    return heightElement.height()! - (topOfCalendar - topOfHeightElement);
  }

  private sanitizedValue(workPackage:WorkPackageResource, attribute:string, toStringMethod:string|null = 'name') {
    let value = workPackage[attribute];
    value = toStringMethod && value ? value[toStringMethod] : value;
    value = value || this.I18n.t('js.placeholders.default');

    return this.sanitizer.sanitize(SecurityContext.HTML, value);
  }
}
