import { Component, OnInit, ChangeDetectionStrategy, HostListener } from '@angular/core';

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationBellComponent implements OnInit {
  constructor() { }

  ngOnInit(): void {
  }

}
