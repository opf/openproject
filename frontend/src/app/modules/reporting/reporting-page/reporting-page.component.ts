import { Component, OnInit, ViewEncapsulation } from "@angular/core";
import { registerTableSorter } from "core-app/modules/reporting/reporting-page/functionality/tablesorter";

export const reportingPageComponentSelector = 'op-reporting-page';

import './functionality/reporting_engine';
import './functionality/reporting_engine/filters';
import './functionality/reporting_engine/group_bys';
import './functionality/reporting_engine/restore_query';
import './functionality/reporting_engine/controls';


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

    // Register table sorting functionality after reporting engine loaded
    registerTableSorter();
  }
}