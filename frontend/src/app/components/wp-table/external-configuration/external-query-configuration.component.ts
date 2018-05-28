import {AfterViewInit, Component, Inject, ViewChild} from '@angular/core';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {WpTableConfigurationService} from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import {RestrictedWpTableConfigurationService} from 'core-components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import {OpQueryConfigurationLocalsToken, ExternalQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-query-configuration.service';

export interface QueryConfigurationLocals {
  service:ExternalQueryConfigurationService;
  currentQuery:any;
  disabledTabs:{ [key:string]:string };
  originator:JQuery;
}

@Component({
  template: `
  <wp-embedded-table #embeddedTableForConfiguration
                   [queryProps]="locals.currentQuery || {}"
                   [configuration]="{ tableVisible: false }">
  </wp-embedded-table>`,
  providers: [
    [{ provide: WpTableConfigurationService, useClass: RestrictedWpTableConfigurationService }]

  ],
})
export class ExternalQueryConfigurationComponent implements AfterViewInit {

  @ViewChild('embeddedTableForConfiguration') private embeddedTable:WorkPackageEmbeddedTableComponent;

  constructor(@Inject(OpQueryConfigurationLocalsToken) readonly locals:QueryConfigurationLocals) {
  }

  ngAfterViewInit() {
    // Open the configuration modal in an asynchronous step
    // to avoid nesting components in the view initialization.
    setTimeout(() => {
      this.embeddedTable.openConfigurationModal(() => {
        this.service.close(this.locals.originator, this.embeddedTable.buildQueryProps());
      });
    });
  }

  public get service():ExternalQueryConfigurationService {
    return this.locals.service;
  }
}
