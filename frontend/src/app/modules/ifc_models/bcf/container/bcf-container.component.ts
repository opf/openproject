import {ChangeDetectorRef, Component, Injector, OnDestroy, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {StateService} from '@uirouter/core';
import {GonService} from "core-app/modules/common/gon/gon.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageViewHandlerToken} from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";
import {BcfCardViewHandlerRegistry} from "core-app/modules/ifc_models/ifc-base-view/event-handler/bcf-card-view-handler-registry";

@Component({
  templateUrl: './bcf-container.component.html',
  providers: [
    { provide: WorkPackageViewHandlerToken, useValue: BcfCardViewHandlerRegistry }
  ]
})
export class BCFContainerComponent implements OnInit, OnDestroy {
  @InjectField() public queryParamListener:QueryParamListenerService;
  @InjectField() public wpListService:WorkPackagesListService;
  @InjectField() public urlParamsHelper:UrlParamsHelperService;

  public queryProps:{ [key:string]:any };

  public configuration:WorkPackageTableConfigurationObject = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    contextMenuEnabled: false,
    inlineCreateEnabled: false,
    withFilters: false,
    showFilterButton: false,
    isCardView: true
  };

  constructor(readonly state:StateService,
              readonly i18n:I18nService,
              readonly paths:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly gon:GonService,
              readonly injector:Injector,
              readonly cdRef:ChangeDetectorRef) {
  }

  ngOnInit():void {
    this.refresh();

    this.queryParamListener
      .observe$
      .pipe(
        untilComponentDestroyed(this)
      ).subscribe((queryProps) => {
        this.refresh(this.urlParamsHelper.buildV3GetQueryFromJsonParams(queryProps));
      });
  }

  ngOnDestroy():void {
    this.queryParamListener.removeQueryChangeListener();
  }

  private defaultQueryProps() {
    let filters = [];
    filters.push({
      status: {
        operator: 'o',
        values: []
      }
    });

    return {
      'columns[]': ['id', 'subject'],
      filters: JSON.stringify(filters),
      sortBy: JSON.stringify([['updatedAt', 'desc']]),
      showHierarchies: false
    };
  }

  public refresh(queryProps:{ [key:string]:any }|undefined = undefined) {
    this.wpListService.loadCurrentQueryFromParams(this.currentProject.identifier!);
    this.queryProps = queryProps || this.state.params.query_props || this.defaultQueryProps();
    this.cdRef.detectChanges();
  }
}
