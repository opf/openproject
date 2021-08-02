import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { InAppNotificationBellComponent } from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { InAppNotificationEntryComponent } from 'core-app/features/in-app-notifications/entry/in-app-notification-entry.component';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { UIRouterModule } from '@uirouter/angular';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { IAN_ROUTES } from 'core-app/features/in-app-notifications/in-app-notifications.routes';
import { InAppNotificationCenterComponent } from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import { InAppNotificationToolbarComponent } from "core-app/features/in-app-notifications/center/toolbar/in-app-notification-toolbar.component";

@NgModule({
  declarations: [
    InAppNotificationBellComponent,
    InAppNotificationCenterComponent,
    InAppNotificationEntryComponent,
    InAppNotificationToolbarComponent,
  ],
  imports: [
    // Routes for /backlogs
    UIRouterModule.forChild({
      states: IAN_ROUTES,
    }),
    CommonModule,
    IconModule,
    OpenprojectModalModule,
    OpenprojectPrincipalRenderingModule,
    ScrollingModule,
  ],
})
export class OpenProjectInAppNotificationsModule {
}
