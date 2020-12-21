import {ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import * as URI from 'urijs';
import {HttpClient} from '@angular/common/http';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Observable} from 'rxjs';

@Component({
  templateUrl: './invite-user.modal.html',
  styleUrls: ['./invite-user.modal.sass'],
  changeDetection: ChangeDetectionStrategy.onPush,
})
export class InviteUserModal extends OpModalComponent implements OnInit {
  /* Close on escape? */
  public closeOnEscape = true;

  /* Close on outside click */
  public closeOnOutsideClick = true;

  public $element:JQuery;
  public exportOptions:{ identifier:string, label:string, url:string }[];

  public text = {
    title: this.I18n.t('js.label_export'),
    closePopup: this.I18n.t('js.close_popup_title'),
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly cdRef: ChangeDetectorRef,
              readonly elementRef:ElementRef,
              readonly httpClient:HttpClient) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    if (this.locals.link) {
      this.requestExport(this.locals.link);
    } else {
      this.querySpace.results
        .valuesPromise()
        .then((results) => this.exportOptions = this.buildExportOptions(results!));
    }
  }

  private buildExportOptions(results:WorkPackageCollectionResource) {
    return results.representations.map(format => {
      const link = format.$link as ExportLink;

      return {
        identifier: link.identifier,
        label: link.title,
        url: this.addColumnsToHref(format.href!)
      };
    });
  }

  private triggerByLink(url:string, event:MouseEvent) {
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
        error => this.handleError(error)
      );

  }

  private replaceWithJobModal(jobId:string) {
    this.service.show(JobStatusModal, 'global', { jobId: jobId });
  }

  private handleError(error:string) {
    this.notifications.addError(error || this.I18n.t('js.error.internal'));
  }

  private addColumnsToHref(href:string) {
    let columns = this.wpTableColumns.getColumns();

    let columnIds = columns.map(function (column) {
      return column.id;
    });

    let url = URI(href);
    // Remove current columns
    url.removeSearch('columns[]');
    url.addSearch('columns[]', columnIds);

    return url.toString();
  }

  protected get afterFocusOn():JQuery {
    return jQuery('#work-packages-settings-button');
  }
}
