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
import { FormsModule } from '@angular/forms';
import { Injector, NgModule } from '@angular/core';
import { A11yModule } from '@angular/cdk/a11y';
import { UIRouterGlobals } from '@uirouter/core';
import { NgSelectModule } from '@ng-select/ng-select';
import { DragDropModule } from '@angular/cdk/drag-drop';
import { PortalModule } from '@angular/cdk/portal';
import { CommonModule } from '@angular/common';
import { NgOptionHighlightModule } from '@ng-select/ng-option-highlight';
import { DragulaModule } from 'ng2-dragula';
import { DynamicModule } from 'ng-dynamic-component';
import { UIRouterModule } from '@uirouter/angular';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { CurrentUserModule } from 'core-app/core/current-user/current-user.module';
import {
  OpenprojectAutocompleterModule,
} from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { AttributeHelpTextModule } from 'core-app/shared/components/attribute-help-texts/attribute-help-text.module';
import {
  IconTriggeredContextMenuComponent,
} from 'core-app/shared/components/op-context-menu/icon-triggered-context-menu/icon-triggered-context-menu.component';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import {
  SortHeaderDirective,
} from 'core-app/features/work-packages/components/wp-table/sort-header/sort-header.directive';
import {
  ZenModeButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { OPContextMenuComponent } from 'core-app/shared/components/op-context-menu/op-context-menu.component';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { FocusModule } from 'core-app/shared/directives/focus/focus.module';
import { EnterpriseBannerComponent } from 'core-app/shared/components/enterprise-banner/enterprise-banner.component';
import { EnterprisePageComponent } from 'core-app/shared/components/enterprise-page/enterprise-page.component';
import { FreeTrialButtonComponent } from 'core-app/features/enterprise/free-trial-button/free-trial-button.component';
import { HomescreenNewFeaturesBlockComponent } from 'core-app/features/homescreen/blocks/new-features.component';
import { TablePaginationComponent } from 'core-app/shared/components/table-pagination/table-pagination.component';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import { CopyToClipboardService } from './components/copy-to-clipboard/copy-to-clipboard.service';
import { CopyToClipboardComponent } from './components/copy-to-clipboard/copy-to-clipboard.component';
import { OpDateTimeComponent } from './components/date/op-date-time.component';
import { ToastComponent } from './components/toaster/toast.component';

// Old datepickers
import {
  OpMultiDatePickerComponent,
} from 'core-app/shared/components/datepicker/multi-date-picker/multi-date-picker.component';

import { ToastsContainerComponent } from './components/toaster/toasts-container.component';
import { UploadProgressComponent } from './components/toaster/upload-progress.component';
import { ResizerComponent } from './components/resizer/resizer.component';
import { CollapsibleSectionComponent } from './components/collapsible-section/collapsible-section.component';
import { NoResultsComponent } from './components/no-results/no-results.component';
import { EditableToolbarTitleComponent } from './components/editable-toolbar-title/editable-toolbar-title.component';
import { PersistentToggleComponent } from './components/persistent-toggle/persistent-toggle.component';
import {
  AddSectionDropdownComponent,
} from './components/hide-section/add-section-dropdown/add-section-dropdown.component';
import { HideSectionLinkComponent } from './components/hide-section/hide-section-link/hide-section-link.component';
import { RemoteFieldUpdaterComponent } from './components/remote-field-updater/remote-field-updater.component';
import { OpOptionListComponent } from './components/option-list/option-list.component';
import { OpProjectIncludeComponent } from './components/project-include/project-include.component';
import { OpProjectIncludeListComponent } from './components/project-include/list/project-include-list.component';
import { OpLoadingProjectListComponent } from './components/searchable-project-list/loading-project-list.component';
import {
  OpNonWorkingDaysListComponent,
} from './components/op-non-working-days-list/op-non-working-days-list.component';
import { ViewsResourceService } from 'core-app/core/state/views/views.service';
import {
  OpenprojectContentLoaderModule,
} from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { FullCalendarModule } from '@fullcalendar/angular';
import { OpDatePickerModule } from 'core-app/shared/components/datepicker/datepicker.module';
import { ShareUpsaleComponent } from 'core-app/features/enterprise/share-upsale/share-upsale.component';

export function bootstrapModule(injector:Injector):void {
  // Ensure error reporter is run
  const currentProject = injector.get(CurrentProjectService);
  const uiRouterGlobals = injector.get(UIRouterGlobals);

  (window.ErrorReporter).addHook(() => ({
    project: currentProject.identifier || 'global',
    'router state': uiRouterGlobals.current.name || 'unknown',
  }));
}

@NgModule({
  imports: [
    // UI router components (NOT routes!)
    UIRouterModule,
    // Angular browser + common module
    CommonModule,
    // Angular Forms
    FormsModule,
    OpSpotModule,
    // Angular CDK
    A11yModule,
    PortalModule,
    DragDropModule,
    DragulaModule,
    CurrentUserModule,
    FormsModule,
    NgSelectModule,
    NgOptionHighlightModule,

    OpenprojectPrincipalRenderingModule,
    OpenprojectContentLoaderModule,
    OpenprojectAutocompleterModule,
    OpenprojectModalModule,

    FocusModule,
    IconModule,
    AttributeHelpTextModule,
    FullCalendarModule,
    OpDatePickerModule,
  ],
  exports: [
    // Re-export all commonly used
    // modules to DRY
    UIRouterModule,
    CommonModule,
    FormsModule,
    PortalModule,
    DragDropModule,
    A11yModule,
    IconModule,
    AttributeHelpTextModule,
    FormsModule,
    NgOptionHighlightModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectAutocompleterModule,
    OpenprojectContentLoaderModule,

    OpSpotModule,

    OpDatePickerModule,

    FocusModule,
    OpDateTimeComponent,

    ToastsContainerComponent,
    ToastComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    ZenModeButtonComponent,

    OPContextMenuComponent,
    IconTriggeredContextMenuComponent,

    NoResultsComponent,

    EditableToolbarTitleComponent,

    // Enterprise Edition
    EnterpriseBannerComponent,
    EnterprisePageComponent,
    FreeTrialButtonComponent,

    DynamicModule,

    OpOptionListComponent,
    OpProjectIncludeComponent,
    OpProjectIncludeListComponent,
    OpLoadingProjectListComponent,

    // Old datepickers
    OpMultiDatePickerComponent,

    OpNonWorkingDaysListComponent,
  ],
  providers: [
    CopyToClipboardService,
    StaticQueriesService,
    ViewsResourceService,
  ],
  declarations: [
    ToastsContainerComponent,
    ToastComponent,
    UploadProgressComponent,
    OpDateTimeComponent,

    OPContextMenuComponent,
    IconTriggeredContextMenuComponent,

    // Add functionality to rails rendered templates
    CopyToClipboardComponent,
    CollapsibleSectionComponent,

    ResizerComponent,

    TablePaginationComponent,
    SortHeaderDirective,

    // Zen mode button
    ZenModeButtonComponent,

    NoResultsComponent,

    EditableToolbarTitleComponent,

    PersistentToggleComponent,
    HideSectionLinkComponent,
    AddSectionDropdownComponent,
    RemoteFieldUpdaterComponent,

    // Enterprise Edition
    EnterpriseBannerComponent,
    EnterprisePageComponent,
    FreeTrialButtonComponent,

    HomescreenNewFeaturesBlockComponent,

    OpOptionListComponent,
    OpProjectIncludeComponent,
    OpProjectIncludeListComponent,
    OpLoadingProjectListComponent,

    OpNonWorkingDaysListComponent,

    // Old datepickers
    OpMultiDatePickerComponent,

    ShareUpsaleComponent,
  ],
})
export class OpSharedModule {
  constructor(injector:Injector) {
    bootstrapModule(injector);
  }
}
