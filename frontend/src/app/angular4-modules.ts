// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {PortalModule} from '@angular/cdk/portal';
import {DragDropModule} from '@angular/cdk/drag-drop';
import {APP_INITIALIZER, ApplicationRef, Injector, NgModule} from '@angular/core';
import {FormsModule} from '@angular/forms';
import {BrowserModule} from '@angular/platform-browser';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';

import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {CurrentProjectService} from 'core-components/projects/current-project.service';
import {ProjectCacheService} from 'core-components/projects/project-cache.service';
import {FirstRouteService} from 'core-components/routing/first-route-service';
import {States} from 'core-components/states.service';
import {ExpandableSearchComponent} from 'core-components/expandable-search/expandable-search.component';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {UserCacheService} from 'core-components/user/user-cache.service';
import {MainMenuResizerComponent} from 'core-components/resizer/main-menu-resizer.component';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {ExternalQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-query-configuration.service';
import {ExternalRelationQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-relation-query-configuration.service';
import {ConfirmDialogModal} from "core-components/modals/confirm-dialog/confirm-dialog.modal";
import {ConfirmDialogService} from "core-components/modals/confirm-dialog/confirm-dialog.service";
import {DynamicContentModal} from "core-components/modals/modal-wrapper/dynamic-content.modal";
import {PasswordConfirmationModal} from "core-components/modals/request-for-confirmation/password-confirmation.modal";
import {OpTitleService} from 'core-components/html/op-title.service';
import {OpenprojectFieldsModule} from "core-app/modules/fields/openproject-fields.module";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {OpenprojectAccessibilityModule} from "core-app/modules/a11y/openproject-a11y.module";
import {CommentService} from "core-components/wp-activity/comment-service";
import {OpDragScrollDirective} from "core-app/modules/common/ui/op-drag-scroll.directive";
import {UIRouterModule} from "@uirouter/angular";
import {initializeUiRouterConfiguration} from "core-components/routing/ui-router.config";
import {OpenprojectPluginsModule} from "core-app/modules/plugins/openproject-plugins.module";
import {ConfirmFormSubmitController} from "core-components/modals/confirm-form-submit/confirm-form-submit.directive";
import {ProjectMenuAutocompleteComponent} from "core-components/projects/project-menu-autocomplete/project-menu-autocomplete.component";
import {MainMenuToggleComponent} from "core-components/resizer/main-menu-toggle.component";
import {MainMenuToggleService} from "core-components/resizer/main-menu-toggle.service";
import {OpenProjectFileUploadService} from "core-components/api/op-file-upload/op-file-upload.service";
import {AttributeHelpTextModal} from "./modules/common/help-texts/attribute-help-text.modal";
import {LinkedPluginsModule} from "core-app/modules/plugins/linked-plugins.module";
import {HookService} from "core-app/modules/plugins/hook-service";
import {ModalWrapperAugmentService} from "core-app/globals/augmenting/modal-wrapper.augment.service";
import {EditorMacrosService} from "core-components/modals/editor/editor-macros.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {CurrentUserService} from 'core-components/user/current-user.service';
import {OpenprojectWorkPackagesModule} from 'core-app/modules/work_packages/openproject-work-packages.module';
import {OpenprojectAttachmentsModule} from 'core-app/modules/attachments/openproject-attachments.module';
import {OpenprojectEditorModule} from 'core-app/modules/editor/openproject-editor.module';
import {OpenprojectGridsModule} from "core-app/modules/grids/openproject-grids.module";

@NgModule({
  imports: [
    BrowserModule,
    FormsModule,
    // UI router routes configuration
    UIRouterModule.forRoot(),
    // Angular CDK
    PortalModule,
    // Commons
    OpenprojectCommonModule,
    // A11y
    OpenprojectAccessibilityModule,
    // Hal Module
    OpenprojectHalModule,

    // CKEditor
    OpenprojectEditorModule,
    // Display + Edit field functionality
    OpenprojectFieldsModule,
    OpenprojectGridsModule,
    OpenprojectAttachmentsModule,
    OpenprojectWorkPackagesModule,
    // Plugin hooks and modules
    OpenprojectPluginsModule,
    // Linked plugins dynamically generated by bundler
    LinkedPluginsModule,

  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initializeUiRouterConfiguration,
      deps: [Injector],
      multi: true
    },
    {
      provide: APP_INITIALIZER,
      useFactory: initializeServices,
      deps: [Injector],
      multi: true
    },
    OpTitleService,
    UrlParamsHelperService,
    ProjectCacheService,
    UserCacheService,
    CurrentUserService,
    {provide: States, useValue: new States()},
    PaginationService,
    OpenProjectFileUploadService,
    CurrentProjectService,
    FirstRouteService,
    // Split view
    CommentService,
    // Context menus
    OPContextMenuService,
    // OP Modals service
    OpModalService,
    ConfirmDialogService,

    // Main Menu
    MainMenuToggleService,

    // Augmenting Rails
    ModalWrapperAugmentService,
  ],
  declarations: [
    ConfirmFormSubmitController,
    OpContextMenuTrigger,
    MainMenuResizerComponent,

    // Searchbar
    ExpandableSearchComponent,

    // Modals
    ConfirmDialogModal,
    DynamicContentModal,
    PasswordConfirmationModal,

    // Main menu
    MainMenuResizerComponent,
    MainMenuToggleComponent,

    // Project autocompleter
    ProjectMenuAutocompleteComponent,

    // Form configuration
    OpDragScrollDirective,
  ],
  entryComponents: [
    // Searchbar
    ExpandableSearchComponent,

    // Project Auto completer
    ProjectMenuAutocompleteComponent,

    // Modals

    DynamicContentModal,
    ConfirmDialogModal,
    PasswordConfirmationModal,
    AttributeHelpTextModal,

    // Main menu
    MainMenuResizerComponent,
    MainMenuToggleComponent,
  ]
})
export class OpenProjectModule {
  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap(appRef:ApplicationRef) {

    // Perform global dynamic bootstrapping of our entry components
    // that are in the current DOM response.
    DynamicBootstrapper.bootstrapOptionalDocument(appRef, document);

    // Call hook service to allow modules to bootstrap additional elements.
    // We can't use ngDoBootstrap in nested modules since they are not called.
    const hookService = (appRef as any)._injector.get(HookService);
    hookService
      .call('openProjectAngularBootstrap')
      .forEach((results:{selector:string, cls:any}[]) => {
        DynamicBootstrapper.bootstrapOptionalDocument(appRef, document, results);
      });
  }
}

export function initializeServices(injector:Injector) {
  return () => {
    const ExternalQueryConfiguration = injector.get(ExternalQueryConfigurationService);
    const ExternalRelationQueryConfiguration = injector.get(ExternalRelationQueryConfigurationService);
    const ModalWrapper = injector.get(ModalWrapperAugmentService);
    const EditorMacros = injector.get(EditorMacrosService);

    // Setup modal wrapping
    ModalWrapper.setupListener();

    // Setup query configuration listener
    ExternalQueryConfiguration.setupListener();
    ExternalRelationQueryConfiguration.setupListener();
  };
}
