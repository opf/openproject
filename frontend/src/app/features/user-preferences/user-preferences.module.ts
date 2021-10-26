import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { OPSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { NotificationsSettingsPageComponent } from 'core-app/features/user-preferences/notifications-settings/page/notifications-settings-page.component';
import { NotificationSettingInlineCreateComponent } from 'core-app/features/user-preferences/notifications-settings/inline-create/notification-setting-inline-create.component';
import { MY_ACCOUNT_ROUTES } from 'core-app/features/user-preferences/user-preferences.routes';
import { NotificationsSettingsToolbarComponent } from './notifications-settings/toolbar/notifications-settings-toolbar.component';
import { NotificationSettingsTableComponent } from './notifications-settings/table/notification-settings-table.component';
import { ReminderSettingsPageComponent } from './reminder-settings/page/reminder-settings-page.component';
import { ReminderSettingsDailyTimeComponent } from 'core-app/features/user-preferences/reminder-settings/reminder-time/reminder-settings-daily-time.component';
import { ImmediateReminderSettingsComponent } from 'core-app/features/user-preferences/reminder-settings/immediate-reminders/immediate-reminder-settings.component';
import { EmailAlertsSettingsComponent } from 'core-app/features/user-preferences/reminder-settings/email-alerts/email-alerts-settings.component';
import { WorkdaysSettingsComponent } from './reminder-settings/workdays/workdays-settings.component';
import { PauseRemindersComponent } from './reminder-settings/pause-reminders/pause-reminders.component';

@NgModule({
  providers: [
    UserPreferencesService,
  ],
  declarations: [
    NotificationsSettingsPageComponent,
    NotificationSettingInlineCreateComponent,
    NotificationsSettingsToolbarComponent,
    NotificationSettingsTableComponent,
    ReminderSettingsPageComponent,
    ReminderSettingsDailyTimeComponent,
    ImmediateReminderSettingsComponent,
    EmailAlertsSettingsComponent,
    WorkdaysSettingsComponent,
    PauseRemindersComponent,
  ],
  imports: [
    CommonModule,
    OPSharedModule,
    OpenprojectAutocompleterModule,
    FormsModule,
    ReactiveFormsModule,
    // Routes for /my/*
    UIRouterModule.forChild({
      states: MY_ACCOUNT_ROUTES,
    }),
  ],
})
export class OpenProjectMyAccountModule { }
