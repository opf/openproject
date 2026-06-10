import {
  AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, inject, OnInit, ViewChild,
} from '@angular/core';
import { WorkPackageEmbeddedTableComponent } from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-table.component';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { RestrictedWpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import { ExternalQueryConfigurationService } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.service';
import { OpQueryConfigurationLocalsToken } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.constants';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

export interface QueryConfigurationLocals {
  service:ExternalQueryConfigurationService;
  currentQuery:unknown;
  urlParams?:boolean;
  disabledTabs?:Record<string, string>;
  callback:(newQuery:unknown) => void;
}

@Component({
  templateUrl: './external-query-configuration.template.html',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  providers: [[{ provide: WpTableConfigurationService, useClass: RestrictedWpTableConfigurationService }]],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class ExternalQueryConfigurationComponent implements OnInit, AfterViewInit {
  @ViewChild('embeddedTableForConfiguration', { static: true }) private embeddedTable:WorkPackageEmbeddedTableComponent;

  readonly locals = inject<QueryConfigurationLocals>(OpQueryConfigurationLocalsToken);
  readonly urlParamsHelper = inject(UrlParamsHelperService);
  readonly cdRef = inject(ChangeDetectorRef);

  queryProps:string|object;

  ngOnInit() {
    if (this.locals.urlParams) {
      const currentQuery = typeof this.locals.currentQuery === 'string' ? this.locals.currentQuery : null;
      this.queryProps = this.urlParamsHelper.buildV3GetQueryFromJsonParams(currentQuery);
    } else {
      this.queryProps = this.locals.currentQuery as object;
    }
  }

  ngAfterViewInit() {
    // Open the configuration modal in an asynchronous step
    // to avoid nesting components in the view initialization.
    setTimeout(() => {
      void this.embeddedTable.openConfigurationModal(() => {
        // The modal emits onDataUpdated immediately after tab onSave hooks run.
        // Defer reading query props by a tick so the embedded query space reflects
        // the latest filter/column changes before we persist them in form configuration.
        setTimeout(() => {
          this.service.detach();
          if (this.locals.urlParams) {
            this.locals.callback(this.embeddedTable.buildUrlParams());
          } else {
            this.locals.callback(this.embeddedTable.buildQueryProps());
          }
        });
      });
      this.cdRef.detectChanges();
    });
  }

  public get service():ExternalQueryConfigurationService {
    return this.locals.service;
  }
}
