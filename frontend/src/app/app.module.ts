//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { APP_INITIALIZER, ApplicationRef, DoBootstrap, Injector, NgModule } from '@angular/core';
import { A11yModule } from '@angular/cdk/a11y';
import { HTTP_INTERCEPTORS, HttpClient, HttpClientModule } from '@angular/common/http';
import { ReactiveFormsModule } from '@angular/forms';
import {
  OpContextMenuTrigger,
} from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { States } from 'core-app/core/states/states.service';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { OpDragScrollDirective } from 'core-app/shared/directives/op-drag-scroll/op-drag-scroll.directive';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { OpenprojectEditorModule } from 'core-app/shared/components/editor/openproject-editor.module';
import { OpenprojectGridsModule } from 'core-app/shared/components/grids/openproject-grids.module';
import { OpenprojectRouterModule } from 'core-app/core/routing/openproject-router.module';
import {
  OpenprojectWorkPackageRoutesModule,
} from 'core-app/features/work-packages/openproject-work-package-routes.module';
import { BrowserModule } from '@angular/platform-browser';
import { OpenprojectCalendarModule } from 'core-app/features/calendar/openproject-calendar.module';
import { OpenprojectGlobalSearchModule } from 'core-app/core/global_search/openproject-global-search.module';
import { OpenprojectDashboardsModule } from 'core-app/features/dashboards/openproject-dashboards.module';
import {
  OpenprojectWorkPackageGraphsModule,
} from 'core-app/shared/components/work-package-graphs/openproject-work-package-graphs.module';
import { PreviewTriggerService } from 'core-app/core/setup/globals/global-listeners/preview-trigger.service';
import { OpenprojectOverviewModule } from 'core-app/features/overview/openproject-overview.module';
import { OpenprojectMyPageModule } from 'core-app/features/my-page/openproject-my-page.module';
import { OpenprojectProjectsModule } from 'core-app/features/projects/openproject-projects.module';
import { KeyboardShortcutService } from 'core-app/shared/directives/a11y/keyboard-shortcut.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import {
  OpenprojectMembersModule,
} from 'core-app/shared/components/autocompleter/members-autocompleter/members.module';
import { OpenprojectAugmentingModule } from 'core-app/core/augmenting/openproject-augmenting.module';
import { OpenprojectInviteUserModalModule } from 'core-app/features/invite-user-modal/invite-user-modal.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import {
  RevitAddInSettingsButtonService,
} from 'core-app/features/bim/revit_add_in/revit-add-in-settings-button.service';
import { OpenprojectEnterpriseModule } from 'core-app/features/enterprise/openproject-enterprise.module';
import { MainMenuToggleComponent } from 'core-app/core/main-menu/main-menu-toggle.component';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogModalComponent } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';
import { DynamicContentModalComponent } from 'core-app/shared/components/modals/modal-wrapper/dynamic-content.modal';
import {
  PasswordConfirmationModalComponent,
} from 'core-app/shared/components/modals/request-for-confirmation/password-confirmation.modal';
import {
  WpPreviewModalComponent,
} from 'core-app/shared/components/modals/preview-modal/wp-preview-modal/wp-preview.modal';
import {
  OpHeaderProjectSelectComponent,
} from 'core-app/shared/components/header-project-select/header-project-select.component';
import {
  OpHeaderProjectSelectListComponent,
} from 'core-app/shared/components/header-project-select/list/header-project-select-list.component';

