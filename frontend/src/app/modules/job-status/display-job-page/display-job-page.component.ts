import {Component} from "@angular/core";
import {StateService} from "@uirouter/core";

@Component({
  templateUrl: './display-job-page.component.html'
})
export class DisplayJobPageComponent {
  jobId:string = this.$state.params.jobId;

  constructor(private $state:StateService) {
  }
}