import {AfterViewInit, Component, Injector, OnDestroy} from "@angular/core";
import {StateService} from "@uirouter/core";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {JobStatusModal} from "core-app/modules/job-status/job-status-modal/job-status.modal";
import {take} from "rxjs/operators";

@Component({
  template: ''
})
export class DisplayJobPageComponent implements AfterViewInit, OnDestroy {
  private modal?:OpModalComponent;

  constructor(private injector:Injector,
              private $state:StateService,
              private modalService:OpModalService) {
  }

  ngAfterViewInit() {
    this.modal = this.modalService.show(JobStatusModal, this.injector, { jobId: this.$state.params.jobId });
    this.modal
      .closingEvent
      .pipe(
        take(1)
      ).subscribe(() => {
        // Go back in history
        window.history.back();
    });
  }

  ngOnDestroy() {
    this.modal?.closeMe();
  }
}