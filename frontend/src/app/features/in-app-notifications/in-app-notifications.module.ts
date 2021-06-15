import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconModule } from "core-app/shared/components/icon/icon.module";
import { InAppNotificationBellComponent } from "core-app/features/in-app-notifications/bell/in-app-notification-bell.component";

@NgModule({
  declarations: [
    InAppNotificationBellComponent,
  ],
  imports: [
    CommonModule,
    IconModule,
  ]
})
export class OpenProjectInAppNotificationsModule { }
