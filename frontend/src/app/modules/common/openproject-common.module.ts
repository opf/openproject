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

import {FormsModule} from "@angular/forms";
import {Injector, NgModule} from "@angular/core";

import {AuthoringComponent} from 'core-app/modules/common/authoring/authoring.component';
import {OpDateTimeComponent} from 'core-app/modules/common/date/op-date-time.component';
import {AttributeHelpTextComponent} from 'core-app/modules/common/help-texts/attribute-help-text.component';
import {AttributeHelpTextModal} from 'core-app/modules/common/help-texts/attribute-help-text.modal';
import {OpIcon} from 'core-app/modules/common/icon/op-icon';
import {NotificationComponent} from 'core-app/modules/common/notifications/notification.component';
import {NotificationsContainerComponent} from 'core-app/modules/common/notifications/notifications-container.component';
import {UploadProgressComponent} from 'core-app/modules/common/notifications/upload-progress.component';
import {OpDatePickerComponent} from "core-app/modules/common/op-date-picker/op-date-picker.component";
import {FocusWithinDirective} from "core-app/modules/common/focus/focus-within.directive";
import {OpenprojectAccessibilityModule} from "core-app/modules/a11y/openproject-a11y.module";
import {FocusDirective} from "core-app/modules/common/focus/focus.directive";
import {HighlightColDirective} from "core-app/modules/common/highlight-col/highlight-col.directive";
import {CopyToClipboardDirective} from "core-app/modules/common/copy-to-clipboard/copy-to-clipboard.directive";
import {highlightColBootstrap} from "./highlight-col/highlight-col.directive";
import {HookService} from "../plugins/hook-service";
import {ColorsAutocompleter} from "core-app/modules/common/colors/colors-autocompleter.component";
import {ResizerComponent} from "core-app/modules/common/resizer/resizer.component";
import {TablePaginationComponent} from 'core-components/table-pagination/table-pagination.component';
import {SortHeaderDirective} from 'core-components/wp-table/sort-header/sort-header.directive';
import {ZenModeButtonComponent} from 'core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {OPContextMenuComponent} from 'core-components/op-context-menu/op-context-menu.component';
import {StateService, UIRouterModule} from "@uirouter/angular";
import {PortalModule} from "@angular/cdk/portal";
import {CommonModule} from "@angular/common";
import {CollapsibleSectionComponent} from "core-app/modules/common/collapsible-section/collapsible-section.component";
import {NoResultsComponent} from "core-app/modules/common/no-results/no-results.component";
import {DragDropModule} from "@angular/cdk/drag-drop";
import {UserAutocompleterComponent} from "app/modules/common/autocomplete/user-autocompleter.component";
import {ScrollableTabsComponent} from "core-app/modules/common/tabs/scrollable-tabs/scrollable-tabs.component";
import {ContentTabsComponent} from "core-app/modules/common/tabs/content-tabs/content-tabs.component";
import {EditableToolbarTitleComponent} from "core-app/modules/common/editable-toolbar-title/editable-toolbar-title.component";
import {UserAvatarComponent} from "core-components/user/user-avatar/user-avatar.component";
import {EnterpriseBannerComponent} from "core-components/enterprise-banner/enterprise-banner.component";
import {EnterpriseBannerBootstrapComponent} from "core-components/enterprise-banner/enterprise-banner-bootstrap.component";
import {DynamicModule} from "ng-dynamic-component";
import {VersionAutocompleterComponent} from "core-app/modules/common/autocomplete/version-autocompleter.component";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";
import {HomescreenNewFeaturesBlockComponent} from "core-components/homescreen/blocks/new-features.component";
import {BoardVideoTeaserModalComponent} from "core-app/modules/boards/board/board-video-teaser-modal/board-video-teaser-modal.component";
import {PersistentToggleComponent} from "core-app/modules/common/persistent-toggle/persistent-toggle.component";
import {AutocompleteSelectDecorationComponent} from "core-app/modules/common/autocomplete/autocomplete-select-decoration.component";
import {AddSectionDropdownComponent} from "core-app/modules/common/hide-section/add-section-dropdown/add-section-dropdown.component";
import {HideSectionLinkComponent} from "core-app/modules/common/hide-section/hide-section-link/hide-section-link.component";
import {RemoteFieldUpdaterComponent} from 'core-app/modules/common/remote-field-updater/remote-field-updater.component';
import {AutofocusDirective} from "core-app/modules/common/autofocus/autofocus.directive";
import {ShowSectionDropdownComponent} from "core-app/modules/common/hide-section/show-section-dropdown.component";
import {IconTriggeredContextMenuComponent} from "core-components/op-context-menu/icon-triggered-context-menu/icon-triggered-context-menu.component";
import {NgSelectModule} from "@ng-select/ng-select";
import {NgOptionHighlightModule} from "@ng-select/ng-option-highlight";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {CurrentUserService} from "core-components/user/current-user.service";
import {WorkPackageAutocompleterComponent} from "core-app/modules/common/autocomplete/wp-autocompleter.component";
import {TimeEntryWorkPackageAutocompleterComponent} from "core-app/modules/common/autocomplete/te-work-package-autocompleter.component";
import {DraggableAutocompleteComponent} from "core-app/modules/common/draggable-autocomplete/draggable-autocomplete.component";
import {DragulaModule} from "ng2-dragula";

