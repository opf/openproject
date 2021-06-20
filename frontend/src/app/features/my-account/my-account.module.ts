import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from "@uirouter/angular";
import { MY_ACCOUNT_ROUTES } from "core-app/features/my-account/my-account.routes";
import { MyNotificationsPageComponent } from "core-app/features/my-account/my-notifications-page/my-notifications-page.component";
import { OpenprojectTabsModule } from "core-app/shared/components/tabs/openproject-tabs.module";
import { InAppNotificationsTabComponent } from './my-notifications-page/in-app-notifications-tab/in-app-notifications-tab.component';
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { OpenprojectFieldsModule } from "core-app/shared/components/fields/openproject-fields.module";
import { OPSharedModule } from "core-app/shared/shared.module";


@NgModule({
  declarations: [
    MyNotificationsPageComponent,
    InAppNotificationsTabComponent
  ],
  imports: [
    CommonModule,
    OpenprojectTabsModule,
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
