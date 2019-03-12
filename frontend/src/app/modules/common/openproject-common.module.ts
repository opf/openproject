// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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


import {FormsModule} from "@angular/forms";
import {APP_INITIALIZER, Injector, NgModule} from "@angular/core";

import {AuthoringComponent} from 'core-app/modules/common/authoring/authoring.component';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {OpDateTimeComponent} from 'core-app/modules/common/date/op-date-time.component';
import {WorkPackageEditActionsBarComponent} from 'core-app/modules/common/edit-actions-bar/wp-edit-actions-bar.component';
import {AttributeHelpTextComponent} from 'core-app/modules/common/help-texts/attribute-help-text.component';
import {AttributeHelpTextModal} from 'core-app/modules/common/help-texts/attribute-help-text.modal';
import {AttributeHelpTextsService} from 'core-app/modules/common/help-texts/attribute-help-text.service';
import {OpIcon} from 'core-app/modules/common/icon/op-icon';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {NotificationComponent} from 'core-app/modules/common/notifications/notification.component';
import {NotificationsContainerComponent} from 'core-app/modules/common/notifications/notifications-container.component';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {UploadProgressComponent} from 'core-app/modules/common/notifications/upload-progress.component';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {OpDatePickerComponent} from "core-app/modules/common/op-date-picker/op-date-picker.component";
import {FocusWithinDirective} from "core-app/modules/common/focus/focus-within.directive";
import {FocusHelperService} from "core-app/modules/common/focus/focus-helper";
import {OpenprojectAccessibilityModule} from "core-app/modules/a11y/openproject-a11y.module";
import {FocusDirective} from "core-app/modules/common/focus/focus.directive";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HighlightColDirective} from "core-app/modules/common/highlight-col/highlight-col.directive";
import {CopyToClipboardDirective} from "core-app/modules/common/copy-to-clipboard/copy-to-clipboard.directive";
import {highlightColBootstrap} from "./highlight-col/highlight-col.directive";
import {HookService} from "../plugins/hook-service";
import {HTMLSanitizeService} from "./html-sanitize/html-sanitize.service";
import {ColorsAutocompleter} from "core-app/modules/common/colors/colors-autocompleter.component";
import {DynamicCssService} from "./dynamic-css/dynamic-css.service";
import {MultiToggledSelectComponent} from "core-app/modules/common/multi-toggled-select/multi-toggled-select.component";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {ResizerComponent} from "core-app/modules/common/resizer/resizer.component";
import {TablePaginationComponent} from 'core-components/table-pagination/table-pagination.component';
import {SortHeaderDirective} from 'core-components/wp-table/sort-header/sort-header.directive';
import {ZenModeButtonComponent} from 'core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {OPContextMenuComponent} from 'core-components/op-context-menu/op-context-menu.component';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {UIRouterModule} from "@uirouter/angular";
import {PortalModule} from "@angular/cdk/portal";
import {CommonModule} from "@angular/common";
import {CollapsibleSectionComponent} from "core-app/modules/common/collapsible-section/collapsible-section.component";
import {NoResultsComponent} from "core-app/modules/common/no-results/no-results.component";
import {DragDropModule} from "@angular/cdk/drag-drop";
import {NgSelectModule} from "@ng-select/ng-select";
import {UserAutocompleterComponent} from "app/modules/common/autocomplete/user-autocompleter.component";
import {ScrollableTabsComponent} from "core-app/modules/common/tabs/scrollable-tabs.component";
import {BrowserDetector} from "core-app/modules/common/browser/browser-detector.service";
import {EditableToolbarTitleComponent} from "core-app/modules/common/editable-toolbar-title/editable-toolbar-title.component";
import {UserAvatarComponent} from "core-components/user/user-avatar/user-avatar.component";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {BackRoutingService} from "core-app/modules/common/back-routing/back-routing.service";

export function bootstrapModule(injector:Injector) {
  return () => {
    const hookService = injector.get(HookService);
    hookService.register('openProjectAngularBootstrap', () => {
      return [
        highlightColBootstrap
      ];
    });
  };
}

@NgModule({
  imports: [
    // UI router components (NOT routes!)
    UIRouterModule,
    // Angular browser + common module
    CommonModule,
    // Angular Forms
    FormsModule,
    // Angular CDK
    PortalModule,
    DragDropModule,
    // Our own A11y module
    OpenprojectAccessibilityModule,
    NgSelectModule,
  ],
  exports: [
    // Re-export all commonly used
    // modules to DRY
    UIRouterModule,
    CommonModule,
    FormsModule,
    PortalModule,
    DragDropModule,
    OpenprojectAccessibilityModule,

    OpDatePickerComponent,
    OpDateTimeComponent,
    OpIcon,

    AttributeHelpTextComponent,
    AttributeHelpTextModal,
    FocusWithinDirective,
    FocusDirective,
    AuthoringComponent,
    WorkPackageEditActionsBarComponent,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    // Entries for ng1 downgraded components
    AttributeHelpTextComponent,

    // Table highlight
    HighlightColDirective,

    // Multi select component
    MultiToggledSelectComponent,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    ZenModeButtonComponent,

    OPContextMenuComponent,

    NoResultsComponent,

    // Autocompleter Component
    NgSelectModule,

    UserAutocompleterComponent,

    ScrollableTabsComponent,

    EditableToolbarTitleComponent,

    // User Avatar
    UserAvatarComponent,
  ],
  declarations: [
    OpDatePickerComponent,
    OpDateTimeComponent,
    OpIcon,

    AttributeHelpTextComponent,
    AttributeHelpTextModal,
    FocusWithinDirective,
    FocusDirective,
    AuthoringComponent,
    WorkPackageEditActionsBarComponent,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    OPContextMenuComponent,
    // Entries for ng1 downgraded components
    AttributeHelpTextComponent,

    // Table highlight
    HighlightColDirective,

    // Add functionality to rails rendered templates
    CopyToClipboardDirective,
    CollapsibleSectionComponent,

    CopyToClipboardDirective,
    ColorsAutocompleter,

    MultiToggledSelectComponent,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    // Zen mode button
    ZenModeButtonComponent,

    NoResultsComponent,

    UserAutocompleterComponent,

    ScrollableTabsComponent,

    EditableToolbarTitleComponent,

    // User Avatar
    UserAvatarComponent,
  ],
  entryComponents: [
    OpDateTimeComponent,
    CopyToClipboardDirective,
    NotificationsContainerComponent,
    HighlightColDirective,
    HighlightColDirective,
    ColorsAutocompleter,

    TablePaginationComponent,

    OPContextMenuComponent,
    ZenModeButtonComponent,
    CollapsibleSectionComponent,
    UserAutocompleterComponent,
    UserAvatarComponent
  ],
  providers: [
    { provide: APP_INITIALIZER, useFactory: bootstrapModule, deps: [Injector], multi: true },
    I18nService,
    DynamicCssService,
    BannersService,
    NotificationsService,
    FocusHelperService,
    LoadingIndicatorService,
    AuthorisationService,
    AttributeHelpTextsService,
    ConfigurationService,
    PathHelperService,
    HTMLSanitizeService,
    TimezoneService,
    BrowserDetector,
    GonService,
    BackRoutingService,
  ]
})
export class OpenprojectCommonModule { }
