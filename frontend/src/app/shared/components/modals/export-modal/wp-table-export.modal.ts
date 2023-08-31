import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import * as URI from 'urijs';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { JobStatusModalComponent } from 'core-app/features/job-status/job-status-modal/job-status.modal';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import isPersistedResource from 'core-app/features/hal/helpers/is-persisted-resource';

interface ExportLink extends HalLink {
  identifier:string;
}

/**
 Modal for exporting work packages to different formats. The user may choose from a variety of formats (e.g. PDF and CSV).
 The modal might also be used to only display the progress of an export. This will happen if a link for exporting is provided via the locals.
 */
@Component({
  templateUrl: './wp-table-export.modal.html',
  styleUrls: ['./wp-table-export.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpTableExportModalComponent extends OpModalComponent implements OnInit {
  public $element:HTMLElement;

  public exportOptions:{ identifier:string, label:string, url:string }[];

  public text = {
    title: this.I18n.t('js.label_export'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing'),
    cancelButton: this.I18n.t('js.button_cancel'),
  };

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly querySpace:IsolatedQuerySpace,
    readonly cdRef:ChangeDetectorRef,
    readonly httpClient:HttpClient,
    readonly wpTableColumns:WorkPackageViewColumnsService,
    readonly opStaticQueries:StaticQueriesService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly toastService:ToastService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    if (this.locals.link) {
      this.requestExport(this.locals.link);
    } else {
      void this.querySpace.results
        .valuesPromise()
        .then((results:WorkPackageCollectionResource) => {
          this.exportOptions = this.buildExportOptions(results);
          this.cdRef.detectChanges();
        });
    }
  }

  private buildExportOptions(results:WorkPackageCollectionResource) {
    return results.representations.map((format) => {
      const link = format.$link as ExportLink;

      return {
        identifier: link.identifier,
        label: link.title,
        url: this.addColumnsAndTitleToHref(format.href as string),
      };
    });
  }

  triggerByLink(url:string, event:MouseEvent):void {
    event.preventDefault();
    this.requestExport(url);
  }

  /**
   * Request the export link and return the job ID to observe
   *
   * @param url
   */
  private requestExport(url:string):void {
    this
      .httpClient
      .get(url, { observe: 'body', responseType: 'json' })
      .subscribe(
        (json:{ job_id:string }) => this.replaceWithJobModal(json.job_id),
        (error) => this.handleError(error),
      );
  }

  private replaceWithJobModal(jobId:string) {
    this.service.show(JobStatusModalComponent, 'global', { jobId });
  }

  private handleError(error:HttpErrorResponse) {
    // There was an error but the status code is actually a 200.
    // If that is the case the response's content-type probably does not match
    // the expected type (json).
    // Currently this happens e.g. when exporting Atom which actually is not an export
    // but rather a feed to follow.
    if (error.status === 200 && error.url) {
      window.open(error.url);
    } else {
      this.showError(error);
    }
  }

  private showError(error:HttpErrorResponse) {
    this.toastService.addError(error.message || this.I18n.t('js.error.internal'));
  }

  private addColumnsAndTitleToHref(href:string) {
    const columns = this.wpTableColumns.getColumns();

    const columnIds = columns.map((column) => column.id);

    const url = URI(href);
    // Remove current columns
    url.removeSearch('columns[]');
    url.addSearch('columns[]', columnIds);

    // Add the query title for the export
    const query = this.querySpace.query.value;
    if (query) {
      url.removeSearch('title');
      url.addSearch('title', this.queryTitle(query));
    }

    return url.toString();
  }

  private queryTitle(query:QueryResource):string {
    return isPersistedResource(query) ? query.name : this.staticQueryName(query);
  }

  protected staticQueryName(query:QueryResource):string {
    return this.opStaticQueries.getStaticName(query);
  }

  protected get afterFocusOn():HTMLElement {
    return document.getElementById('work-packages-settings-button') as HTMLElement;
  }
}
