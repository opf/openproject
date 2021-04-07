import { Component, OnInit, ViewEncapsulation } from "@angular/core";

export const backlogsPageComponentSelector = 'op-backlogs-page';

@Component({
  selector: backlogsPageComponentSelector,
  // Empty wrapper around legacy backlogs for CSS loading
  // that got removed in the Rails assets pipeline
  encapsulation: ViewEncapsulation.None,
  template: '',
  styleUrls: [
    './styles/backlogs.sass'
  ]
})
export class BacklogsPageComponent implements OnInit {
  ngOnInit() {
    document.getElementById('projected-content')!.hidden = false;
  }
}