import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from "@uirouter/angular";
import { MY_ACCOUNT_ROUTES } from "core-app/features/my-account/my-account.routes";
import { MyNotificationsPageComponent } from "core-app/features/my-account/my-notifications-page/my-notifications-page.component";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { OPSharedModule } from "core-app/shared/shared.module";
import { NotificationSettingsStore } from "core-app/features/my-account/my-notifications-page/notification-settings.store";
import { MyNotificationsPageService } from "core-app/features/my-account/my-notifications-page/my-notifications-page.service";
import { NotificationSettingsQuery } from "core-app/features/my-account/my-notifications-page/notification-settings.query";

@NgModule({
  providers: [
    NotificationSettingsStore,
    NotificationSettingsQuery,
    MyNotificationsPageService,
  ],
  declarations: [
    MyNotificationsPageComponent
  ],
  imports: [
    CommonModule,
    OPSharedModule,
    FormsModule,
    ReactiveFormsModule,
    // Routes for /my/*
    UIRouterModule.forChild({
      states: MY_ACCOUNT_ROUTES
    }),
  ]
})
export class OpenProjectMyAccountModule { }
