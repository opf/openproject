import { AfterViewInit, ChangeDetectorRef, Component, Inject, OnInit, ViewChild } from '@angular/core';
import { WorkPackageEmbeddedTableComponent } from 'core-components/wp-table/embedded/wp-embedded-table.component';
import { WpTableConfigurationService } from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import { RestrictedWpTableConfigurationService } from 'core-components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import { OpQueryConfigurationLocalsToken } from "core-components/wp-table/external-configuration/external-query-configuration.constants";
import { UrlParamsHelperService } from "core-components/wp-query/url-params-helper";

export interface QueryConfigurationLocals {
  service:any;
  currentQuery:any;
  urlParams?:boolean;
  disabledTabs?:{ [key:string]:string };
  callback:(newQuery:any) => void;
}

@Component({
  templateUrl: './external-query-configuration.template.html',
  providers: [[{ provide: WpTableConfigurationService, useClass: RestrictedWpTableConfigurationService }]]
})
export class ExternalQueryConfigurationComponent implements OnInit, AfterViewInit {

  @ViewChild('embeddedTableForConfiguration', { static: true }) private embeddedTable:WorkPackageEmbeddedTableComponent;

  queryProps:string;

  constructor(@Inject(OpQueryConfigurationLocalsToken) readonly locals:QueryConfigurationLocals,
              readonly urlParamsHelper:UrlParamsHelperService,
              readonly cdRef:ChangeDetectorRef) {
  }

  ngOnInit() {
    if (this.locals.urlParams) {
      this.queryProps = this.urlParamsHelper.buildV3GetQueryFromJsonParams(this.locals.currentQuery);
    } else {
      this.queryProps = this.locals.currentQuery;
    }
  }

  ngAfterViewInit() {
    // Open the configuration modal in an asynchronous step
    // to avoid nesting components in the view initialization.
    setTimeout(() => {
      this.embeddedTable.openConfigurationModal(() => {
        this.service.detach();
        if (this.locals.urlParams) {
          this.locals.callback(this.embeddedTable.buildUrlParams());
        } else {
          this.locals.callback(this.embeddedTable.buildQueryProps());
        }
      });
      this.cdRef.detectChanges();
    });
  }

  public get service():any {
    return this.locals.service;
  }
}
