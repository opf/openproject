import {ChangeDetectionStrategy, Component, Injector} from '@angular/core';
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {WorkPackageTableConfiguration} from "core-components/wp-table/wp-table-configuration";
import {Observable} from 'rxjs';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {QueryFormDmService} from "core-app/modules/hal/dm-services/query-form-dm.service";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {StateService} from '@uirouter/core';
import {skip} from 'rxjs/operators';

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
              protected readonly queryDm:QueryDmService,
              protected readonly querySpace:IsolatedQuerySpace,
              protected readonly queryFormDm:QueryFormDmService) {
    super(i18n, injector);
  }

  ngOnInit() {
    if (!this.resource.options.queryId) {
      this.createInitial()
        .then((query) => {
          let changeset = this.setChangesetOptions({ queryId: query.id });

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
      this.saveQuery(query);
    } else {
      this.queryFormDm.load(query).then((form) => {
        this.queryForm = form;
        this.saveQuery(query);
      });
    }
  }

  private saveQuery(query:QueryResource) {
    this.inFlight = true;

    this
      .queryDm
      .update(query, this.queryForm)
      .toPromise()
      .then((query) => {
        this.inFlight = false;
        return query;
      })
      .catch(() => this.inFlight = false);
  }

  private createInitial():Promise<QueryResource> {
    const projectIdentifier = this.state.params['projectPath'];
    let initializationProps = this.resource.options.queryProps;
    let queryProps = Object.assign({ pageSize: 0 }, initializationProps);

    return this.queryFormDm
      .loadWithParams(
        queryProps,
        undefined,
        projectIdentifier,
        this.queryCreationParams()
      )
      .then(form => {
        const query = this.queryFormDm.buildQueryResource(form);

        return this.queryDm.create(query, form).then((query) => {
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
