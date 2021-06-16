import { Component, OnInit, ChangeDetectionStrategy, Input } from '@angular/core';
import { InAppNotification } from "core-app/features/in-app-notifications/store/in-app-notification.model";

@Component({
  selector: 'op-in-app-notification-entry',
  templateUrl: './in-app-notification-entry.component.html',
  styleUrls: ['./in-app-notification-entry.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class InAppNotificationEntryComponent implements OnInit {
  @Input() notification:InAppNotification;

  constructor() { }

  ngOnInit(): void {
  }

}
