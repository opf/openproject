import {AfterViewInit, Component, Inject, ViewChild} from '@angular/core';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {
  ExternalQueryConfigurationService,
  OpQueryConfigurationLocals
} from 'core-components/wp-table/external-configuration/external-query-configuration.service';

interface QueryConfigurationLocals {
  service:ExternalQueryConfigurationService;
  currentQuery:any;
  originator:JQuery;
}

@Component({
  template: `
  <wp-embedded-table #embeddedTableForConfiguration
                   [queryProps]="locals.currentQuery || {}"
                   [configuration]="{ tableVisible: false }">
  </wp-embedded-table>`
})
export class ExternalQueryConfigurationComponent implements AfterViewInit {

  @ViewChild('embeddedTableForConfiguration') private embeddedTable:WorkPackageEmbeddedTableComponent;

  constructor(@Inject(OpQueryConfigurationLocals) readonly locals:QueryConfigurationLocals) {
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
