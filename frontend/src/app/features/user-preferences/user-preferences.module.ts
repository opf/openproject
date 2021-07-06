import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { OPSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { NotificationsSettingsPageComponent } from 'core-app/features/user-preferences/notifications-settings/page/notifications-settings-page.component';
import { NotificationSettingRowComponent } from 'core-app/features/user-preferences/notifications-settings/row/notification-setting-row.component';
import { NotificationSettingInlineCreateComponent } from 'core-app/features/user-preferences/notifications-settings/inline-create/notification-setting-inline-create.component';
import { MY_ACCOUNT_ROUTES } from 'core-app/features/user-preferences/user-preferences.routes';
import { NotificationsSettingsToolbarComponent } from './notifications-settings/toolbar/notifications-settings-toolbar.component';
import { NotificationSettingsTableComponent } from './notifications-settings/table/notification-settings-table.component';

@NgModule({
  providers: [
    UserPreferencesStore,
    UserPreferencesQuery,
    UserPreferencesService,
  ],
  declarations: [
    NotificationsSettingsPageComponent,
    NotificationSettingRowComponent,
    NotificationSettingInlineCreateComponent,
    NotificationsSettingsToolbarComponent,
    NotificationSettingsTableComponent,
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
