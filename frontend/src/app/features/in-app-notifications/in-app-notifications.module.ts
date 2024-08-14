import { NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { CommonModule } from '@angular/common';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import {
  InAppNotificationBellComponent,
} from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import {
  InAppNotificationEntryComponent,
} from 'core-app/features/in-app-notifications/entry/in-app-notification-entry.component';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { ScrollingModule } from '@angular/cdk/scrolling';
import {
  InAppNotificationCenterComponent,
} from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { DynamicModule } from 'ng-dynamic-component';
import { InAppNotificationStatusComponent } from './entry/status/in-app-notification-status.component';
import {
  OpenprojectContentLoaderModule,
} from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { InAppNotificationActorsLineComponent } from './entry/actors-line/in-app-notification-actors-line.component';
import { InAppNotificationDateAlertComponent } from './entry/date-alert/in-app-notification-date-alert.component';
import {
  InAppNotificationsDateAlertsUpsaleComponent,
} from 'core-app/features/in-app-notifications/date-alerts-upsale/ian-date-alerts-upsale.component';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';

@NgModule({
  declarations: [
    InAppNotificationBellComponent,
    InAppNotificationCenterComponent,
    InAppNotificationEntryComponent,
    InAppNotificationStatusComponent,
    InAppNotificationActorsLineComponent,
    InAppNotificationDateAlertComponent,
    InAppNotificationsDateAlertsUpsaleComponent,
  ],
  imports: [
    OpSharedModule,
    DynamicModule,
    CommonModule,
    IconModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectWorkPackagesModule,
    OpenprojectContentLoaderModule,
    ScrollingModule,
  ],
  providers: [
    IanBellService,
    IanCenterService,
  ],
})
export class OpenProjectInAppNotificationsModule {
}