import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { MainMenuResizerComponent } from 'core-app/shared/components/resizer/resizer/main-menu-resizer.component';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { OpenprojectAdminModule } from 'core-app/features/admin/openproject-admin.module';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { OpenprojectPluginsModule } from 'core-app/features/plugins/openproject-plugins.module';
import { LinkedPluginsModule } from 'core-app/features/plugins/linked-plugins.module';
import {
  OpenProjectInAppNotificationsModule,
} from 'core-app/features/in-app-notifications/in-app-notifications.module';
import { OpenProjectBackupService } from './core/backup/op-backup.service';
import { OpenProjectStateModule } from 'core-app/core/state/openproject-state.module';
import {
  OpenprojectContentLoaderModule,
} from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { OpenProjectHeaderInterceptor } from 'core-app/features/hal/http/openproject-header-interceptor';
import { TopMenuService } from 'core-app/core/top-menu/top-menu.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { FogUploadService } from 'core-app/core/upload/fog-upload.service';
import { LocalUploadService } from 'core-app/core/upload/local-upload.service';
import { registerCustomElement } from 'core-app/shared/helpers/angular/custom-elements.helper';
import {
  EmbeddedTablesMacroComponent,
} from 'core-app/features/work-packages/components/wp-table/embedded/embedded-tables-macro.component';
import { OpPrincipalComponent } from 'core-app/shared/components/principal/principal.component';
import {
  OpBasicSingleDatePickerComponent,
} from 'core-app/shared/components/datepicker/basic-single-date-picker/basic-single-date-picker.component';
import {
  OpBasicRangeDatePickerComponent,
} from 'core-app/shared/components/datepicker/basic-range-date-picker/basic-range-date-picker.component';
import { GlobalSearchInputComponent } from 'core-app/core/global_search/input/global-search-input.component';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import {
  ProjectAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import {
  AutocompleteSelectDecorationComponent,
} from 'core-app/shared/components/autocompleter/autocomplete-select-decoration/autocomplete-select-decoration.component';
import {
  MembersAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/members-autocompleter/members-autocompleter.component';
import {
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { AttributeValueMacroComponent } from 'core-app/shared/components/fields/macros/attribute-value-macro.component';
import { AttributeLabelMacroComponent } from 'core-app/shared/components/fields/macros/attribute-label-macro.component';
import {
  WorkPackageQuickinfoMacroComponent,
} from 'core-app/shared/components/fields/macros/work-package-quickinfo-macro.component';
import {
  CkeditorAugmentedTextareaComponent,
} from 'core-app/shared/components/editor/components/ckeditor-augmented-textarea/ckeditor-augmented-textarea.component';
import {
  DraggableAutocompleteComponent,
} from 'core-app/shared/components/autocompleter/draggable-autocomplete/draggable-autocomplete.component';
import {
  AttributeHelpTextComponent,
} from 'core-app/shared/components/attribute-help-texts/attribute-help-text.component';
import { OpExclusionInfoComponent } from 'core-app/shared/components/fields/display/info/op-exclusion-info.component';
import { NewProjectComponent } from 'core-app/features/projects/components/new-project/new-project.component';
import { CopyProjectComponent } from 'core-app/features/projects/components/copy-project/copy-project.component';
import { ProjectsComponent } from 'core-app/features/projects/components/projects/projects.component';
import { OpenProjectJobStatusModule } from 'core-app/features/job-status/openproject-job-status.module';
import {
  NotificationsSettingsPageComponent,
} from 'core-app/features/user-preferences/notifications-settings/page/notifications-settings-page.component';
import {
  ReminderSettingsPageComponent,
} from 'core-app/features/user-preferences/reminder-settings/page/reminder-settings-page.component';
import { OpenProjectMyAccountModule } from 'core-app/features/user-preferences/user-preferences.module';
import { OpAttachmentsComponent } from 'core-app/shared/components/attachments/attachments.component';
import {
  InAppNotificationCenterComponent,
} from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import {
  WorkPackageSplitViewEntryComponent,
} from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view-entry.component';
import {
  InAppNotificationsDateAlertsUpsaleComponent,
} from 'core-app/features/in-app-notifications/date-alerts-upsale/ian-date-alerts-upsale.component';
import { ShareUpsaleComponent } from 'core-app/features/enterprise/share-upsale/share-upsale.component';
import {
  StorageLoginButtonComponent,
} from 'core-app/shared/components/storages/storage-login-button/storage-login-button.component';
import { OpCustomModalOverlayComponent } from 'core-app/shared/components/modal/custom-modal-overlay.component';
import { TimerAccountMenuComponent } from 'core-app/shared/components/time_entries/timer/timer-account-menu.component';
import {
  RemoteFieldUpdaterComponent,
} from 'core-app/shared/components/remote-field-updater/remote-field-updater.component';
import {
  OpModalSingleDatePickerComponent,
} from 'core-app/shared/components/datepicker/modal-single-date-picker/modal-single-date-picker.component';
import { SpotDropModalPortalComponent } from 'core-app/spot/components/drop-modal/drop-modal-portal.component';
import { OpModalOverlayComponent } from 'core-app/shared/components/modal/modal-overlay.component';
import {
  InAppNotificationBellComponent,
} from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import { BackupComponent } from 'core-app/core/setup/globals/components/admin/backup.component';
import {
  EditableQueryPropsComponent,
} from 'core-app/features/admin/editable-query-props/editable-query-props.component';
import {
  TriggerActionsEntryComponent,
} from 'core-app/shared/components/time_entries/edit/trigger-actions-entry.component';
import {
  WorkPackageOverviewGraphComponent,
} from 'core-app/shared/components/work-package-graphs/overview/wp-overview-graph.component';
import {
  EEActiveSavedTrialComponent,
} from 'core-app/features/enterprise/enterprise-active-trial/ee-active-saved-trial.component';
import { FreeTrialButtonComponent } from 'core-app/features/enterprise/free-trial-button/free-trial-button.component';
import { EnterpriseBaseComponent } from 'core-app/features/enterprise/enterprise-base.component';
import { NoResultsComponent } from 'core-app/shared/components/no-results/no-results.component';
import {
  OpNonWorkingDaysListComponent,
} from 'core-app/shared/components/op-non-working-days-list/op-non-working-days-list.component';
import { EnterpriseBannerComponent } from 'core-app/shared/components/enterprise-banner/enterprise-banner.component';
import {
  CollapsibleSectionComponent,
} from 'core-app/shared/components/collapsible-section/collapsible-section.component';
import { CopyToClipboardComponent } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.component';
import { GlobalSearchTitleComponent } from 'core-app/core/global_search/title/global-search-title.component';
import { ContentTabsComponent } from 'core-app/shared/components/tabs/content-tabs/content-tabs.component';
import {
  AddSectionDropdownComponent,
} from 'core-app/shared/components/hide-section/add-section-dropdown/add-section-dropdown.component';
import {
  HideSectionLinkComponent,
} from 'core-app/shared/components/hide-section/hide-section-link/hide-section-link.component';
import { PersistentToggleComponent } from 'core-app/shared/components/persistent-toggle/persistent-toggle.component';
import { TypeFormConfigurationComponent } from 'core-app/features/admin/types/type-form-configuration.component';
import { ToastsContainerComponent } from 'core-app/shared/components/toaster/toasts-container.component';
import { GlobalSearchWorkPackagesComponent } from 'core-app/core/global_search/global-search-work-packages.component';
import {
  CustomDateActionAdminComponent,
} from 'core-app/features/work-packages/components/wp-custom-actions/date-action/custom-date-action-admin.component';
import { HomescreenNewFeaturesBlockComponent } from 'core-app/features/homescreen/blocks/new-features.component';
import { GlobalSearchTabsComponent } from 'core-app/core/global_search/tabs/global-search-tabs.component';
import {
  ZenModeButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { ColorsAutocompleterComponent } from 'core-app/shared/components/colors/colors-autocompleter.component';
import {
  StaticAttributeHelpTextComponent,
} from 'core-app/shared/components/attribute-help-texts/static-attribute-help-text.component';
import { appBaseSelector, ApplicationBaseComponent } from 'core-app/core/routing/base/application-base.component';
import { SpotSwitchComponent } from 'core-app/spot/components/switch/switch.component';

export function initializeServices(injector:Injector) {
  return () => {
    const PreviewTrigger = injector.get(PreviewTriggerService);
    const topMenuService = injector.get(TopMenuService);
    const keyboardShortcuts = injector.get(KeyboardShortcutService);
    // Conditionally add the Revit Add-In settings button
    injector.get(RevitAddInSettingsButtonService);

    topMenuService.register();

    PreviewTrigger.setupListener();

    keyboardShortcuts.register();

    return injector.get(ConfigurationService).initialize();
  };
}

@NgModule({
  imports: [
    // The BrowserModule must only be loaded here!
    BrowserModule,
    A11yModule,

    // Commons
    OpSharedModule,
    // Design System
    OpSpotModule,
    // State module
    OpenProjectStateModule,
    // Router module
    OpenprojectRouterModule,
    // Hal Module
    OpenprojectHalModule,
    OpenProjectJobStatusModule,

    // CKEditor
    OpenprojectEditorModule,
    // Display + Edit field functionality
    OpenprojectFieldsModule,
    OpenprojectGridsModule,
    OpenprojectAttachmentsModule,

    // Project module
    OpenprojectProjectsModule,

    // Work packages and their routes
    OpenprojectWorkPackagesModule,
    OpenprojectWorkPackageRoutesModule,

    // Work packages in graph representation
    OpenprojectWorkPackageGraphsModule,

    // Calendar module
    OpenprojectCalendarModule,

    // Dashboards
    OpenprojectDashboardsModule,

    // Overview
    OpenprojectOverviewModule,

    // MyPage
    OpenprojectMyPageModule,

    // Global Search
    OpenprojectGlobalSearchModule,

    // Admin module
    OpenprojectAdminModule,
    OpenprojectEnterpriseModule,

    // Plugin hooks and modules
    OpenprojectPluginsModule,
    // Linked plugins dynamically generated by bundler
    LinkedPluginsModule,

    // Members
    OpenprojectMembersModule,

    // Angular Forms
    ReactiveFormsModule,

    // Angular Http Client
    HttpClientModule,

    // Augmenting Module
    OpenprojectAugmentingModule,

    // Modals
    OpenprojectModalModule,

    // Invite user modal
    OpenprojectInviteUserModalModule,

    // Tabs
    OpenprojectTabsModule,

    // Notifications
    OpenProjectInAppNotificationsModule,

    // Loading
    OpenprojectContentLoaderModule,

    // My account
    OpenProjectMyAccountModule,
  ],
  providers: [
    { provide: States, useValue: new States() },
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
    {
      provide: APP_INITIALIZER, useFactory: initializeServices, deps: [Injector], multi: true,
    },
    {
      provide: OpUploadService,
      useFactory: (config:ConfigurationService, http:HttpClient) =>
        (config.isDirectUploads() ? new FogUploadService(http) : new LocalUploadService(http)),
      deps: [ConfigurationService, HttpClient],
    },
    PaginationService,
    OpenProjectBackupService,
    ConfirmDialogService,
    RevitAddInSettingsButtonService,
    CopyToClipboardService,
  ],
  declarations: [
    OpContextMenuTrigger,

    // Modals
    ConfirmDialogModalComponent,
    DynamicContentModalComponent,
    PasswordConfirmationModalComponent,
    WpPreviewModalComponent,

    // Main menu
    MainMenuResizerComponent,
    MainMenuToggleComponent,

    // Project selector
    OpHeaderProjectSelectComponent,
    OpHeaderProjectSelectListComponent,

    // Form configuration
    OpDragScrollDirective,
  ],
})
export class OpenProjectModule implements DoBootstrap {
  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap(appRef:ApplicationRef) {
    // Try to bootstrap a dynamic root element
    const root = document.querySelector(appBaseSelector);
    if (root) {
      appRef.bootstrap(ApplicationBaseComponent, root);
    }

    this.registerCustomElements(appRef.injector);
  }

  private registerCustomElements(injector:Injector) {
    registerCustomElement('opce-macro-embedded-table', EmbeddedTablesMacroComponent, { injector });
    registerCustomElement('opce-principal', OpPrincipalComponent, { injector });
    registerCustomElement('opce-single-date-picker', OpBasicSingleDatePickerComponent, { injector });
    registerCustomElement('opce-range-date-picker', OpBasicRangeDatePickerComponent, { injector });
    registerCustomElement('opce-global-search', GlobalSearchInputComponent, { injector });
    registerCustomElement('opce-autocompleter', OpAutocompleterComponent, { injector });
    registerCustomElement('opce-project-autocompleter', ProjectAutocompleterComponent, { injector });
    registerCustomElement('opce-select-decoration', AutocompleteSelectDecorationComponent, { injector });
    registerCustomElement('opce-members-autocompleter', MembersAutocompleterComponent, { injector });
    registerCustomElement('opce-user-autocompleter', UserAutocompleterComponent, { injector });
    registerCustomElement('opce-macro-attribute-value', AttributeValueMacroComponent, { injector });
    registerCustomElement('opce-macro-attribute-label', AttributeLabelMacroComponent, { injector });
    registerCustomElement('opce-macro-wp-quickinfo', WorkPackageQuickinfoMacroComponent, { injector });
    registerCustomElement('opce-ckeditor-augmented-textarea', CkeditorAugmentedTextareaComponent, { injector });
    registerCustomElement('opce-draggable-autocompleter', DraggableAutocompleteComponent, { injector });
    registerCustomElement('opce-attribute-help-text', AttributeHelpTextComponent, { injector });
    registerCustomElement('opce-static-attribute-help-text', StaticAttributeHelpTextComponent, { injector });
    registerCustomElement('opce-exclusion-info', OpExclusionInfoComponent, { injector });
    registerCustomElement('opce-attachments', OpAttachmentsComponent, { injector });
    registerCustomElement('opce-storage-login-button', StorageLoginButtonComponent, { injector });
    registerCustomElement('opce-custom-modal-overlay', OpCustomModalOverlayComponent, { injector });

    // TODO: These elements are now registered custom elements, but are actually single-use components. They should be removed when we move these pages to Rails.
    registerCustomElement('opce-new-project', NewProjectComponent, { injector });
    registerCustomElement('opce-project-settings', ProjectsComponent, { injector });
    registerCustomElement('opce-copy-project', CopyProjectComponent, { injector });
    registerCustomElement('opce-notification-settings', NotificationsSettingsPageComponent, { injector });
    registerCustomElement('opce-reminder-settings', ReminderSettingsPageComponent, { injector });
    registerCustomElement('opce-notification-center', InAppNotificationCenterComponent, { injector });
    registerCustomElement('opce-ian-date-alerts-upsale', InAppNotificationsDateAlertsUpsaleComponent, { injector });
    registerCustomElement('opce-share-upsale', ShareUpsaleComponent, { injector });
    registerCustomElement('opce-wp-split-view', WorkPackageSplitViewEntryComponent, { injector });
    registerCustomElement('opce-timer-account-menu', TimerAccountMenuComponent, { injector });
    registerCustomElement('opce-remote-field-updater', RemoteFieldUpdaterComponent, { injector });
    registerCustomElement('opce-modal-single-date-picker', OpModalSingleDatePickerComponent, { injector });
    registerCustomElement('opce-basic-single-date-picker', OpBasicSingleDatePickerComponent, { injector });
    registerCustomElement('opce-storage-login-button', StorageLoginButtonComponent, { injector });
    registerCustomElement('opce-spot-drop-modal-portal', SpotDropModalPortalComponent, { injector });
    registerCustomElement('opce-spot-switch', SpotSwitchComponent, { injector });
    registerCustomElement('opce-modal-overlay', OpModalOverlayComponent, { injector });
    registerCustomElement('opce-in-app-notification-bell', InAppNotificationBellComponent, { injector });
    registerCustomElement('opce-backup', BackupComponent, { injector });
    registerCustomElement('opce-editable-query-props', EditableQueryPropsComponent, { injector });
    registerCustomElement('opce-time-entry-trigger-actions', TriggerActionsEntryComponent, { injector });
    registerCustomElement('opce-wp-overview-graph', WorkPackageOverviewGraphComponent, { injector });
    registerCustomElement('opce-header-project-select', OpHeaderProjectSelectComponent, { injector });
    registerCustomElement('opce-enterprise-active-saved-trial', EEActiveSavedTrialComponent, { injector });
    registerCustomElement('opce-free-trial-button', FreeTrialButtonComponent, { injector });
    registerCustomElement('opce-enterprise-base', EnterpriseBaseComponent, { injector });
    registerCustomElement('opce-no-results', NoResultsComponent, { injector });
    registerCustomElement('opce-non-working-days-list', OpNonWorkingDaysListComponent, { injector });
    registerCustomElement('opce-enterprise-banner', EnterpriseBannerComponent, { injector });
    registerCustomElement('opce-collapsible-section-augment', CollapsibleSectionComponent, { injector });
    registerCustomElement('opce-main-menu-toggle', MainMenuToggleComponent, { injector });
    registerCustomElement('opce-main-menu-resizer', MainMenuResizerComponent, { injector });
    registerCustomElement('opce-copy-to-clipboard', CopyToClipboardComponent, { injector });
    registerCustomElement('opce-global-search-title', GlobalSearchTitleComponent, { injector });
    registerCustomElement('opce-content-tabs', ContentTabsComponent, { injector });
    registerCustomElement('opce-add-section-dropdown', AddSectionDropdownComponent, { injector });
    registerCustomElement('opce-hide-section-link', HideSectionLinkComponent, { injector });
    registerCustomElement('opce-persistent-toggle', PersistentToggleComponent, { injector });
    registerCustomElement('opce-admin-type-form-configuration', TypeFormConfigurationComponent, { injector });
    registerCustomElement('opce-toasts-container', ToastsContainerComponent, { injector });
    registerCustomElement('opce-global-search-work-packages', GlobalSearchWorkPackagesComponent, { injector });
    registerCustomElement('opce-custom-date-action-admin', CustomDateActionAdminComponent, { injector });
    registerCustomElement('opce-homescreen-new-features-block', HomescreenNewFeaturesBlockComponent, { injector });
    registerCustomElement('opce-global-search-tabs', GlobalSearchTabsComponent, { injector });
    registerCustomElement('opce-zen-mode-toggle-button', ZenModeButtonComponent, { injector });
    registerCustomElement('opce-colors-autocompleter', ColorsAutocompleterComponent, { injector });
  }
}
