// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {APP_INITIALIZER, ApplicationRef, Injector, NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';

import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {States} from 'core-components/states.service';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {MainMenuResizerComponent} from 'core-components/resizer/main-menu-resizer.component';
import {ExternalQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-query-configuration.service';
import {ExternalRelationQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-relation-query-configuration.service';
import {ConfirmDialogModal} from "core-components/modals/confirm-dialog/confirm-dialog.modal";
import {ConfirmDialogService} from "core-components/modals/confirm-dialog/confirm-dialog.service";
import {DynamicContentModal} from "core-components/modals/modal-wrapper/dynamic-content.modal";
import {PasswordConfirmationModal} from "core-components/modals/request-for-confirmation/password-confirmation.modal";
import {OpenprojectFieldsModule} from "core-app/modules/fields/openproject-fields.module";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {CommentService} from "core-components/wp-activity/comment-service";
import {OpDragScrollDirective} from "core-app/modules/common/ui/op-drag-scroll.directive";
import {OpenprojectPluginsModule} from "core-app/modules/plugins/openproject-plugins.module";
import {ConfirmFormSubmitController} from "core-components/modals/confirm-form-submit/confirm-form-submit.directive";
import {ProjectMenuAutocompleteComponent} from "core-components/projects/project-menu-autocomplete/project-menu-autocomplete.component";
import {OpenProjectFileUploadService} from "core-components/api/op-file-upload/op-file-upload.service";
import {LinkedPluginsModule} from "core-app/modules/plugins/linked-plugins.module";
import {HookService} from "core-app/modules/plugins/hook-service";
import {ModalWrapperAugmentService} from "core-app/globals/augmenting/modal-wrapper.augment.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {OpenprojectWorkPackagesModule} from 'core-app/modules/work_packages/openproject-work-packages.module';
import {OpenprojectAttachmentsModule} from 'core-app/modules/attachments/openproject-attachments.module';
import {OpenprojectEditorModule} from 'core-app/modules/editor/openproject-editor.module';
import {OpenprojectGridsModule} from "core-app/modules/grids/openproject-grids.module";
import {OpenprojectRouterModule} from "core-app/modules/router/openproject-router.module";
import {OpenprojectWorkPackageRoutesModule} from "core-app/modules/work_packages/openproject-work-package-routes.module";
import {BrowserModule} from "@angular/platform-browser";
import {OpenprojectCalendarModule} from "core-app/modules/calendar/openproject-calendar.module";
import {OpenprojectGlobalSearchModule} from "core-app/modules/global_search/openproject-global-search.module";
import {MainMenuToggleComponent} from "core-components/main-menu/main-menu-toggle.component";
import {MainMenuNavigationService} from "core-components/main-menu/main-menu-navigation.service";
import {OpenprojectAdminModule} from "core-app/modules/admin/openproject-admin.module";
import {OpenprojectDashboardsModule} from "core-app/modules/dashboards/openproject-dashboards.module";
import {OpenprojectWorkPackageGraphsModule} from "core-app/modules/work-package-graphs/openproject-work-package-graphs.module";
import {WpPreviewModal} from "core-components/modals/preview-modal/wp-preview-modal/wp-preview.modal";
import {PreviewTriggerService} from "core-app/globals/global-listeners/preview-trigger.service";
import {OpenprojectOverviewModule} from "core-app/modules/overview/openproject-overview.module";
import {OpenprojectMyPageModule} from "core-app/modules/my-page/openproject-my-page.module";
import {OpenprojectProjectsModule} from "core-app/modules/projects/openproject-projects.module";
import {KeyboardShortcutService} from "core-app/modules/a11y/keyboard-shortcut-service";
import {globalDynamicComponents} from "core-app/global-dynamic-components.const";
import {OpenprojectMembersModule} from "core-app/modules/members/members.module";
import {OpenprojectEnterpriseModule} from "core-components/enterprise/openproject-enterprise.module";

@NgModule({
  imports: [
    // The BrowserModule must only be loaded here!
    BrowserModule,
    // Commons
    OpenprojectCommonModule,
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
    ReactiveFormsModule
  ],
  providers: [
    { provide: States, useValue: new States() },
    { provide: APP_INITIALIZER, useFactory: initializeServices, deps: [Injector], multi: true },
    PaginationService,
    OpenProjectFileUploadService,
    // Split view
    CommentService,
    ConfirmDialogService,
  ],
  declarations: [
    OpContextMenuTrigger,

    // Modals
    ConfirmDialogModal,
    DynamicContentModal,
    PasswordConfirmationModal,
    WpPreviewModal,

    // Main menu
    MainMenuResizerComponent,
    MainMenuToggleComponent,

    // Project autocompleter
    ProjectMenuAutocompleteComponent,

    // Form configuration
    OpDragScrollDirective,
    ConfirmFormSubmitController,
  ]
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

export function initializeServices(injector:Injector) {
  return () => {
    const ExternalQueryConfiguration = injector.get(ExternalQueryConfigurationService);
    const ExternalRelationQueryConfiguration = injector.get(ExternalRelationQueryConfigurationService);
    const ModalWrapper = injector.get(ModalWrapperAugmentService);
    const PreviewTrigger = injector.get(PreviewTriggerService);
    const mainMenuNavigationService = injector.get(MainMenuNavigationService);
    const keyboardShortcuts = injector.get(KeyboardShortcutService);

    mainMenuNavigationService.register();

    // Setup modal wrapping
    ModalWrapper.setupListener();

    PreviewTrigger.setupListener();

    keyboardShortcuts.register();

    // Setup query configuration listener
    ExternalQueryConfiguration.setupListener();
    ExternalRelationQueryConfiguration.setupListener();
  };
}
