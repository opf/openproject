import {ChangeDetectorRef, Component, Injector, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {StateService} from '@uirouter/core';
import {GonService} from "core-app/modules/common/gon/gon.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";

@Component({
  templateUrl: './bcf-container.component.html',
  providers: [
    QueryParamListenerService
  ]
})
export class BCFContainerComponent implements OnInit {
  @InjectField() public queryParamListener:QueryParamListenerService;
  @InjectField() public wpListService:WorkPackagesListService;

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
  private filters:any[] = [];

  constructor(readonly state:StateService,
              readonly i18n:I18nService,
              readonly paths:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly gon:GonService,
              readonly injector:Injector,
              readonly cdRef:ChangeDetectorRef) {
  }

  ngOnInit():void {
    this.wpListService.loadCurrentQueryFromParams( this.currentProject.identifier!).then(() => {
        this.queryProps = this.state.params.query_props || this.defaultQueryProps();
        this.cdRef.detectChanges();
    });

    this.queryParamListener.observe$.pipe().subscribe((queryProps) => {
      this.queryProps = queryProps;
      this.cdRef.detectChanges();
    });
  }

  private defaultQueryProps() {
    this.filters.push({
      status: {
        operator: 'o',
        values: []
      }
    });

    return {
      'columns[]': ['id', 'subject'],
      filters: JSON.stringify(this.filters),
      sortBy: JSON.stringify([['updatedAt', 'desc']]),
      showHierarchies: false
    };
  }
}
