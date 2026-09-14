//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
