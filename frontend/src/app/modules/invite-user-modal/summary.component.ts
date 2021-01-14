import {Component, ElementRef, OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-summary',
  templateUrl: './summary.component.html',
  styleUrls: ['./summary.component.sass'],
})
export class InviteSummaryComponent implements OnInit {
  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef) {}

  ngOnInit() {
  }
}
