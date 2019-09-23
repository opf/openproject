import {AfterViewInit, ChangeDetectorRef, Component, Inject, ViewChild} from '@angular/core';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {WpTableConfigurationService} from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import {RestrictedWpTableConfigurationService} from 'core-components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import {OpQueryConfigurationLocalsToken} from "core-components/wp-table/external-configuration/external-query-configuration.constants";

export interface QueryConfigurationLocals {
  service:any;
  currentQuery:any;
  disabledTabs:{ [key:string]:string };
  callback:(newQuery:any) => void;
}

@Component({
  templateUrl: './external-query-configuration.template.html',
  providers: [[{ provide: WpTableConfigurationService, useClass: RestrictedWpTableConfigurationService }]]
})
export class ExternalQueryConfigurationComponent implements AfterViewInit {

  @ViewChild('embeddedTableForConfiguration', { static: true }) private embeddedTable:WorkPackageEmbeddedTableComponent;

  constructor(@Inject(OpQueryConfigurationLocalsToken) readonly locals:QueryConfigurationLocals,
              readonly cdRef:ChangeDetectorRef) {
  }

  ngAfterViewInit() {
    // Open the configuration modal in an asynchronous step
    // to avoid nesting components in the view initialization.
    setTimeout(() => {
      this.embeddedTable.openConfigurationModal(() => {
        this.service.detach();
        this.locals.callback(this.embeddedTable.buildQueryProps());
      });
      this.cdRef.detectChanges();
    });
  }

  public get service():any {
    return this.locals.service;
  }
}
