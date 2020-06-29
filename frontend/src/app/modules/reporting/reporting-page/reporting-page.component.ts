import {Component, OnInit, ViewEncapsulation} from "@angular/core";

export const reportingPageComponentSelector = 'op-reporting-page';

@Component({
  selector: reportingPageComponentSelector,
  // Empty wrapper around legacy backlogs for CSS loading
  // that got removed in the Rails assets pipeline
  encapsulation: ViewEncapsulation.None,
  template: '',
  styleUrls: [
    './styles/reporting.sass'
  ]
})
export class ReportingPageComponent implements OnInit {
  ngOnInit() {
    document.getElementById('projected-content')!.hidden = false;
  }
}