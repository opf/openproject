import {
  ChangeDetectionStrategy,
  Component,
  Injector,
  OnInit,
} from '@angular/core';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import {
  Observable,
  switchMap,
} from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { StateService } from '@uirouter/core';
import {
  map,
  skip,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

@Component({
  selector: 'widget-wp-table',
  templateUrl: './wp-table.component.html',
  styleUrls: ['./wp-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
})
export class WidgetWpTableComponent extends AbstractWidgetComponent implements OnInit {
  public queryId:string|null;

  private queryForm:QueryFormResource;

  public inFlight = false;

  public query$:Observable<QueryResource>;

  public configuration:Partial<WorkPackageTableConfiguration> = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    hierarchyToggleEnabled: true,
    contextMenuEnabled: false,
  };

  constructor(protected i18n:I18nService,
    protected readonly injector:Injector,
    protected urlParamsHelper:UrlParamsHelperService,
    protected readonly state:StateService,
    protected readonly querySpace:IsolatedQuerySpace,
    protected readonly apiV3Service:ApiV3Service) {
    super(i18n, injector);
  }

  ngOnInit():void {
    if (!this.resource.options.queryId) {
      this
        .createInitial()
        .subscribe((query) => {
          const changeset = this.setChangesetOptions({ queryId: query.id });

          this.resourceChanged.emit(changeset);

          this.queryId = query.id;
        });
    } else {
      this.queryId = this.resource.options.queryId as string;
    }

    this.query$ = this
      .querySpace
      .query
      .values$();

    this.query$
      .pipe(
        // 2 because ... well it is a magic number and works
        skip(2),
        this.untilDestroyed(),
      ).subscribe((query) => {
      this.ensureFormAndSaveQuery(query);
    });
  }

  public get widgetName() {
    return this.resource.options.name as string;
  }

  public static get identifier():string {
    return 'work_packages_table';
  }

  private ensureFormAndSaveQuery(query:QueryResource) {
    if (this.queryForm) {
      this.saveQuery(query, this.queryForm);
    } else {
      this
        .apiV3Service
        .queries
        .form
        .load(query)
        .subscribe(([form, _]) => {
          this.queryForm = form;
          this.saveQuery(query, form);
        });
    }
  }

  private saveQuery(query:QueryResource, form:QueryFormResource) {
    this.inFlight = true;

    this
      .apiV3Service
      .queries
      .id(query)
      .patch(query, this.queryForm)
      .subscribe(
        () => this.inFlight = false,
        () => this.inFlight = false,
      );
  }

  private createInitial():Observable<QueryResource> {
    const projectIdentifier = this.state.params.projectPath as string;
    const initializationProps = this.resource.options.queryProps as { [key:string]:unknown };
    const queryProps = {
      pageSize: 0,
      ...initializationProps,
    };

    return this
      .apiV3Service
      .queries
      .form
      .loadWithParams(
        queryProps,
        undefined,
        projectIdentifier,
        this.queryCreationParams(),
      )
      .pipe(
        switchMap(([form, query]) => this
          .apiV3Service
          .queries
          .post(query, form)
          .pipe(
            map((resource:QueryResource) => {
              delete this.resource.options.queryProps;

              return resource;
            }),
          ),
        ),
      );
  }

  protected queryCreationParams() {
    // On the MyPage, the queries should be non public, on a project dashboard, they should be public.
    // This will not longer work, when global dashboards are implemented as the tables then need to
    // be public as well.
    const projectIdentifier = this.state.params.projectPath;

    return {
      hidden: true,
      public: !!projectIdentifier,
    };
  }
}
