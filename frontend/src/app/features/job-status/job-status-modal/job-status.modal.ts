import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnInit,
  ViewChild,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HttpClient, HttpErrorResponse, HttpResponse } from '@angular/common/http';
import { Observable, retry, timer } from 'rxjs';
import { switchMap, takeWhile } from 'rxjs/operators';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { JobStatusEnum, JobStatusInterface } from 'core-app/features/job-status/job-status.interface';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { EXTERNAL_REQUEST_HEADER } from 'core-app/features/hal/http/openproject-header-interceptor';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  templateUrl: './job-status.modal.html',
  styleUrls: ['./job-status.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class JobStatusModalComponent extends OpModalComponent implements OnInit {
  public text = {
    title: this.I18n.t('js.job_status.title'),
    closePopup: this.I18n.t('js.close_popup_title'),
    redirect: this.I18n.t('js.job_status.redirect'),
    redirect_errors: `${this.I18n.t('js.job_status.redirect_errors')} `,
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

  /** Additional html to render */
  public htmlContent:SafeHtml|null = null;

  /** A link in case the job results in a download */
  public downloadHref:string|null = null;

  @ViewChild('downloadLink') private downloadLink:ElementRef<HTMLInputElement>;

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly toastService:ToastService,
    readonly sanitization:DomSanitizer,
    readonly httpClient:HttpClient,
  ) {
    super(locals, cdRef, elementRef);

    this.jobId = locals.jobId as string;
  }

  ngOnInit() {
    super.ngOnInit();
    this.listenOnJobStatus();
  }

  private listenOnJobStatus() {
    this.loadingIndicator.indicator('modal').start();
    timer(0, 2000)
      .pipe(
        switchMap(() => this.performRequest()),
        retry({
          count: 10,
          delay: (error:HttpErrorResponse) => {
            // Example for catching specific error code as well
            if ([502, 503, 504].includes(error.status)) {
              return timer(2000);
            }

            // eslint-disable-next-line @typescript-eslint/no-throw-literal
            throw error;
          },
        }),
        takeWhile((response) => !!response.body && this.continuedStatus(response.body), true),
        this.untilDestroyed(),
      )
      .subscribe({
        next: (response) => this.onResponse(response),
        error: (error:HttpErrorResponse) => this.handleError(error),
        complete: () => {
          this.loadingIndicator.indicator('modal').stop();
          this.isLoading = false;
        },
      });
  }

  private iconForStatus():string|null {
    switch (this.status) {
      case 'cancelled':
      case 'failure':
      case 'error':
        return 'icon-error';
        break;
      case 'success':
        return 'icon-checkmark';
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
    const { body } = response;

    if (!body) {
      throw new Error(response?.statusText || 'Internal Error');
    }

    // eslint-disable-next-line no-multi-assign
    const status = this.status = body.status;

    this.message = body.message
      || this.I18n.t(`js.job_status.generic_messages.${status}`, { defaultValue: status });

    this.payload = body.payload;
    if (body.payload) {
      this.title = body.payload.title || this.text.title;
      this.handleRedirect(body.payload);
      this.handleDownload(body.payload?.download);
      this.handleHTML(body.payload?.html);
    }

    this.statusIcon = this.iconForStatus();
    this.cdRef.detectChanges();
  }

  private handleHTML(content?:string) {
    if (content) {
      this.htmlContent = this.sanitization.bypassSecurityTrustHtml(content);
    }
  }

  private handleRedirect(payload:JobStatusInterface['payload']) {
    if (payload?.redirect && !payload?.errors) {
      setTimeout(() => { window.location.href = payload.redirect as string; }, 2000);
      this.message += `. ${this.text.redirect}`;
    }
  }

  private handleDownload(redirectionUrl?:string) {
    if (redirectionUrl !== undefined) {
      // Get the file url from the redirectionUrl
      this.httpClient
        .get(redirectionUrl, {
          observe: 'response',
          responseType: 'text',
          // This might or might not be an external request (depending on the configuration of an S3 storage)
          // But not having headers like X-CSRF-TOKEN set works in both cases.
          headers: {
            [EXTERNAL_REQUEST_HEADER]: 'true',
          },
        })
        .subscribe((response) => {
          this.downloadHref = response.url;

          this.cdRef.detectChanges();
          this.downloadLink.nativeElement.click();
        }, (error:HttpErrorResponse) => {
          // In this case, most typically, there is a CORS error.
          // Instead of failing completely, we show a manual link for the user to click themselves.
          if (error.status === 0) {
            this.downloadHref = redirectionUrl;

            this.cdRef.detectChanges();
          }
        });
    }
  }

  private performRequest():Observable<HttpResponse<JobStatusInterface>> {
    return this
      .httpClient
      .get<JobStatusInterface>(
        this.jobUrl,
        { observe: 'response', responseType: 'json' },
      );
  }

  private handleError(error:HttpErrorResponse) {
    if (error?.status === 404) {
      this.statusIcon = 'icon-help';
      this.message = this.I18n.t('js.job_status.generic_messages.not_found');
    } else {
      this.statusIcon = 'icon-error';
      this.message = error?.message || this.I18n.t('js.error.internal');
      this.toastService.addError(this.message);
    }

    this.cdRef.detectChanges();
  }

  private get jobUrl():string {
    return this.apiV3Service.job_statuses.id(this.jobId).toString();
  }
}
