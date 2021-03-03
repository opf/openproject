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

import { Injector, NgModule } from '@angular/core';
import { OpenprojectCommonModule } from 'core-app/modules/common/openproject-common.module';
import { OpenprojectFieldsModule } from 'core-app/modules/fields/openproject-fields.module';
import { OpenprojectModalModule } from 'core-app/modules/modal/modal.module';
import { HookService } from 'core-app/modules/plugins/hook-service';
import {
  GroupDescriptor,
  WorkPackageSingleViewComponent
} from 'core-components/work-packages/wp-single-view/wp-single-view.component';
import { WorkPackageFormAttributeGroupComponent } from 'core-components/wp-form-group/wp-attribute-group.component';
import { WorkPackageEmbeddedTableComponent } from 'core-components/wp-table/embedded/wp-embedded-table.component';
import { WorkPackageEmbeddedTableEntryComponent } from 'core-components/wp-table/embedded/wp-embedded-table-entry.component';
import { WorkPackageTablePaginationComponent } from 'core-components/wp-table/table-pagination/wp-table-pagination.component';
import { WpResizerDirective } from 'core-components/resizer/wp-resizer.component';
import { WorkPackageTimelineTableController } from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import { WorkPackageInlineCreateComponent } from 'core-components/wp-inline-create/wp-inline-create.component';
import { OpTypesContextMenuDirective } from 'core-components/op-context-menu/handlers/op-types-context-menu.directive';
import { OpColumnsContextMenu } from 'core-components/op-context-menu/handlers/op-columns-context-menu.directive';
import { OpSettingsMenuDirective } from 'core-components/op-context-menu/handlers/op-settings-dropdown-menu.directive';
import { WorkPackageStatusDropdownDirective } from 'core-components/op-context-menu/handlers/wp-status-dropdown-menu.directive';
import { WorkPackageCreateSettingsMenuDirective } from 'core-components/op-context-menu/handlers/wp-create-settings-menu.directive';
import { WorkPackageSingleContextMenuDirective } from 'core-components/op-context-menu/wp-context-menu/wp-single-context-menu';
import { WorkPackageQuerySelectDropdownComponent } from 'core-components/wp-query-select/wp-query-select-dropdown.component';
import { WorkPackageTimelineHeaderController } from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import { WorkPackageTableTimelineRelations } from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import { WorkPackageTableTimelineStaticElements } from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import { WorkPackageTableTimelineGrid } from 'core-components/wp-table/timeline/grid/wp-timeline-grid.directive';
import { WorkPackageTimelineButtonComponent } from 'core-components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component';
import { WorkPackageOverviewTabComponent } from 'core-components/wp-single-view-tabs/overview-tab/overview-tab.component';
import { WorkPackageStatusButtonComponent } from 'core-components/wp-buttons/wp-status-button/wp-status-button.component';
import { WorkPackageReplacementLabelComponent } from 'core-components/wp-edit/wp-edit-field/wp-replacement-label.component';
import { NewestActivityOnOverviewComponent } from 'core-components/wp-single-view-tabs/activity-panel/activity-on-overview.component';
import { UserLinkComponent } from 'core-components/user/user-link/user-link.component';
import { WorkPackageCommentComponent } from 'core-components/work-packages/work-package-comment/work-package-comment.component';
import { WorkPackageCommentFieldComponent } from 'core-components/work-packages/work-package-comment/wp-comment-field.component';
import { ActivityEntryComponent } from 'core-components/wp-activity/activity-entry.component';
import { UserActivityComponent } from 'core-components/wp-activity/user/user-activity.component';
import { RevisionActivityComponent } from 'core-components/wp-activity/revision/revision-activity.component';
import { ActivityLinkComponent } from 'core-components/wp-activity/activity-link.component';
import { WorkPackageActivityTabComponent } from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import { OpenprojectAttachmentsModule } from 'core-app/modules/attachments/openproject-attachments.module';
import { WpCustomActionComponent } from 'core-components/wp-custom-actions/wp-custom-actions/wp-custom-action.component';
import { WpCustomActionsComponent } from 'core-components/wp-custom-actions/wp-custom-actions.component';
import { WorkPackageRelationsCountComponent } from 'core-components/work-packages/wp-relations-count/wp-relations-count.component';
import { WorkPackageWatchersCountComponent } from 'core-components/work-packages/wp-relations-count/wp-watchers-count.component';
import { WorkPackageBreadcrumbComponent } from 'core-components/work-packages/wp-breadcrumb/wp-breadcrumb.component';
import { WorkPackageSplitViewToolbarComponent } from 'core-components/wp-details/wp-details-toolbar.component';
import { WorkPackageWatcherButtonComponent } from 'core-components/work-packages/wp-watcher-button/wp-watcher-button.component';
import { WorkPackageSubjectComponent } from 'core-components/work-packages/wp-subject/wp-subject.component';
import { WorkPackageRelationsTabComponent } from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import { WorkPackageRelationsComponent } from 'core-components/wp-relations/wp-relations.component';
import { WorkPackageRelationsGroupComponent } from 'core-components/wp-relations/wp-relations-group/wp-relations-group.component';
import { WorkPackageRelationRowComponent } from 'core-components/wp-relations/wp-relation-row/wp-relation-row.component';
import { WorkPackageRelationsCreateComponent } from 'core-components/wp-relations/wp-relations-create/wp-relations-create.component';
import { WorkPackageRelationsHierarchyComponent } from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.directive';
import { WorkPackageCreateButtonComponent } from 'core-components/wp-buttons/wp-create-button/wp-create-button.component';
import { WorkPackageBreadcrumbParentComponent } from 'core-components/work-packages/wp-breadcrumb/wp-breadcrumb-parent.component';
import { WorkPackageFilterButtonComponent } from 'core-components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { WorkPackageFilterContainerComponent } from 'core-components/filters/filter-container/filter-container.directive';
import { QueryFiltersComponent } from 'core-components/filters/query-filters/query-filters.component';
import { QueryFilterComponent } from 'core-components/filters/query-filter/query-filter.component';
import { FilterBooleanValueComponent } from 'core-components/filters/filter-boolean-value/filter-boolean-value.component';
import { FilterDateValueComponent } from 'core-components/filters/filter-date-value/filter-date-value.component';
import { FilterDatesValueComponent } from 'core-components/filters/filter-dates-value/filter-dates-value.component';
import { FilterDateTimeValueComponent } from 'core-components/filters/filter-date-time-value/filter-date-time-value.component';
import { FilterDateTimesValueComponent } from 'core-components/filters/filter-date-times-value/filter-date-times-value.component';
import { FilterIntegerValueComponent } from 'core-components/filters/filter-integer-value/filter-integer-value.component';
import { FilterStringValueComponent } from 'core-components/filters/filter-string-value/filter-string-value.component';
import { FilterToggledMultiselectValueComponent } from 'core-components/filters/filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import { FilterSearchableMultiselectValueComponent } from 'core-components/filters/filter-searchable-multiselect-value/filter-searchable-multiselect-value.component';
import { WorkPackageDetailsViewButtonComponent } from 'core-components/wp-buttons/wp-details-view-button/wp-details-view-button.component';
import { WorkPackageFoldToggleButtonComponent } from 'core-components/wp-buttons/wp-fold-toggle-button/wp-fold-toggle-button.component';
import { WpTableConfigurationModalComponent } from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import { WpTableConfigurationColumnsTab } from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import { WpTableConfigurationDisplaySettingsTab } from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import { WpTableConfigurationFiltersTab } from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';
import { WpTableConfigurationSortByTab } from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import { WpTableConfigurationTimelinesTab } from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import { WpTableConfigurationHighlightingTab } from 'core-components/wp-table/configuration-modal/tabs/highlighting-tab.component';
import { WpTableConfigurationRelationSelectorComponent } from "core-components/wp-table/configuration-modal/wp-table-configuration-relation-selector";
import { WorkPackageWatchersTabComponent } from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import { WorkPackageWatcherEntryComponent } from 'core-components/wp-single-view-tabs/watchers-tab/wp-watcher-entry.component';
import { WorkPackageCopyFullViewComponent } from 'core-components/wp-copy/wp-copy-full-view.component';
import { WorkPackageCopySplitViewComponent } from 'core-components/wp-copy/wp-copy-split-view.component';
import { WorkPackageTypeStatusComponent } from 'core-components/work-packages/wp-type-status/wp-type-status.component';
import { WorkPackageNewSplitViewComponent } from 'core-components/wp-new/wp-new-split-view.component';
import { WorkPackageNewFullViewComponent } from 'core-components/wp-new/wp-new-full-view.component';
import { WpTableExportModal } from 'core-components/modals/export-modal/wp-table-export.modal';
import { QuerySharingModal } from 'core-components/modals/share-modal/query-sharing.modal';
import { SaveQueryModal } from 'core-components/modals/save-modal/save-query.modal';
import { WpDestroyModal } from 'core-components/modals/wp-destroy-modal/wp-destroy.modal';
import { QuerySharingForm } from 'core-components/modals/share-modal/query-sharing-form.component';
import { EmbeddedTablesMacroComponent } from 'core-components/wp-table/embedded/embedded-tables-macro.component';
import { WpButtonMacroModal } from 'core-components/modals/editor/macro-wp-button-modal/wp-button-macro.modal';
import { OpenprojectEditorModule } from 'core-app/modules/editor/openproject-editor.module';
import { WorkPackageTableSumsRowController } from 'core-components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import { ExternalQueryConfigurationComponent } from 'core-components/wp-table/external-configuration/external-query-configuration.component';
import { ExternalQueryConfigurationService } from 'core-components/wp-table/external-configuration/external-query-configuration.service';
import { ExternalRelationQueryConfigurationComponent } from "core-components/wp-table/external-configuration/external-relation-query-configuration.component";
import { ExternalRelationQueryConfigurationService } from "core-components/wp-table/external-configuration/external-relation-query-configuration.service";
import { WorkPackageStaticQueriesService } from 'core-components/wp-query-select/wp-static-queries.service';
import { WorkPackagesListInvalidQueryService } from 'core-components/wp-list/wp-list-invalid-query.service';
import { SchemaCacheService } from 'core-components/schemas/schema-cache.service';
import { WorkPackageWatchersService } from 'core-components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import { WorkPackagesActivityService } from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { WorkPackageChildrenQueryComponent } from "core-components/wp-relations/embedded/children/wp-children-query.component";
import { WpRelationInlineAddExistingComponent } from "core-components/wp-relations/embedded/inline/add-existing/wp-relation-inline-add-existing.component";
import { WorkPackageRelationQueryComponent } from "core-components/wp-relations/embedded/relations/wp-relation-query.component";
import { WorkPackagesBaseComponent } from "core-app/modules/work_packages/routing/wp-base/wp--base.component";
import { WorkPackageSplitViewComponent } from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";
import { WorkPackagesFullViewComponent } from "core-app/modules/work_packages/routing/wp-full-view/wp-full-view.component";
import { AttachmentsUploadComponent } from 'core-app/modules/attachments/attachments-upload/attachments-upload.component';
import { AttachmentListComponent } from 'core-app/modules/attachments/attachment-list/attachment-list.component';
import { WorkPackageFilterByTextInputComponent } from "core-components/filters/quick-filter-by-text-input/quick-filter-by-text-input.component";
import { QueryFiltersService } from "core-components/wp-query/query-filters.service";
import { WorkPackageCardViewComponent } from "core-components/wp-card-view/wp-card-view.component";
import { WorkPackageIsolatedQuerySpaceDirective } from "core-app/modules/work_packages/query-space/wp-isolated-query-space.directive";
import { WorkPackageRelationsService } from "core-components/wp-relations/wp-relations.service";
import { OpenprojectBcfModule } from "core-app/modules/bim/bcf/openproject-bcf.module";
import { WorkPackageRelationsAutocomplete } from "core-components/wp-relations/wp-relations-create/wp-relations-autocomplete/wp-relations-autocomplete.component";
import { CustomDateActionAdminComponent } from 'core-components/wp-custom-actions/date-action/custom-date-action-admin.component';
import { WorkPackagesTableConfigMenu } from "core-components/wp-table/config-menu/config-menu.component";
import { WorkPackageIsolatedGraphQuerySpaceDirective } from "core-app/modules/work_packages/query-space/wp-isolated-graph-query-space.directive";
import { WorkPackageViewToggleButton } from "core-components/wp-buttons/wp-view-toggle-button/work-package-view-toggle-button.component";
import { WorkPackagesGridComponent } from "core-components/wp-grid/wp-grid.component";
import { WorkPackageViewDropdownMenuDirective } from "core-components/op-context-menu/handlers/wp-view-dropdown-menu.directive";
import { HalEventsService } from "core-app/modules/hal/services/hal-events.service";
import { OpenprojectProjectsModule } from "core-app/modules/projects/openproject-projects.module";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { WorkPackageEditActionsBarComponent } from "core-app/modules/common/edit-actions-bar/wp-edit-actions-bar.component";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { WorkPackageChangeset } from "core-components/wp-edit/work-package-changeset";
import { WorkPackageSingleCardComponent } from "core-components/wp-card-view/wp-single-card/wp-single-card.component";
import { TimeEntryChangeset } from 'core-app/components/time-entries/time-entry-changeset';
import { WorkPackageListViewComponent } from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import { PartitionedQuerySpacePageComponent } from "core-app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component";
import { WorkPackageViewPageComponent } from "core-app/modules/work_packages/routing/wp-view-page/wp-view-page.component";
import { WorkPackageSettingsButtonComponent } from "core-components/wp-buttons/wp-settings-button/wp-settings-button.component";
import { BackButtonComponent } from "core-app/modules/common/back-routing/back-button.component";
import { DatePickerModal } from "core-components/datepicker/datepicker.modal";
import { WorkPackagesTableComponent } from "core-components/wp-table/wp-table.component";
import { WorkPackageGroupToggleDropdownMenuDirective } from "core-components/op-context-menu/handlers/wp-group-toggle-dropdown-menu.directive";
import { OpenprojectAutocompleterModule } from "core-app/modules/autocompleter/openproject-autocompleter.module";

