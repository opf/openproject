import {Component} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import { StateService } from '@uirouter/core';
import {GonService} from "core-app/modules/common/gon/gon.service";

@Component({
  templateUrl: './bcf-container.component.html'
})
export class BCFContainerComponent {
  public queryProps:{ [key:string]:any };
  public configuration:WorkPackageTableConfigurationObject = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    contextMenuEnabled: false,
    inlineCreateEnabled: false,
    withFilters: true,
    showFilterButton: false,
    isCardView: true
  };

  private filters:any[] = [];

  constructor(readonly state:StateService,
              readonly i18n:I18nService,
              readonly paths:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly gon:GonService) {

    this.applyFilters();
  }

  private applyFilters() {
    // TODO: Limit to project
    this.filters.push({
      status: {
        operator: 'o',
        values: []
      }
    });

    this.queryProps = {
      'columns[]': ['id', 'subject'],
      filters: JSON.stringify(this.filters),
      sortBy: JSON.stringify([['updatedAt', 'desc']]),
      showHierarchies: false
    };
  }
}
