import {ChangeDetectorRef, Component, ElementRef, Inject, OnInit, ViewChild, OnDestroy} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {WorkPackageViewColumnsService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {HalLink} from "core-app/modules/hal/hal-link/hal-link";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import * as URI from 'urijs';
import { HttpClient, HttpResponse } from '@angular/common/http';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import { expand, concatMap, catchError } from 'rxjs/operators';
import { timer, Subscription } from 'rxjs';

interface ExportLink extends HalLink {
  identifier:string;
}

/*
Modal for exporting work packages to different formats. The user may choose from a variety of formats (e.g. PDF and CSV).

The backend may choose to provide the export right away (synchronously) or delayed. In the later case, the modal will poll the
backend until the export is done.
Because the modal has to deal with both cases, without knowing upfront whether the download will be delayed or not, it needs
to treat every download expecting it to be delayed. Because of this, the modal cannot simply provide download hrefs which would
 allow the browser to download the export but rather has to first check whether an export is delayed or not, and if it is delayed,
 it has to wait until the export is ready. Because of the necessary check, the modal has a hidden link that it clicks on to perform
 the actual download once the export is ready (delayed or not).

The modal might also be used to only display the progress of an export. This will happen if a link for exporting is provided via the locals.
 */
@Component({
  templateUrl: './wp-table-export.modal.html',
  styleUrls: ['./wp-table-export.modal.sass']
})
export class WpTableExportModal extends OpModalComponent implements OnInit, OnDestroy {

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

  public downloadHref:string;
  private subscription?:Subscription;
  private loadingPromise?:Promise<void>;
  private finished?:Function;

  @ViewChild('downloadLink') downloadLink:ElementRef;

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly elementRef:ElementRef,
              readonly querySpace:IsolatedQuerySpace,
              readonly cdRef:ChangeDetectorRef,
              readonly httpClient:HttpClient,
              readonly wpTableColumns:WorkPackageViewColumnsService,
              readonly loadingIndicator:LoadingIndicatorService) {
  super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    if (this.locals.link) {
      this.downloadSwitched(this.locals.link);
    } else {
      this.querySpace.results
        .valuesPromise()
        .then((results) => this.exportOptions = this.buildExportOptions(results!));
    }
  }

  ngOnDestroy() {
    super.ngOnDestroy();
    this.safeUnsubscribe();
  }

  public get isLoading() {
    return !!this.loadingPromise;
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

    this.downloadSwitched(url);
  }

  private downloadSwitched(url:string) {
    this
      .triggerCall(url)
      .then((data) => {
        if (data.status === 202) {
          this.pollUntilDownload(data.url!);
        }
      })
      .catch((data) => {
        this.errorOrDownload(data);
      });

    this.startLoadingIndicator();
  }

  private triggerCall(url:string) {
    return this
      .httpClient
      .get(url, { observe: 'response' })
      .toPromise();
  }

  private pollUntilDownload(url:string) {
    let poller = this
      .httpClient
      .get(url, { observe: 'response'})
      .pipe(
        catchError(this.errorOrDownload.bind(this))
      );

    this.subscription = poller.pipe(
      expand(_ => timer(1000).pipe(concatMap(_ => poller)))
    ).subscribe();
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

  // While an error is thrown, it does not have to be an actual error.
  // Most likely, the response was a success (Code 200) but the client
  // failed to parse the response.
  private errorOrDownload(data:HttpResponse<any>) {
    if (data.status === 200) {
      this.download(data.url!);
    }

    this.safeUnsubscribe();
  }

  private download(url:string) {
    this.downloadHref = url;
    if (this.finished) {
      this.finished();
    }
    setTimeout(() => {
      this.downloadLink.nativeElement.click();
      this.service.close();
    });
  }

  private startLoadingIndicator() {
    this.loadingPromise = new Promise<void>((resolve) => {
      this.finished = resolve;
    });

    setTimeout(() => { this.loadingIndicator.modal.promise = this.loadingPromise!; } );
  }

  private safeUnsubscribe() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }
}
