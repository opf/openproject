import { NgModule } from '@angular/core';
import { OPSharedModule } from 'core-app/shared/shared.module';
import { CommonModule } from '@angular/common';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { InAppNotificationBellComponent } from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import { InAppNotificationEntryComponent } from 'core-app/features/in-app-notifications/entry/in-app-notification-entry.component';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { UIRouterModule } from '@uirouter/angular';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { IAN_ROUTES } from 'core-app/features/in-app-notifications/in-app-notifications.routes';
import { InAppNotificationCenterComponent } from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import { InAppNotificationCenterPageComponent } from 'core-app/features/in-app-notifications/center/in-app-notification-center-page.component';
import { IanMenuComponent } from 'core-app/features/in-app-notifications/center/menu/menu.component';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { DynamicModule } from 'ng-dynamic-component';
import { InAppNotificationStatusComponent } from './entry/status/in-app-notification-status.component';
import { NotificationSettingsButtonComponent } from './center/toolbar/settings/notification-settings-button.component';
import { ActivateFacetButtonComponent } from './center/toolbar/facet/activate-facet-button.component';
import { MarkAllAsReadButtonComponent } from './center/toolbar/mark-all-as-read/mark-all-as-read-button.component';
import { OpenprojectContentLoaderModule } from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { EmptyStateComponent } from './center/empty-state/empty-state.component';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

@NgModule({
  declarations: [
    InAppNotificationBellComponent,
    InAppNotificationCenterComponent,
    InAppNotificationEntryComponent,
    InAppNotificationCenterPageComponent,
    InAppNotificationStatusComponent,
    NotificationSettingsButtonComponent,
    ActivateFacetButtonComponent,
    MarkAllAsReadButtonComponent,
    IanMenuComponent,
    EmptyStateComponent,
  ],
  imports: [
    OPSharedModule,
    // Routes for /backlogs
    UIRouterModule.forChild({
      states: IAN_ROUTES,
    }),
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
  ],
})
export class OpenProjectInAppNotificationsModule {
}
