import {
  AfterViewInit,
  Directive,
  Input,
  SimpleChanges, OnInit, OnChanges, inject,
} from '@angular/core';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject,
} from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackagesViewBase } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.base';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { firstValueFrom } from 'rxjs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Directive()
export abstract class WorkPackageEmbeddedBaseComponent extends WorkPackagesViewBase implements AfterViewInit, OnInit, OnChanges {
  @Input('configuration') protected providedConfiguration:WorkPackageTableConfigurationObject;

  @Input() public uniqueEmbeddedTableName = `embedded-table-${Date.now()}`;

  @Input() public initialLoadingIndicator = true;

  public renderTable = false;

  public showTablePagination = false;

  public configuration:WorkPackageTableConfiguration;

  public error:string|null = null;

  protected initialized = false;

  readonly apiV3Service = inject(ApiV3Service);

  readonly urlParamsHelper = inject(UrlParamsHelperService);

  readonly pathHelper = inject(PathHelperService);

  ngOnInit() {
    this.configuration = new WorkPackageTableConfiguration(this.providedConfiguration);
    // Set embedded status in configuration
    this.configuration.isEmbedded = true;
    this.initialized = true;

    super.ngOnInit();
  }

  ngAfterViewInit():void {
    // Load initially
    void this.loadQuery(true, false);
  }

  ngOnChanges(changes:SimpleChanges) {
    if (this.initialized && (changes.queryId || changes.queryProps)) {
      void this.loadQuery(this.initialLoadingIndicator, false);
    }
  }

  public get projectIdentifier() {
    if (this.configuration.projectContext) {
      return this.currentProject.identifier || undefined;
    }
    return this.configuration.projectIdentifier || undefined;
  }

  public buildQueryProps():object {
    const query = this.querySpace.query.value!;
    this.wpStatesInitialization.applyToQuery(query);

    return this.urlParamsHelper.buildV3GetQueryFromQueryResource(query);
  }

  public buildUrlParams() {
    const query = this.querySpace.query.value!;
    this.wpStatesInitialization.applyToQuery(query);

    return this.urlParamsHelper.encodeQueryJsonParams(query);
  }

  protected setLoaded() {
    this.renderTable = this.configuration.tableVisible;
    this.cdRef.detectChanges();
  }

  public refresh(visible = true, firstPage = false):Promise<any> {
    const query = this.querySpace.query.value!;
    const pagination = this.wpTablePagination.paginationObject;

    if (firstPage) {
      pagination.offset = 1;
    }

    const params = this.urlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination) as object;
    const promise = firstValueFrom(
      this
        .wpListService
        .loadQueryFromExisting(query, params, this.queryProjectScope),
    )
      .then((updated) => this.wpStatesInitialization.updateQuerySpace(updated, updated.results));

    if (visible) {
      this.loadingIndicator = promise;
    }
    return promise;
  }

  public get isInitialized() {
    return !!this.configuration;
  }

  public set loadingIndicator(promise:Promise<unknown>) {
    if (this.configuration.tableVisible) {
      this.loadingIndicatorService
        .indicator(this.uniqueEmbeddedTableName)
        .promise = promise;
    }
  }

  public abstract loadQuery(visible:boolean, firstPage:boolean):Promise<QueryResource|undefined>;

  protected get queryProjectScope() {
    if (!this.configuration.projectContext) {
      return undefined;
    }
    return this.projectIdentifier;
  }

  protected initializeStates(query:QueryResource) {
    this.wpStatesInitialization.clearStates();
    this.wpStatesInitialization.initializeFromQuery(query, query.results);
    this.wpStatesInitialization.updateQuerySpace(query, query.results);
  }
}
