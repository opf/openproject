import { ChangeDetectionStrategy, Component, Injector } from '@angular/core';
import { AbstractWidgetComponent } from "core-app/modules/grids/widgets/abstract-widget.component";
import { QueryFormResource } from "core-app/modules/hal/resources/query-form-resource";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { WorkPackageTableConfiguration } from "core-components/wp-table/wp-table-configuration";
import { Observable } from 'rxjs';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { UrlParamsHelperService } from "core-components/wp-query/url-params-helper";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { StateService } from '@uirouter/core';
import { finalize, publish, skip } from 'rxjs/operators';
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Component({
  selector: 'widget-wp-table',
  templateUrl: './wp-table.component.html',
  styleUrls: ['./wp-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetWpTableComponent extends AbstractWidgetComponent {
  public queryId:string|null;
  private queryForm:QueryFormResource;
  public inFlight = false;
  public query$:Observable<QueryResource>;

  public configuration:Partial<WorkPackageTableConfiguration> = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    hierarchyToggleEnabled: true,
    contextMenuEnabled: false
  };

  constructor(protected i18n:I18nService,
              protected readonly injector:Injector,
              protected urlParamsHelper:UrlParamsHelperService,
              protected readonly state:StateService,
              protected readonly querySpace:IsolatedQuerySpace,
              protected readonly apiV3Service:APIV3Service) {
    super(i18n, injector);
  }

  ngOnInit() {
    if (!this.resource.options.queryId) {
      this.createInitial()
        .then((query) => {
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
        this.untilDestroyed()
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

  private createInitial():Promise<QueryResource> {
    const projectIdentifier = this.state.params['projectPath'];
    const initializationProps = this.resource.options.queryProps;
    const queryProps = Object.assign({ pageSize: 0 }, initializationProps);

    return this
      .apiV3Service
      .queries
      .form
      .loadWithParams(
        queryProps,
        undefined,
        projectIdentifier,
        this.queryCreationParams()
      )
      .toPromise()
      .then(([form, query]) => {
        return this
          .apiV3Service
          .queries
          .post(query, form)
          .toPromise()
          .then((query) => {
            delete this.resource.options.queryProps;

            return query;
          });
      });
  }

  protected queryCreationParams() {
    // On the MyPage, the queries should be non public, on a project dashboard, they should be public.
    // This will not longer work, when global dashboards are implemented as the tables then need to
    // be public as well.
    const projectIdentifier = this.state.params['projectPath'];

    return {
      hidden: true,
      public: !!projectIdentifier
    };
  }
}
