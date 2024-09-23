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

import { CUSTOM_ELEMENTS_SCHEMA, Injector, NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { HookService } from 'core-app/features/plugins/hook-service';
import {
  WorkPackageEmbeddedTableComponent,
} from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-table.component';
import {
  WorkPackageEmbeddedTableEntryComponent,
} from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-table-entry.component';
import {
  WorkPackageTablePaginationComponent,
} from 'core-app/features/work-packages/components/wp-table/table-pagination/wp-table-pagination.component';
import {
  WorkPackageTimelineTableController,
} from 'core-app/features/work-packages/components/wp-table/timeline/container/wp-timeline-container.directive';
import {
  WorkPackageInlineCreateComponent,
} from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.component';
import {
  OpTypesContextMenuDirective,
} from 'core-app/shared/components/op-context-menu/handlers/op-types-context-menu.directive';
import {
  OpColumnsContextMenu,
} from 'core-app/shared/components/op-context-menu/handlers/op-columns-context-menu.directive';
import {
  OpSettingsMenuDirective,
} from 'core-app/shared/components/op-context-menu/handlers/op-settings-dropdown-menu.directive';
import {
  WorkPackageStatusDropdownDirective,
} from 'core-app/shared/components/op-context-menu/handlers/wp-status-dropdown-menu.directive';
import {
  WorkPackageCreateSettingsMenuDirective,
} from 'core-app/shared/components/op-context-menu/handlers/wp-create-settings-menu.directive';
import {
  WorkPackageSingleContextMenuDirective,
} from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-single-context-menu';
import {
  WorkPackageTimelineHeaderController,
} from 'core-app/features/work-packages/components/wp-table/timeline/header/wp-timeline-header.directive';
import {
  WorkPackageTableTimelineRelations,
} from 'core-app/features/work-packages/components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {
  WorkPackageTableTimelineStaticElements,
} from 'core-app/features/work-packages/components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import {
  WorkPackageTableTimelineGrid,
} from 'core-app/features/work-packages/components/wp-table/timeline/grid/wp-timeline-grid.directive';
import {
  WorkPackageTimelineButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component';
import {
  WorkPackageOverviewTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {
  WorkPackageStatusButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-status-button/wp-status-button.component';
import {
  WorkPackageReplacementLabelComponent,
} from 'core-app/features/work-packages/components/wp-edit/wp-edit-field/wp-replacement-label.component';
import {
  NewestActivityOnOverviewComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-on-overview.component';
import {
  WorkPackageActivityTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-tab.component';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import {
  WpCustomActionComponent,
} from 'core-app/features/work-packages/components/wp-custom-actions/wp-custom-actions/wp-custom-action.component';
import {
  WpCustomActionsComponent,
} from 'core-app/features/work-packages/components/wp-custom-actions/wp-custom-actions.component';
import {
  WorkPackageRelationsTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {
  WorkPackageRelationsComponent,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations.component';
import {
  WorkPackageRelationsGroupComponent,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations-group/wp-relations-group.component';
import {
  WorkPackageRelationRowComponent,
} from 'core-app/features/work-packages/components/wp-relations/wp-relation-row/wp-relation-row.component';
import {
  WorkPackageRelationsCreateComponent,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations-create/wp-relations-create.component';
import {
  WorkPackageRelationsHierarchyComponent,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.directive';
import {
  WorkPackageCreateButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-create-button/wp-create-button.component';
import {
  WorkPackageFilterButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import {
  WorkPackageDetailsViewButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-details-view-button/wp-details-view-button.component';
import {
  WorkPackageFoldToggleButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-fold-toggle-button/wp-fold-toggle-button.component';
import {
  WpTableConfigurationModalComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import {
  WpTableConfigurationColumnsTabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/columns-tab.component';
import {
  WpTableConfigurationDisplaySettingsTabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {
  WpTableConfigurationFiltersTab,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/filters-tab.component';
import {
  WpTableConfigurationSortByTabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {
  WpTableConfigurationTimelinesTabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {
  WpTableConfigurationHighlightingTabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/highlighting-tab.component';
import {
  WpTableConfigurationRelationSelectorComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration-relation-selector';
import {
  WorkPackageWatchersTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {
  WorkPackageWatcherEntryComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/wp-watcher-entry.component';
import {
  WorkPackageNewSplitViewComponent,
} from 'core-app/features/work-packages/components/wp-new/wp-new-split-view.component';
import {
  WorkPackageNewFullViewComponent,
} from 'core-app/features/work-packages/components/wp-new/wp-new-full-view.component';
import {
  EmbeddedTablesMacroComponent,
} from 'core-app/features/work-packages/components/wp-table/embedded/embedded-tables-macro.component';
import { OpenprojectEditorModule } from 'core-app/shared/components/editor/openproject-editor.module';
import {
  WorkPackageTableSumsRowController,
} from 'core-app/features/work-packages/components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import {
  ExternalQueryConfigurationComponent,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.component';
import {
  ExternalQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.service';
import {
  ExternalRelationQueryConfigurationComponent,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-relation-query-configuration.component';
import {
  ExternalRelationQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-relation-query-configuration.service';
import {
  WorkPackagesListInvalidQueryService,
} from 'core-app/features/work-packages/components/wp-list/wp-list-invalid-query.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import {
  WorkPackageWatchersService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import {
  WorkPackagesActivityService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  WorkPackageChildrenQueryComponent,
} from 'core-app/features/work-packages/components/wp-relations/embedded/children/wp-children-query.component';
import {
  WpRelationInlineAddExistingComponent,
} from 'core-app/features/work-packages/components/wp-relations/embedded/inline/add-existing/wp-relation-inline-add-existing.component';
import {
  WorkPackageRelationQueryComponent,
} from 'core-app/features/work-packages/components/wp-relations/embedded/relations/wp-relation-query.component';
import { WorkPackagesBaseComponent } from 'core-app/features/work-packages/routing/wp-base/wp--base.component';
import {
  WorkPackageSplitViewComponent,
} from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view.component';
import {
  WorkPackagesFullViewComponent,
} from 'core-app/features/work-packages/routing/wp-full-view/wp-full-view.component';
import { QueryFiltersService } from 'core-app/features/work-packages/components/wp-query/query-filters.service';
import {
  WorkPackageCardViewComponent,
} from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import {
  WorkPackageRelationsService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { OpenprojectBcfModule } from 'core-app/features/bim/bcf/openproject-bcf.module';
import {
  WorkPackageRelationsAutocompleteComponent,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations-create/wp-relations-autocomplete/wp-relations-autocomplete.component';
import {
  CustomDateActionAdminComponent,
} from 'core-app/features/work-packages/components/wp-custom-actions/date-action/custom-date-action-admin.component';
import {
  WorkPackagesTableConfigMenuComponent,
} from 'core-app/features/work-packages/components/wp-table/config-menu/config-menu.component';
import {
  WorkPackageViewDropdownMenuDirective,
} from 'core-app/shared/components/op-context-menu/handlers/wp-view-dropdown-menu.directive';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { OpenprojectProjectsModule } from 'core-app/features/projects/openproject-projects.module';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import {
  WorkPackageEditActionsBarComponent,
} from 'core-app/features/work-packages/components/edit-actions-bar/wp-edit-actions-bar.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import {
  WorkPackageSingleCardComponent,
} from 'core-app/features/work-packages/components/wp-card-view/wp-single-card/wp-single-card.component';
import {
  WorkPackageListViewComponent,
} from 'core-app/features/work-packages/routing/wp-list-view/wp-list-view.component';
import {
  PartitionedQuerySpacePageComponent,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import {
  WorkPackageViewPageComponent,
} from 'core-app/features/work-packages/routing/wp-view-page/wp-view-page.component';
import {
  WorkPackageSettingsButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-settings-button/wp-settings-button.component';
import { BackButtonComponent } from 'core-app/features/work-packages/components/back-routing/back-button.component';
import { WorkPackagesTableComponent } from 'core-app/features/work-packages/components/wp-table/wp-table.component';
import {
  WorkPackageGroupToggleDropdownMenuDirective,
} from 'core-app/shared/components/op-context-menu/handlers/wp-group-toggle-dropdown-menu.directive';
import {
  OpenprojectAutocompleterModule,
} from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { OpWpTabsModule } from 'core-app/features/work-packages/components/wp-tabs/wp-tabs.module';
import {
  EditFieldControlsModule,
} from 'core-app/shared/components/fields/edit/field-controls/edit-field-controls.module';
import {
  WpButtonMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-wp-button-modal/wp-button-macro.modal';
import { QuerySharingModalComponent } from 'core-app/shared/components/modals/share-modal/query-sharing.modal';
import { SaveQueryModalComponent } from 'core-app/shared/components/modals/save-modal/save-query.modal';
import { QuerySharingFormComponent } from 'core-app/shared/components/modals/share-modal/query-sharing-form.component';
import { WpDestroyModalComponent } from 'core-app/shared/components/modals/wp-destroy-modal/wp-destroy.modal';
import {
  WorkPackageTypeStatusComponent,
} from 'core-app/features/work-packages/components/wp-type-status/wp-type-status.component';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import {
  WorkPackageBreadcrumbParentComponent,
} from 'core-app/features/work-packages/components/wp-breadcrumb/wp-breadcrumb-parent.component';
import {
  WorkPackageSubjectComponent,
} from 'core-app/features/work-packages/components/wp-subject/wp-subject.component';
import {
  WorkPackageBreadcrumbComponent,
} from 'core-app/features/work-packages/components/wp-breadcrumb/wp-breadcrumb.component';
import { UserLinkComponent } from 'core-app/shared/components/user-link/user-link.component';
import {
  WorkPackageCommentComponent,
} from 'core-app/features/work-packages/components/work-package-comment/work-package-comment.component';
import {
  WorkPackageWatcherButtonComponent,
} from 'core-app/features/work-packages/components/wp-watcher-button/wp-watcher-button.component';
import {
  WorkPackageCommentFieldComponent,
} from 'core-app/features/work-packages/components/work-package-comment/wp-comment-field.component';
import { WpResizerDirective } from 'core-app/shared/components/resizer/resizer/wp-resizer.component';
import {
  GroupDescriptor,
  WorkPackageSingleViewComponent,
} from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';
import {
  RevisionActivityComponent,
} from 'core-app/features/work-packages/components/wp-activity/revision/revision-activity.component';
import {
  WorkPackageCopySplitViewComponent,
} from 'core-app/features/work-packages/components/wp-copy/wp-copy-split-view.component';
import {
  WorkPackageFormAttributeGroupComponent,
} from 'core-app/features/work-packages/components/wp-form-group/wp-attribute-group.component';
import { WorkPackagesGridComponent } from 'core-app/features/work-packages/components/wp-grid/wp-grid.component';
import {
  ActivityEntryComponent,
} from 'core-app/features/work-packages/components/wp-activity/activity-entry.component';
import { ActivityLinkComponent } from 'core-app/features/work-packages/components/wp-activity/activity-link.component';
import {
  UserActivityComponent,
} from 'core-app/features/work-packages/components/wp-activity/user/user-activity.component';
import {
  WorkPackageSplitViewToolbarComponent,
} from 'core-app/features/work-packages/components/wp-details/wp-details-toolbar.component';
import {
  WorkPackageCopyFullViewComponent,
} from 'core-app/features/work-packages/components/wp-copy/wp-copy-full-view.component';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { TimeEntryChangeset } from 'core-app/features/work-packages/helpers/time-entries/time-entry-changeset';

import { OpAttachmentsComponent } from 'core-app/shared/components/attachments/attachments.component';
import {
  QueryFiltersComponent,
} from 'core-app/features/work-packages/components/filters/query-filters/query-filters.component';
import {
  FilterDateTimesValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-date-times-value/filter-date-times-value.component';
import {
  FilterSearchableMultiselectValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-searchable-multiselect-value/filter-searchable-multiselect-value.component';
import {
  QueryFilterComponent,
} from 'core-app/features/work-packages/components/filters/query-filter/query-filter.component';
import {
  FilterDatesValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-dates-value/filter-dates-value.component';
import {
  FilterStringValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-string-value/filter-string-value.component';
import {
  FilterProjectComponent,
} from 'core-app/features/work-packages/components/filters/filter-project/filter-project.component';
import {
  FilterDateValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-date-value/filter-date-value.component';
import {
  FilterDateTimeValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-date-time-value/filter-date-time-value.component';
import {
  FilterToggledMultiselectValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import {
  WorkPackageFilterByTextInputComponent,
} from 'core-app/features/work-packages/components/filters/quick-filter-by-text-input/quick-filter-by-text-input.component';
import {
  FilterIntegerValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-integer-value/filter-integer-value.component';
import {
  WorkPackageFilterContainerComponent,
} from 'core-app/features/work-packages/components/filters/filter-container/filter-container.directive';
import {
  FilterBooleanValueComponent,
} from 'core-app/features/work-packages/components/filters/filter-boolean-value/filter-boolean-value.component';
import {
  WorkPackageMarkNotificationButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-mark-notification-button/work-package-mark-notification-button.component';
import {
  WorkPackageFilesTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/files-tab/op-files-tab.component';
import { WorkPackagesQueryViewService } from 'core-app/features/work-packages/components/wp-list/wp-query-view.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { OpenprojectStoragesModule } from 'core-app/shared/components/storages/openproject-storages.module';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import { ProjectStoragesResourceService } from 'core-app/core/state/project-storages/project-storages.service';
import {
  OpBaselineModalComponent,
} from 'core-app/features/work-packages/components/wp-baseline/baseline-modal/baseline-modal.component';
import {
  OpBaselineComponent,
} from 'core-app/features/work-packages/components/wp-baseline/baseline/baseline.component';
import {
  OpBaselineLoadingComponent,
} from 'core-app/features/work-packages/components/wp-baseline/baseline-loading/baseline-loading.component';
import {
  OpBaselineLegendsComponent,
} from 'core-app/features/work-packages/components/wp-baseline/baseline-legends/baseline-legends.component';
import { NgSelectModule } from '@ng-select/ng-select';
import {
  WorkPackageTimerButtonComponent,
} from 'core-app/features/work-packages/components/wp-timer-button/wp-timer-button.component';
import { OpenprojectTimeEntriesModule } from 'core-app/shared/components/time_entries/openproject-time-entries.module';
import { RecentItemsService } from 'core-app/core/recent-items.service';
import {
  WorkPackageShareButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-share-button/wp-share-button.component';
import {
  WorkPackageShareModalComponent,
} from 'core-app/features/work-packages/components/wp-share-modal/wp-share.modal';
import {
  WorkPackageSplitViewEntryComponent,
} from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view-entry.component';

@NgModule({
  imports: [
    // Commons
    OpSharedModule,
    NgSelectModule,
    // Display + Edit field functionality
    OpenprojectFieldsModule,
    // CKEditor
    OpenprojectEditorModule,

    OpenprojectAttachmentsModule,

    OpenprojectBcfModule,

    OpenprojectProjectsModule,

    OpenprojectModalModule,

    OpenprojectAutocompleterModule,

    OpenprojectTimeEntriesModule,

    OpWpTabsModule,

    EditFieldControlsModule,
    OpenprojectTabsModule,
    OpenprojectStoragesModule,

    WorkPackageIsolatedQuerySpaceDirective,
  ],
  providers: [
    // Notification service
    WorkPackageNotificationService,

    // External query configuration
    ExternalQueryConfigurationService,
    ExternalRelationQueryConfigurationService,

    // Global work package states / services
    SchemaCacheService,

    // Global query/table state services
    // For any service that depends on the isolated query space,
    // they should be provided in wp-isolated-query-space.directive instead
    QueryFiltersService,
    WorkPackagesListInvalidQueryService,

    // Provide a separate service for creation events of WP Inline create
    // This can be hierarchically injected to provide isolated events on an embedded table
    WorkPackageRelationsService,

    WorkPackagesActivityService,
    WorkPackageRelationsService,
    WorkPackageWatchersService,

    WorkPackagesQueryViewService,

    HalEventsService,
    FileLinksResourceService,
    StorageFilesResourceService,

    StoragesResourceService,
    ProjectStoragesResourceService,

    RecentItemsService,
  ],
  declarations: [
    // Routing
    WorkPackagesBaseComponent,
    PartitionedQuerySpacePageComponent,
    WorkPackageViewPageComponent,

    // WP list side
    WorkPackageListViewComponent,
    WorkPackageSettingsButtonComponent,

    // WP New
    WorkPackageNewFullViewComponent,
    WorkPackageNewSplitViewComponent,
    WorkPackageTypeStatusComponent,
    WorkPackageEditActionsBarComponent,

    // WP Copy
    WorkPackageCopyFullViewComponent,
    WorkPackageCopySplitViewComponent,

    // Embedded table
    WorkPackageEmbeddedTableComponent,
    WorkPackageEmbeddedTableEntryComponent,

    // External query configuration
    ExternalQueryConfigurationComponent,
    ExternalRelationQueryConfigurationComponent,

    // Inline create
    WorkPackageInlineCreateComponent,
    WpRelationInlineAddExistingComponent,

    WorkPackagesGridComponent,

    WorkPackagesTableComponent,
    WorkPackagesTableConfigMenuComponent,
    WorkPackageTablePaginationComponent,

    WpResizerDirective,

    WorkPackageTableSumsRowController,

    // Fold/Unfold button on wp list
    WorkPackageFoldToggleButtonComponent,

    // Filters
    QueryFiltersComponent,
    QueryFilterComponent,
    FilterBooleanValueComponent,
    FilterDateValueComponent,
    FilterDatesValueComponent,
    FilterDateTimeValueComponent,
    FilterDateTimesValueComponent,
    FilterIntegerValueComponent,
    FilterStringValueComponent,
    FilterProjectComponent,
    FilterToggledMultiselectValueComponent,
    FilterSearchableMultiselectValueComponent,

    WorkPackageFilterContainerComponent,
    WorkPackageFilterButtonComponent,

    // Context menus
    OpTypesContextMenuDirective,
    OpColumnsContextMenu,
    OpSettingsMenuDirective,
    WorkPackageStatusDropdownDirective,
    WorkPackageCreateSettingsMenuDirective,
    WorkPackageSingleContextMenuDirective,
    WorkPackageViewDropdownMenuDirective,
    WorkPackageGroupToggleDropdownMenuDirective,

    // Timeline
    WorkPackageTimelineButtonComponent,
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements,
    WorkPackageTableTimelineGrid,
    WorkPackageTimelineTableController,

    WorkPackageCreateButtonComponent,
    WorkPackageFilterByTextInputComponent,

    // Single view
    WorkPackageOverviewTabComponent,
    WorkPackageSingleViewComponent,
    WorkPackageStatusButtonComponent,
    WorkPackageReplacementLabelComponent,
    UserLinkComponent,
    WorkPackageChildrenQueryComponent,
    WorkPackageRelationQueryComponent,
    WorkPackageFormAttributeGroupComponent,
    BackButtonComponent,
    WorkPackageTimerButtonComponent,

    // Activity Tab
    NewestActivityOnOverviewComponent,
    WorkPackageCommentComponent,
    WorkPackageCommentFieldComponent,
    ActivityEntryComponent,
    UserActivityComponent,
    RevisionActivityComponent,
    ActivityLinkComponent,
    WorkPackageActivityTabComponent,

    // Watchers wp-tab-wrapper
    WorkPackageWatchersTabComponent,
    WorkPackageWatcherEntryComponent,

    // Relations
    WorkPackageRelationsTabComponent,
    WorkPackageRelationsComponent,
    WorkPackageRelationsGroupComponent,
    WorkPackageRelationRowComponent,
    WorkPackageRelationsCreateComponent,
    WorkPackageRelationsHierarchyComponent,
    WorkPackageRelationsAutocompleteComponent,
    WorkPackageBreadcrumbParentComponent,

    // Files tab
    WorkPackageFilesTabComponent,

    // Split view
    WorkPackageDetailsViewButtonComponent,
    WorkPackageSplitViewComponent,
    WorkPackageSplitViewEntryComponent,
    WorkPackageBreadcrumbComponent,
    WorkPackageSplitViewToolbarComponent,
    WorkPackageWatcherButtonComponent,
    WorkPackageShareButtonComponent,
    WorkPackageSubjectComponent,

    // Full view
    WorkPackagesFullViewComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationColumnsTabComponent,
    WpTableConfigurationDisplaySettingsTabComponent,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTabComponent,
    WpTableConfigurationTimelinesTabComponent,
    WpTableConfigurationHighlightingTabComponent,
    WpTableConfigurationRelationSelectorComponent,
    QuerySharingFormComponent,
    QuerySharingModalComponent,
    SaveQueryModalComponent,
    WpDestroyModalComponent,
    WorkPackageShareModalComponent,

    // CustomActions
    WpCustomActionComponent,
    WpCustomActionsComponent,
    CustomDateActionAdminComponent,

    // CKEditor macros which could not be included in the
    // editor module to avoid circular dependencies
    EmbeddedTablesMacroComponent,
    WpButtonMacroModalComponent,

    // Card view
    WorkPackageCardViewComponent,
    WorkPackageSingleCardComponent,

    // Notifications
    WorkPackageMarkNotificationButtonComponent,

    // Timestamps
    OpBaselineModalComponent,
    OpBaselineComponent,
    OpBaselineLoadingComponent,
    OpBaselineLegendsComponent,
  ],
  exports: [
    WorkPackagesTableComponent,
    WorkPackageTablePaginationComponent,
    WorkPackageEmbeddedTableComponent,
    WorkPackageEmbeddedTableEntryComponent,
    WorkPackageCardViewComponent,
    WorkPackageSingleCardComponent,
    WorkPackageFilterButtonComponent,
    WorkPackageFilterContainerComponent,
    QueryFiltersComponent,

    WpResizerDirective,
    WorkPackageBreadcrumbComponent,
    WorkPackageBreadcrumbParentComponent,
    WorkPackageSplitViewToolbarComponent,
    WorkPackageSubjectComponent,
    WorkPackagesGridComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationFiltersTab,

    // Needed so that e.g. IFC can access it.
    WorkPackageCreateButtonComponent,
    WorkPackageStatusButtonComponent,
    WorkPackageTypeStatusComponent,
    WorkPackageEditActionsBarComponent,
    WorkPackageSingleViewComponent,
    WorkPackageSplitViewComponent,
    BackButtonComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class OpenprojectWorkPackagesModule {
  static bootstrapAttributeGroupsCalled = false;

  constructor(private injector:Injector) {
    OpenprojectWorkPackagesModule.bootstrapAttributeGroups(injector);
  }

  // The static property prevents running the function
  // multiple times. This happens e.g. when the module is included
  // into a plugin's module.
  public static bootstrapAttributeGroups(injector:Injector):void {
    if (this.bootstrapAttributeGroupsCalled) {
      return;
    }

    this.bootstrapAttributeGroupsCalled = true;

    const hookService = injector.get(HookService);

    hookService.register('attributeGroupComponent', (group:GroupDescriptor, workPackage:WorkPackageResource) => {
      if (group.type === 'WorkPackageFormAttributeGroup') {
        return WorkPackageFormAttributeGroupComponent;
      }
      if (!isNewResource(workPackage) && group.type === 'WorkPackageFormChildrenQueryGroup') {
        return WorkPackageChildrenQueryComponent;
      }
      if (!isNewResource(workPackage) && group.type === 'WorkPackageFormRelationQueryGroup') {
        return WorkPackageRelationQueryComponent;
      }
      return null;
    });

    hookService.register('workPackageAttachmentListComponent', () => OpAttachmentsComponent);

    /** Return specialized work package changeset for editing service */
    hookService.register('halResourceChangesetClass', (resource:HalResource) => {
      switch (resource._type) {
        case 'WorkPackage':
          return WorkPackageChangeset;
        case 'TimeEntry':
          return TimeEntryChangeset;
        default:
          return null;
      }
    });
  }
}
