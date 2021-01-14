import {Component, ElementRef, OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'op-ium-message',
  templateUrl: './message.component.html',
  styleUrls: ['./message.component.sass'],
})
export class InviteMessageComponent implements OnInit {
  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef) {}

  ngOnInit() {
  }
}
