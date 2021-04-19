//-- copyright
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {FormsModule} from '@angular/forms';
import {Injector, NgModule} from '@angular/core';
import {NgSelectModule} from '@ng-select/ng-select';
import {DragDropModule} from '@angular/cdk/drag-drop';
import {PortalModule} from '@angular/cdk/portal';
import {CommonModule} from '@angular/common';
import {NgOptionHighlightModule} from '@ng-select/ng-option-highlight';
import {DragulaModule} from 'ng2-dragula';
import {DynamicModule} from 'ng-dynamic-component';
import {StateService, UIRouterModule} from '@uirouter/angular';
import {HookService} from '../plugins/hook-service';
import {OpenprojectAccessibilityModule} from 'core-app/modules/a11y/openproject-a11y.module';
import {IconTriggeredContextMenuComponent} from 'core-components/op-context-menu/icon-triggered-context-menu/icon-triggered-context-menu.component';
import {CurrentProjectService} from 'core-components/projects/current-project.service';
import {CurrentUserService} from 'core-components/user/current-user.service';
import {TablePaginationComponent} from 'core-components/table-pagination/table-pagination.component';
import {SortHeaderDirective} from 'core-components/wp-table/sort-header/sort-header.directive';
import {ZenModeButtonComponent} from 'core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {OPContextMenuComponent} from 'core-components/op-context-menu/op-context-menu.component';
import {EnterpriseBannerComponent} from 'core-components/enterprise-banner/enterprise-banner.component';
import {EnterpriseBannerBootstrapComponent} from 'core-components/enterprise-banner/enterprise-banner-bootstrap.component';
import {HomescreenNewFeaturesBlockComponent} from 'core-components/homescreen/blocks/new-features.component';
import {BoardVideoTeaserModalComponent} from 'core-app/modules/boards/board/board-video-teaser-modal/board-video-teaser-modal.component';
import {highlightColBootstrap} from './highlight-col/highlight-col.directive';
import {HighlightColDirective} from './highlight-col/highlight-col.directive';
import {CopyToClipboardDirective} from './copy-to-clipboard/copy-to-clipboard.directive';
import {AuthoringComponent} from './authoring/authoring.component';
import {OpDateTimeComponent} from './date/op-date-time.component';
import {NotificationComponent} from './notifications/notification.component';
import {NotificationsContainerComponent} from './notifications/notifications-container.component';
import {UploadProgressComponent} from './notifications/upload-progress.component';
import {ResizerComponent} from './resizer/resizer.component';
import {CollapsibleSectionComponent} from './collapsible-section/collapsible-section.component';
import {NoResultsComponent} from './no-results/no-results.component';
import {ScrollableTabsComponent} from './tabs/scrollable-tabs/scrollable-tabs.component';
import {ContentTabsComponent} from './tabs/content-tabs/content-tabs.component';
import {EditableToolbarTitleComponent} from './editable-toolbar-title/editable-toolbar-title.component';
import {PersistentToggleComponent} from './persistent-toggle/persistent-toggle.component';
import {AddSectionDropdownComponent} from './hide-section/add-section-dropdown/add-section-dropdown.component';
import {HideSectionLinkComponent} from './hide-section/hide-section-link/hide-section-link.component';
import {RemoteFieldUpdaterComponent} from './remote-field-updater/remote-field-updater.component';
import {AutofocusDirective} from './autofocus/autofocus.directive';
import {ShowSectionDropdownComponent} from './hide-section/show-section-dropdown.component';
import {SlideToggleComponent} from './slide-toggle/slide-toggle.component';
import {DynamicBootstrapModule} from './dynamic-bootstrap/dynamic-bootstrap.module';
import {OpFormFieldComponent} from './form-field/form-field.component';
import {OpFormBindingDirective} from './form-field/form-binding.directive';
import {OpOptionListComponent} from './option-list/option-list.component';
import {OpIconComponent} from './icon/icon.component';
import {OpenprojectPrincipalRenderingModule} from "core-app/modules/principal/principal-rendering.module";
import { DatePickerModule } from "core-app/modules/common/op-date-picker/date-picker.module";
import { FocusModule } from "core-app/modules/common/focus/focus.module";

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

    DynamicBootstrapModule,
    OpenprojectPrincipalRenderingModule,

    DatePickerModule,
    FocusModule,
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
    DynamicBootstrapModule,
    OpenprojectPrincipalRenderingModule,

    DatePickerModule,
    FocusModule,
    OpDateTimeComponent,
    AutofocusDirective,

    AuthoringComponent,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    // Table highlight
    HighlightColDirective,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    ZenModeButtonComponent,

    OPContextMenuComponent,
    IconTriggeredContextMenuComponent,

    NoResultsComponent,

    ScrollableTabsComponent,

    EditableToolbarTitleComponent,

    // Enterprise Edition
    EnterpriseBannerComponent,

    DynamicModule,

    // filter

    SlideToggleComponent,

    OpFormFieldComponent,
    OpFormBindingDirective,
    OpOptionListComponent,
    OpIconComponent,
  ],
  declarations: [
    OpDateTimeComponent,
    AutofocusDirective,

    AuthoringComponent,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    OPContextMenuComponent,
    IconTriggeredContextMenuComponent,

    // Table highlight
    HighlightColDirective,

    // Add functionality to rails rendered templates
    CopyToClipboardDirective,
    CollapsibleSectionComponent,

    CopyToClipboardDirective,
    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    // Zen mode button
    ZenModeButtonComponent,

    NoResultsComponent,

    ScrollableTabsComponent,
    ContentTabsComponent,

    EditableToolbarTitleComponent,

    PersistentToggleComponent,
    HideSectionLinkComponent,
    ShowSectionDropdownComponent,
    AddSectionDropdownComponent,
    RemoteFieldUpdaterComponent,

    // Enterprise Edition
    EnterpriseBannerComponent,
    EnterpriseBannerBootstrapComponent,



    HomescreenNewFeaturesBlockComponent,
    BoardVideoTeaserModalComponent,

    //filter
    SlideToggleComponent,

    OpFormFieldComponent,
    OpFormBindingDirective,
    OpOptionListComponent,
    OpIconComponent,
  ]
})
export class OpenprojectCommonModule {
  constructor(injector:Injector) {
    bootstrapModule(injector);


  }
}