export function bootstrapModule(injector:Injector) {
  // Ensure error reporter is run
  const currentProject = injector.get(CurrentProjectService);
  const currentUser = injector.get(CurrentUserService);
  const routerState = injector.get(StateService);

  window.ErrorReporter.addContext((scope) => {
    if (currentUser.isLoggedIn) {
      scope.setUser({ name: currentUser.name, id: currentUser.userId, email: currentUser.mail });
    }

    if (currentProject.inProjectContext) {
      scope.setTag('project', currentProject.identifier!);
    }

    scope.setExtra('router state', routerState.current.name);
  });

  const hookService = injector.get(HookService);
  hookService.register('openProjectAngularBootstrap', () => {
    return [
      highlightColBootstrap
    ];
  });
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
    DragulaModule,
    // Our own A11y module
    OpenprojectAccessibilityModule,
    NgSelectModule,
    NgOptionHighlightModule,

    DynamicModule.withComponents([
      VersionAutocompleterComponent,
      WorkPackageAutocompleterComponent,
      TimeEntryWorkPackageAutocompleterComponent,
      CreateAutocompleterComponent]),
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
    NgSelectModule,
    NgOptionHighlightModule,

    OpDatePickerComponent,
    OpDateTimeComponent,
    OpIcon,
    AutofocusDirective,

    AttributeHelpTextComponent,
    AttributeHelpTextModal,
    FocusWithinDirective,
    FocusDirective,
    AuthoringComponent,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    // Entries for ng1 downgraded components
    AttributeHelpTextComponent,

    // Table highlight
    HighlightColDirective,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    ZenModeButtonComponent,

    OPContextMenuComponent,
    IconTriggeredContextMenuComponent,

    NoResultsComponent,

    UserAutocompleterComponent,

    ScrollableTabsComponent,

    EditableToolbarTitleComponent,

    // User Avatar
    UserAvatarComponent,

    // Enterprise Edition
    EnterpriseBannerComponent,

    DynamicModule,

    WorkPackageAutocompleterComponent,

    DraggableAutocompleteComponent,
  ],
  declarations: [
    OpDatePickerComponent,
    OpDateTimeComponent,
    OpIcon,
    AutofocusDirective,

    AttributeHelpTextComponent,
    AttributeHelpTextModal,
    FocusWithinDirective,
    FocusDirective,
    AuthoringComponent,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    OPContextMenuComponent,
    IconTriggeredContextMenuComponent,

    // Entries for ng1 downgraded components
    AttributeHelpTextComponent,

    // Table highlight
    HighlightColDirective,

    // Add functionality to rails rendered templates
    CopyToClipboardDirective,
    CollapsibleSectionComponent,

    CopyToClipboardDirective,
    ColorsAutocompleter,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    // Zen mode button
    ZenModeButtonComponent,

    NoResultsComponent,

    UserAutocompleterComponent,

    ScrollableTabsComponent,
    ContentTabsComponent,

    EditableToolbarTitleComponent,

    // User Avatar
    UserAvatarComponent,

    PersistentToggleComponent,
    AutocompleteSelectDecorationComponent,
    HideSectionLinkComponent,
    ShowSectionDropdownComponent,
    AddSectionDropdownComponent,
    RemoteFieldUpdaterComponent,

    // Enterprise Edition
    EnterpriseBannerComponent,
    EnterpriseBannerBootstrapComponent,

    // Autocompleter
    CreateAutocompleterComponent,
    VersionAutocompleterComponent,
    WorkPackageAutocompleterComponent,
    TimeEntryWorkPackageAutocompleterComponent,
    DraggableAutocompleteComponent,

    HomescreenNewFeaturesBlockComponent,
    BoardVideoTeaserModalComponent
  ]
})
export class OpenprojectCommonModule {
  constructor(injector:Injector) {
    bootstrapModule(injector);


  }
}
