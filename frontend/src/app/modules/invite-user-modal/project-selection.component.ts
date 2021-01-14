import {Component, ElementRef, OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  templateUrl: './project-selection.component.html',
  styleUrls: ['./project-selection.component.sass'],
})
export class InviteProjectSelectionComponent implements OnInit {
  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef) {}

  ngOnInit() {
  }
}
