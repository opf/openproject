import { AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, Input, OnDestroy } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { JobStatusModalComponent } from 'core-app/features/job-status/job-status-modal/job-status.modal';
import { take } from 'rxjs/operators';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

@Component({
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DisplayJobPageComponent implements AfterViewInit, OnDestroy {
  @Input() jobId:string;

  constructor(
    readonly elementRef:ElementRef,
    readonly modalService:OpModalService,
  ) {
    populateInputsFromDataset(this);
  }

  ngAfterViewInit() {
    this.modalService.show(JobStatusModalComponent, 'global', { jobId: this.jobId })
      .subscribe((modal) => modal
        .closingEvent
        .pipe(
          take(1),
        ).subscribe(() => {
          // Go back in history
          window.history.back();
        }));
  }

  ngOnDestroy() {
    this.modalService.close();
  }
}
