import { ChangeDetectorRef, Component, ElementRef, Inject, OnInit, ViewChild } from '@angular/core';
import { OpModalLocalsMap } from 'core-app/modules/modal/modal.types';
import { OpModalComponent } from 'core-app/modules/modal/modal.component';
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HttpClient, HttpErrorResponse, HttpResponse } from '@angular/common/http';
import { Observable, timer } from "rxjs";
import { switchMap, takeWhile } from "rxjs/operators";
import {
  LoadingIndicatorService,
  withDelayedLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { JobStatusEnum, JobStatusInterface } from "core-app/modules/job-status/job-status.interface";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";


@Component({
  templateUrl: './job-status.modal.html',
  styleUrls: ['./job-status.modal.sass']
})
export class JobStatusModal extends OpModalComponent implements OnInit {

  /* Close on escape? */
  public closeOnEscape = false;

  /* Close on outside click */
  public closeOnOutsideClick = false;

  public text = {
    title: this.I18n.t('js.job_status.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    redirect: this.I18n.t('js.job_status.redirect'),
    redirect_errors: this.I18n.t('js.job_status.redirect_errors') + ' ',
    redirect_link: this.I18n.t('js.job_status.redirect_link'),
    errors: this.I18n.t('js.job_status.errors'),
    download_starts: this.I18n.t('js.job_status.download_starts'),
    click_to_download: this.I18n.t('js.job_status.click_to_download'),
  };

  /** The job ID reference */
  public jobId:string;

  /** Whether to show the loading indicator */
  public isLoading = false;

  /** The current status */
  public status:JobStatusEnum;

  /** An associated icon to render, if any */
  public statusIcon:string|null;

  /** Public message to show */
  public message:string;

  /** Payload object of the response */
  public payload:any;

  /** Title to show */
  public title:string = this.text.title;

  /** A link in case the job results in a download */
  public downloadHref:string|null = null;

  @ViewChild('downloadLink') private downloadLink:ElementRef<HTMLInputElement>;

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              readonly elementRef:ElementRef,
              readonly pathHelper:PathHelperService,
              readonly apiV3Service:APIV3Service,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly notifications:NotificationsService,
              readonly httpClient:HttpClient) {
    super(locals, cdRef, elementRef);

    this.jobId = locals.jobId;
  }

  ngOnInit() {
    super.ngOnInit();
    this.listenOnJobStatus();
  }

  private listenOnJobStatus() {
    timer(0, 2000)
      .pipe(
        switchMap(() => this.performRequest()),
        takeWhile(response => !!response.body && this.continuedStatus(response.body), true),
        this.untilDestroyed(),
        withDelayedLoadingIndicator(this.loadingIndicator.getter('modal')),
      ).subscribe(
        response => this.onResponse(response),
        error => this.handleError(error),
        () => this.isLoading = false
      );
  }

  private iconForStatus():string|null {
    switch (this.status) {
    case "cancelled":
    case "failure":
    case "error":
      return 'icon-error';
      break;
    case "success":
      return "icon-checkmark";
      break;
    default:
      return null;
    }
  }

  /**
   * Determine whether the given status continues the timer
   * @param response
   */
  private continuedStatus(response:JobStatusInterface) {
    return ['in_queue', 'in_process'].includes(response.status);
  }

  private onResponse(response:HttpResponse<JobStatusInterface>) {
    const body = response.body;

    if (!body) {
      throw new Error(response as any);
    }

    const status = this.status = body.status;

    this.message = body.message ||
      this.I18n.t(`js.job_status.generic_messages.${status}`, { defaultValue: status });

    this.payload = body.payload;
    if (body.payload) {
      this.title = body.payload.title || this.text.title;
      this.handleRedirect(body.payload);
      this.handleDownload(body.payload?.download);
    }

    this.statusIcon = this.iconForStatus();
    this.cdRef.detectChanges();
  }

  private handleRedirect(payload:any) {
    if (payload?.redirect && !payload?.errors) {
      setTimeout(() => window.location.href = payload.redirect, 2000);
      this.message += `. ${this.text.redirect}`;
    }
  }

  private handleDownload(redirectionUrl?:string) {
    if (redirectionUrl !== undefined) {
      // Get the file url from the redirectionUrl
      this.httpClient
        .get(redirectionUrl, {
          observe: 'response',
          responseType: 'text'
        })
        .subscribe(response => {
          this.downloadHref = response.url;

          this.cdRef.detectChanges();
          this.downloadLink.nativeElement.click();
        });
    }
  }

  private performRequest():Observable<HttpResponse<JobStatusInterface>> {
    return this
      .httpClient
      .get<JobStatusInterface>(
        this.jobUrl,
        { observe: 'response', responseType: 'json' }
      );
  }

  private handleError(error:HttpErrorResponse) {
    if (error?.status === 404) {
      this.statusIcon = 'icon-help';
      this.message = this.I18n.t('js.job_status.generic_messages.not_found');
      return;
    }


    this.statusIcon = 'icon-error';
    this.message = error?.message || this.I18n.t('js.error.internal');
    this.notifications.addError(this.message);
  }

  private get jobUrl():string {
    return this.apiV3Service.job_statuses.id(this.jobId).toString();
  }
}
