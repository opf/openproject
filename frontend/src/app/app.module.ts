// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import {
  APP_INITIALIZER,
  ApplicationRef,
  Injector,
  NgModule,
} from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { States } from 'core-app/core/states/states.service';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import { OPSharedModule } from 'core-app/shared/shared.module';
import { OpDragScrollDirective } from 'core-app/shared/directives/op-drag-scroll/op-drag-scroll.directive';
import { DynamicBootstrapper } from 'core-app/core/setup/globals/dynamic-bootstrapper';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { OpenprojectEditorModule } from 'core-app/shared/components/editor/openproject-editor.module';
import { OpenprojectGridsModule } from 'core-app/shared/components/grids/openproject-grids.module';
import { OpenprojectRouterModule } from 'core-app/core/routing/openproject-router.module';
import { OpenprojectWorkPackageRoutesModule } from 'core-app/features/work-packages/openproject-work-package-routes.module';
import { BrowserModule } from '@angular/platform-browser';
import { OpenprojectCalendarModule } from 'core-app/features/calendar/openproject-calendar.module';
import { OpenprojectGlobalSearchModule } from 'core-app/core/global_search/openproject-global-search.module';
import { OpenprojectDashboardsModule } from 'core-app/features/dashboards/openproject-dashboards.module';
import { OpenprojectWorkPackageGraphsModule } from 'core-app/shared/components/work-package-graphs/openproject-work-package-graphs.module';
import { PreviewTriggerService } from 'core-app/core/setup/globals/global-listeners/preview-trigger.service';
import { OpenprojectOverviewModule } from 'core-app/features/overview/openproject-overview.module';
import { OpenprojectMyPageModule } from 'core-app/features/my-page/openproject-my-page.module';
import { OpenprojectProjectsModule } from 'core-app/features/projects/openproject-projects.module';
import { KeyboardShortcutService } from 'core-app/shared/directives/a11y/keyboard-shortcut.service';
import { OpenprojectMembersModule } from 'core-app/shared/components/autocompleter/members-autocompleter/members.module';
import { OpenprojectAugmentingModule } from 'core-app/core/augmenting/openproject-augmenting.module';
import { OpenprojectInviteUserModalModule } from 'core-app/features/invite-user-modal/invite-user-modal.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { RevitAddInSettingsButtonService } from 'core-app/features/bim/revit_add_in/revit-add-in-settings-button.service';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { OpenProjectFileUploadService } from 'core-app/core/file-upload/op-file-upload.service';
import { OpenprojectEnterpriseModule } from 'core-app/features/enterprise/openproject-enterprise.module';
import { MainMenuToggleComponent } from 'core-app/core/main-menu/main-menu-toggle.component';
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogModalComponent } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';
import { DynamicContentModalComponent } from 'core-app/shared/components/modals/modal-wrapper/dynamic-content.modal';
import { PasswordConfirmationModalComponent } from 'core-app/shared/components/modals/request-for-confirmation/password-confirmation.modal';
import { WpPreviewModalComponent } from 'core-app/shared/components/modals/preview-modal/wp-preview-modal/wp-preview.modal';
import { ConfirmFormSubmitController } from 'core-app/shared/components/modals/confirm-form-submit/confirm-form-submit.directive';
import { ProjectMenuAutocompleteComponent } from 'core-app/shared/components/autocompleter/project-menu-autocomplete/project-menu-autocomplete.component';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { MainMenuResizerComponent } from 'core-app/shared/components/resizer/resizer/main-menu-resizer.component';
import { CommentService } from 'core-app/features/work-packages/components/wp-activity/comment-service';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { OpenprojectAdminModule } from 'core-app/features/admin/openproject-admin.module';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { globalDynamicComponents } from 'core-app/core/setup/global-dynamic-components.const';
import { HookService } from 'core-app/features/plugins/hook-service';
import { OpenprojectPluginsModule } from 'core-app/features/plugins/openproject-plugins.module';
import { LinkedPluginsModule } from 'core-app/features/plugins/linked-plugins.module';
import { OpenProjectInAppNotificationsModule } from 'core-app/features/in-app-notifications/in-app-notifications.module';
import { OpenProjectBackupService } from './core/backup/op-backup.service';
import { OpenProjectDirectFileUploadService } from './core/file-upload/op-direct-file-upload.service';
import { OpenProjectStateModule } from 'core-app/core/state/openproject-state.module';

export function initializeServices(injector:Injector) {
  return () => {
    const PreviewTrigger = injector.get(PreviewTriggerService);
    const mainMenuNavigationService = injector.get(MainMenuNavigationService);
    const keyboardShortcuts = injector.get(KeyboardShortcutService);
    // Conditionally add the Revit Add-In settings button
    injector.get(RevitAddInSettingsButtonService);

    mainMenuNavigationService.register();

    PreviewTrigger.setupListener();

    keyboardShortcuts.register();
  };
}

@NgModule({
  imports: [
    // The BrowserModule must only be loaded here!
    BrowserModule,
    // Commons
    OPSharedModule,
    // State module
    OpenProjectStateModule,
    // Router module
    OpenprojectRouterModule,
    // Hal Module
    OpenprojectHalModule,

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

    // Augmenting Module
    OpenprojectAugmentingModule,

    // Modals
    OpenprojectModalModule,

    // Invite user modal
    OpenprojectInviteUserModalModule,

    // Autocompleters
    OpenprojectAutocompleterModule,

    // Tabs
    OpenprojectTabsModule,

    // Notifications
    OpenProjectInAppNotificationsModule,
  ],
  providers: [
    { provide: States, useValue: new States() },
    {
      provide: APP_INITIALIZER, useFactory: initializeServices, deps: [Injector], multi: true,
    },
    PaginationService,
    OpenProjectBackupService,
    OpenProjectFileUploadService,
    OpenProjectDirectFileUploadService,
    // Split view
    CommentService,
    ConfirmDialogService,
    RevitAddInSettingsButtonService,
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

    // Project autocompleter
    ProjectMenuAutocompleteComponent,

    // Form configuration
    OpDragScrollDirective,
    ConfirmFormSubmitController,
  ],
})
export class OpenProjectModule {
  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap(appRef:ApplicationRef) {
    // Register global dynamic components
    // this is necessary to ensure they are not tree-shaken
    // (if they are not used anywhere in Angular, they would be removed)
    DynamicBootstrapper.register(...globalDynamicComponents);

    // Perform global dynamic bootstrapping of our entry components
    // that are in the current DOM response.
    DynamicBootstrapper.bootstrapOptionalDocument(appRef, document);

    // Call hook service to allow modules to bootstrap additional elements.
    // We can't use ngDoBootstrap in nested modules since they are not called.
    const hookService = (appRef as any)._injector.get(HookService);
    hookService
      .call('openProjectAngularBootstrap')
      .forEach((results:{ selector:string, cls:any }[]) => {
        DynamicBootstrapper.bootstrapOptionalDocument(appRef, document, results);
      });
  }
}
