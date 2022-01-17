import { Component, OnInit, ChangeDetectionStrategy } from '@angular/core';

@Component({
  selector: 'op-quick-add-pane',
  templateUrl: './quick-add-pane.component.html',
  styleUrls: ['./quick-add-pane.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class QuickAddPaneComponent implements OnInit {

  constructor() { }

  ngOnInit(): void {
  }

}
