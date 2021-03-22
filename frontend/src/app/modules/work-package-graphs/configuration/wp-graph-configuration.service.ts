import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { WpGraphConfigurationSettingsTab } from "core-app/modules/work-package-graphs/configuration-modal/tabs/settings-tab.component";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { TabInterface } from "core-components/wp-table/configuration-modal/tab-portal-outlet";
import { Injectable } from '@angular/core';
import { WpGraphConfigurationFiltersTab } from "core-app/modules/work-package-graphs/configuration-modal/tabs/filters-tab.component";
import { ChartType } from 'chart.js';
import { QueryFormResource } from "core-app/modules/hal/resources/query-form-resource";
import {
  WpGraphConfiguration,
  WpGraphQueryParams
} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Injectable()
export class WpGraphConfigurationService {

  private _configuration:WpGraphConfiguration;
  private _forms:{[id:string]:QueryFormResource} = {};
  private _formsPromise:Promise<void[]>|null;

  constructor(readonly I18n:I18nService,
              readonly apiv3Service:APIV3Service,
              readonly notificationService:WorkPackageNotificationService,
              readonly currentProject:CurrentProjectService) {
  }

  public persistAndReload() {
    return this
      .persistChanges()
      .then(() => this.reloadQueries());
  }

  public persistChanges() {
    const promises = this.queries.map(query => {
      return this.saveQuery(query);
    });

    return Promise.all(promises);
  }

  public get datasets() {
    return this.queries.map(query => {
      return {
        groups: query.results.groups,
        queryProps: '',
        label: query.name
      };
    });
  }

  public reloadQueries() {
    this.configuration.queries.length = 0;

    return this.loadQueries();
  }

  public ensureQueryAndLoad() {
    if (this.queryParams.length === 0) {
      return this.createInitial()
        .then((query) => {
          this.queryParams.push({ id: query.id! });

          return this.loadQueries();
        });
    } else {
      return this.loadQueries();
    }
  }

  private createInitial():Promise<QueryResource> {
    return this
      .apiv3Service
      .queries
      .form
      .loadWithParams(
        { pageSize: 0 },
        undefined,
        this.currentProject.identifier,
        WpGraphConfiguration.queryCreationParams(this.I18n, !!this.currentProject.identifier)
      )
      .toPromise()
      .then(([form, query]) => {
        return this
          .apiv3Service
          .queries
          .post(query, form)
          .toPromise();
      });
  }

  private loadQueries() {
    const queryPromises = this.queryParams.map(queryParam => {
      return this.loadQuery(queryParam);
    });

    return Promise.all(queryPromises);
  }

  private loadQuery(params:WpGraphQueryParams) {
    return this
      .apiv3Service
      .queries
      .find(
        Object.assign({ pageSize: 0 }, params.props),
        params.id,
        this.currentProject.identifier,
      )
      .toPromise()
      .then(query => {
        if (params.name) {
          query.name = params.name;
        }
        this.configuration.queries.push(query);
      });
  }

  private async saveQuery(query:QueryResource) {
    return this.formFor(query)
      .then(form => {
        return this
          .apiv3Service
          .queries
          .id(query)
          .patch(query, form)
          .toPromise();
      });
  }

  public get configuration() {
    return this._configuration;
  }

  public set configuration(config:WpGraphConfiguration) {
    this._configuration = config;
    this._formsPromise = null;
  }

  public async formFor(query:QueryResource) {
    return this
      .loadForms()
      .then(() => {
        return this._forms[query.id!];
      });
  }

  public get tabs() {
    const tabs:TabInterface[] = [
      {
        name: 'graph-settings',
        title: this.I18n.t('js.chart.tabs.graph_settings'),
        componentClass: WpGraphConfigurationSettingsTab,
      }
    ];

    const queryTabs = this.configuration.queries.map((query) => {
      return {
        name: query.id as string,
        title: this.I18n.t('js.work_packages.query.filters'),
        componentClass: WpGraphConfigurationFiltersTab
      };
    });

    return tabs.concat(queryTabs);
  }

  public loadForms() {
    if (!this._formsPromise) {
      const formPromises = this.configuration.queries.map((query) => {
        return this
          .apiv3Service
          .queries
          .form
          .load(query)
          .toPromise()
          .then(([form, _]) => {
            this._forms[query.id as string] = form;
          })
          .catch((error) => this.notificationService.handleRawError(error));
      });

      this._formsPromise = Promise.all(formPromises);
    }

    return this._formsPromise;
  }

  public get chartType() {
    return this._configuration.chartType;
  }

  public set chartType(type:ChartType) {
    this._configuration.chartType = type;
  }

  public get queries() {
    return this._configuration.queries;
  }

  public get chartOptions() {
    return this._configuration.chartOptions;
  }

  public get queryParams() {
    return this._configuration.queryParams;
  }
}
