import {
  AfterViewInit, Component, OnDestroy,
} from '@angular/core';
import { StateService } from '@uirouter/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { JobStatusModalComponent } from 'core-app/features/job-status/job-status-modal/job-status.modal';
import { take } from 'rxjs/operators';

@Component({
  template: '',
})
export class DisplayJobPageComponent implements AfterViewInit, OnDestroy {
  private modal?:OpModalComponent;

  constructor(private $state:StateService,
    private modalService:OpModalService) {
  }

  ngAfterViewInit() {
    this.modal = this.modalService.show(JobStatusModalComponent, 'global', { jobId: this.$state.params.jobId });
    this.modal
      .closingEvent
      .pipe(
        take(1),
      ).subscribe(() => {
        // Go back in history
        window.history.back();
      });
  }

  ngOnDestroy() {
    this.modal?.closeMe();
  }
}
