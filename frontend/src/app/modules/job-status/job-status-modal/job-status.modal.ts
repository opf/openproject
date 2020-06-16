import {ChangeDetectorRef, Component, ElementRef, Inject, OnInit} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {HttpClient} from '@angular/common/http';
import {interval, Observable, timer} from "rxjs";
import {map, switchMap, takeUntil, takeWhile} from "rxjs/operators";
import {
  LoadingIndicatorService,
  withDelayedLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {JobStatusEnum, JobStatusInterface} from "core-app/modules/job-status/job-status.interface";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";


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
    exportPreparing: this.I18n.t('js.label_export_preparing')
  };

  /** The job ID reference */
  public jobId:string;

  /** Whether to show the loading indicator */
  public isLoading = false;

  /** The current status */
  public status:JobStatusEnum;

  /** Public message to show */
  public message:string;

  /** A link in case the job results in a download */
  public downloadHref:string|null = null;

  constructor(@Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              readonly elementRef:ElementRef,
              readonly pathHelper:PathHelperService,
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
    this.isLoading = true;

    timer(0, 2000)
      .pipe(
        switchMap(() => this.performRequest()),
        takeWhile(response => this.continuedStatus(response), true),
        this.untilDestroyed(),
        withDelayedLoadingIndicator(this.loadingIndicator.getter('modal')),
      ).subscribe(
        object => this.onResponse(object),
      error => this.handleError(error.message),
      () => this.isLoading = false
    );
  }

  /**
   * Determine whether the given status continues the timer
   * @param response
   */
  private continuedStatus(response:JobStatusInterface) {
    return ['in_queue', 'in_process'].includes(response.status);
  }

  private onResponse(response:JobStatusInterface) {
    let status = this.status = response.status;
    this.message = response.message ||
      this.I18n.t(`js.job_status.generic_messages.${status}`, { defaultValue: status });

    this.cdRef.detectChanges();
  }

  private performRequest():Observable<JobStatusInterface> {
    return this
      .httpClient
      .get<JobStatusInterface>(
        this.jobUrl,
        { observe: 'body', responseType: 'json' }
      );
  }

  private handleError(error:string|null|undefined) {
    this.notifications.addError(error || this.I18n.t('js.error.internal'));
  }

  private get jobUrl():string {
    return this.pathHelper.api.v3.job_statuses.id(this.jobId).toString();
  }
}