@NgModule({
  imports: [
    // Commons
    OpenprojectCommonModule,
    // Display + Edit field functionality
    OpenprojectFieldsModule,
    // CKEditor
    OpenprojectEditorModule,

    OpenprojectAttachmentsModule,

    OpenprojectBcfModule,

    OpenprojectProjectsModule,

    OpenprojectModalModule,

    OpenprojectAutocompleterModule,
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
    WorkPackageStaticQueriesService,
    WorkPackagesListInvalidQueryService,

    // Provide a separate service for creation events of WP Inline create
    // This can be hierarchically injected to provide isolated events on an embedded table
    WorkPackageRelationsService,

    WorkPackagesActivityService,
    WorkPackageRelationsService,
    WorkPackageWatchersService,

    HalEventsService,
  ],
  declarations: [
    // Routing
    WorkPackagesBaseComponent,
    PartitionedQuerySpacePageComponent,
    WorkPackageViewPageComponent,

    // WP list side
    WorkPackageListViewComponent,
    WorkPackageSettingsButtonComponent,

    // Query injector isolation
    WorkPackageIsolatedQuerySpaceDirective,
    WorkPackageIsolatedGraphQuerySpaceDirective,

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
    WorkPackagesTableConfigMenu,
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
    WorkPackageQuerySelectDropdownComponent,
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

    // Activity Tab
    NewestActivityOnOverviewComponent,
    WorkPackageCommentComponent,
    WorkPackageCommentFieldComponent,
    ActivityEntryComponent,
    UserActivityComponent,
    RevisionActivityComponent,
    ActivityLinkComponent,
    WorkPackageActivityTabComponent,

    // Watchers tab
    WorkPackageWatchersTabComponent,
    WorkPackageWatcherEntryComponent,

    // Relations
    WorkPackageRelationsTabComponent,
    WorkPackageRelationsComponent,
    WorkPackageRelationsGroupComponent,
    WorkPackageRelationRowComponent,
    WorkPackageRelationsCreateComponent,
    WorkPackageRelationsHierarchyComponent,
    WorkPackageRelationsAutocomplete,
    WorkPackageBreadcrumbParentComponent,

    // Split view
    WorkPackageDetailsViewButtonComponent,
    WorkPackageSplitViewComponent,
    WorkPackageRelationsCountComponent,
    WorkPackageWatchersCountComponent,
    WorkPackageBreadcrumbComponent,
    WorkPackageSplitViewToolbarComponent,
    WorkPackageWatcherButtonComponent,
    WorkPackageSubjectComponent,

    // Full view
    WorkPackagesFullViewComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationColumnsTab,
    WpTableConfigurationDisplaySettingsTab,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTab,
    WpTableConfigurationTimelinesTab,
    WpTableConfigurationHighlightingTab,
    WpTableConfigurationRelationSelectorComponent,
    WpTableExportModal,
    QuerySharingForm,
    QuerySharingModal,
    SaveQueryModal,
    WpDestroyModal,
    DatePickerModal,

    // CustomActions
    WpCustomActionComponent,
    WpCustomActionsComponent,
    CustomDateActionAdminComponent,

    // CKEditor macros which could not be included in the
    // editor module to avoid circular dependencies
    EmbeddedTablesMacroComponent,
    WpButtonMacroModal,

    // Card view
    WorkPackageCardViewComponent,
    WorkPackageSingleCardComponent,
    WorkPackageViewToggleButton,


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
    WorkPackageIsolatedQuerySpaceDirective,
    WorkPackageIsolatedGraphQuerySpaceDirective,
    QueryFiltersComponent,

    WpResizerDirective,
    WorkPackageBreadcrumbComponent,
    WorkPackageBreadcrumbParentComponent,
    WorkPackageSplitViewToolbarComponent,
    WorkPackageSubjectComponent,
    WorkPackageWatchersCountComponent,
    WorkPackageRelationsCountComponent,
    WorkPackagesGridComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationFiltersTab,

    // Needed so that e.g. IFC can access it.
    WorkPackageCreateButtonComponent,
    WorkPackageTypeStatusComponent,
    WorkPackageEditActionsBarComponent,
    WorkPackageSingleViewComponent,
    WorkPackageSplitViewComponent,
    BackButtonComponent,
  ]
})
export class OpenprojectWorkPackagesModule {
  static bootstrapAttributeGroupsCalled = false;

  constructor(injector:Injector) {
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
      } else if (!workPackage.isNew && group.type === 'WorkPackageFormChildrenQueryGroup') {
        return WorkPackageChildrenQueryComponent;
      } else if (!workPackage.isNew && group.type === 'WorkPackageFormRelationQueryGroup') {
        return WorkPackageRelationQueryComponent;
      } else {
        return null;
      }
    });

    hookService.register('workPackageAttachmentUploadComponent', (workPackage:WorkPackageResource) => {
      return AttachmentsUploadComponent;
    });

    hookService.register('workPackageAttachmentListComponent', (workPackage:WorkPackageResource) => {
      return AttachmentListComponent;
    });

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
