import {AfterViewInit, Injector, Input, OnDestroy, OnInit, SimpleChanges} from '@angular/core';
import {CurrentProjectService} from '../../projects/current-project.service';
import {TableState} from '../table-state/table-state';
import {WorkPackageStatesInitializationService} from '../../wp-list/wp-states-initialization.service';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject
} from 'core-components/wp-table/wp-table-configuration';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export abstract class WorkPackageEmbeddedBaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input('configuration') protected providedConfiguration:WorkPackageTableConfigurationObject;
  @Input() public uniqueEmbeddedTableName:string = `embedded-table-${Date.now()}`;
  @Input() public initialLoadingIndicator:boolean = true;

  public tableInformationLoaded = false;
  public showTablePagination = false;
  public configuration:WorkPackageTableConfiguration;
  public error:string|null = null;

  private initialized:boolean = false;

  readonly QueryDm:QueryDmService = this.injector.get(QueryDmService);
  readonly tableState:TableState  = this.injector.get(TableState);
  readonly I18n:I18nService = this.injector.get(I18nService);
  readonly urlParamsHelper:UrlParamsHelperService = this.injector.get(UrlParamsHelperService);
  readonly loadingIndicatorService:LoadingIndicatorService = this.injector.get(LoadingIndicatorService);
  readonly wpStatesInitialization:WorkPackageStatesInitializationService = this.injector.get(WorkPackageStatesInitializationService);
  readonly currentProject:CurrentProjectService = this.injector.get(CurrentProjectService);

  protected constructor(protected injector:Injector) {
  }

  ngOnInit() {
    this.configuration = new WorkPackageTableConfiguration(this.providedConfiguration);
    // Set embedded status in configuration
    this.configuration.isEmbedded = true;
    this.initialized = true;
  }

  ngAfterViewInit():void {
    // Load initially
    this.refresh(this.initialLoadingIndicator);

    // Reload results on refresh requests
    this.tableState.refreshRequired
      .values$()
      .pipe(untilComponentDestroyed(this))
      .subscribe(() => this.refresh(false));
  }

  ngOnDestroy():void {
    // noting to do
  }

  ngOnChanges(changes:SimpleChanges) {
    if (this.initialized) {
      this.refresh(this.initialLoadingIndicator);
    }
  }

  get projectIdentifier() {
    let identifier:string|null = null;

    if (this.configuration.projectContext) {
      identifier = this.currentProject.identifier;
    } else {
      identifier = this.configuration.projectIdentifier;
    }

    return identifier || undefined;
  }

  public buildQueryProps() {
    const query = this.tableState.query.value!;
    this.wpStatesInitialization.applyToQuery(query);

    return this.urlParamsHelper.buildV3GetQueryFromQueryResource(query);
  }

  protected setLoaded() {
    this.tableInformationLoaded = this.configuration.tableVisible;
  }

  public refresh(visible:boolean = true):Promise<any> {
    return this.loadQuery(visible);
  }

  public get isInitialized() {
    return !!this.configuration;
  }

  public set loadingIndicator(promise:Promise<any>) {
    if (this.configuration.tableVisible) {
      this.loadingIndicatorService
        .indicator(this.uniqueEmbeddedTableName)
        .promise = promise;
    }
  }

  protected abstract loadQuery(visible:boolean):Promise<any>;

  protected get queryProjectScope() {
    if (!this.configuration.projectContext) {
      return undefined;
    } else {
      return this.projectIdentifier;
    }
  }
}
