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

import {OpenprojectCommonModule} from 'core-app/modules/common/openproject-common.module';
import {WorkPackageFormAttributeGroupComponent} from 'core-components/wp-form-group/wp-attribute-group.component';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';
import {OpenprojectFieldsModule} from 'core-app/modules/fields/openproject-fields.module';
import {ChartsModule} from 'ng2-charts';
import {DynamicModule} from 'ng-dynamic-component';
import {APP_INITIALIZER, Injector, NgModule} from '@angular/core';
import {
  GroupDescriptor,
  WorkPackageSingleViewComponent
} from 'core-components/work-packages/wp-single-view/wp-single-view.component';
import {HookService} from 'core-app/modules/plugins/hook-service';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {WorkPackageEmbeddedTableEntryComponent} from 'core-components/wp-table/embedded/wp-embedded-table-entry.component';
import {WorkPackagesTableController} from 'core-components/wp-table/wp-table.directive';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTablePaginationComponent} from 'core-components/wp-table/table-pagination/wp-table-pagination.component';
import {WpResizerDirective} from 'core-components/resizer/wp-resizer.component';
import {WorkPackageTimelineTableController} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import {WorkPackageInlineCreateComponent} from 'core-components/wp-inline-create/wp-inline-create.component';
import {WpRelationsAutocompleteComponent} from 'core-components/wp-relations/wp-relations-create/wp-relations-autocomplete/wp-relations-autocomplete.upgraded.component';
import {OpTypesContextMenuDirective} from 'core-components/op-context-menu/handlers/op-types-context-menu.directive';
import {OpColumnsContextMenu} from 'core-components/op-context-menu/handlers/op-columns-context-menu.directive';
import {OpSettingsMenuDirective} from 'core-components/op-context-menu/handlers/op-settings-dropdown-menu.directive';
import {WorkPackageStatusDropdownDirective} from 'core-components/op-context-menu/handlers/wp-status-dropdown-menu.directive';
import {WorkPackageCreateSettingsMenuDirective} from 'core-components/op-context-menu/handlers/wp-create-settings-menu.directive';
import {WorkPackageSingleContextMenuDirective} from 'core-components/op-context-menu/wp-context-menu/wp-single-context-menu';
import {WorkPackageQuerySelectableTitleComponent} from 'core-components/wp-query-select/wp-query-selectable-title.component';
import {WorkPackageQuerySelectDropdownComponent} from 'core-components/wp-query-select/wp-query-select-dropdown.component';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {WorkPackageTableTimelineRelations} from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {WorkPackageTableTimelineStaticElements} from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import {WorkPackageTableTimelineGrid} from 'core-components/wp-table/timeline/grid/wp-timeline-grid.directive';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTimelineButtonComponent} from 'core-components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component';
import {WorkPackageOverviewTabComponent} from 'core-components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {WorkPackageStatusButtonComponent} from 'core-components/wp-buttons/wp-status-button/wp-status-button.component';
import {WorkPackageReplacementLabelComponent} from 'core-components/wp-edit/wp-edit-field/wp-replacement-label.component';
import {NewestActivityOnOverviewComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-on-overview.component';
import {UserLinkComponent} from 'core-components/user/user-link/user-link.component';
import {WorkPackageCommentComponent} from 'core-components/work-packages/work-package-comment/work-package-comment.component';
import {WorkPackageCommentFieldComponent} from 'core-components/work-packages/work-package-comment/wp-comment-field.component';
import {ActivityEntryComponent} from 'core-components/wp-activity/activity-entry.component';
import {UserActivityComponent} from 'core-components/wp-activity/user/user-activity.component';
import {RevisionActivityComponent} from 'core-components/wp-activity/revision/revision-activity.component';
import {ActivityLinkComponent} from 'core-components/wp-activity/activity-link.component';
import {WorkPackageActivityTabComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import {OpenprojectAttachmentsModule} from 'core-app/modules/attachments/openproject-attachments.module';
import {WorkPackageEditFieldComponent} from 'core-app/components/wp-edit/wp-edit-field/wp-edit-field.component';
import {WpCustomActionComponent} from 'core-components/wp-custom-actions/wp-custom-actions/wp-custom-action.component';
import {WpCustomActionsComponent} from 'core-components/wp-custom-actions/wp-custom-actions.component';
import {WorkPackageRelationsCountComponent} from 'core-components/work-packages/wp-relations-count/wp-relations-count.component';
import {WorkPackageWatchersCountComponent} from 'core-components/work-packages/wp-relations-count/wp-watchers-count.component';
import {WorkPackageBreadcrumbComponent} from 'core-components/work-packages/wp-breadcrumb/wp-breadcrumb.component';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {WorkPackageSplitViewToolbarComponent} from 'core-components/wp-details/wp-details-toolbar.component';
import {WorkPackageWatcherButtonComponent} from 'core-components/work-packages/wp-watcher-button/wp-watcher-button.component';
import {WorkPackageSubjectComponent} from 'core-components/work-packages/wp-subject/wp-subject.component';
import {WorkPackageRelationsTabComponent} from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {WorkPackageRelationsComponent} from 'core-components/wp-relations/wp-relations.component';
import {WorkPackageRelationsGroupComponent} from 'core-components/wp-relations/wp-relations-group/wp-relations-group.component';
import {WorkPackageRelationRowComponent} from 'core-components/wp-relations/wp-relation-row/wp-relation-row.component';
import {WorkPackageRelationsCreateComponent} from 'core-components/wp-relations/wp-relations-create/wp-relations-create.component';
import {WorkPackageRelationsHierarchyComponent} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.directive';
import {WorkPackageCreateButtonComponent} from 'core-components/wp-buttons/wp-create-button/wp-create-button.component';
import {FullCalendarModule} from 'ng-fullcalendar';
import {WorkPackageBreadcrumbParentComponent} from 'core-components/work-packages/wp-breadcrumb/wp-breadcrumb-parent.component';
import {WorkPackageFilterButtonComponent} from 'core-components/wp-buttons/wp-filter-button/wp-filter-button.component';
import {WorkPackageFilterContainerComponent} from 'core-components/filters/filter-container/filter-container.directive';
import {QueryFiltersComponent} from 'core-components/filters/query-filters/query-filters.component';
import {QueryFilterComponent} from 'core-components/filters/query-filter/query-filter.component';
import {FilterBooleanValueComponent} from 'core-components/filters/filter-boolean-value/filter-boolean-value.component';
import {FilterDateValueComponent} from 'core-components/filters/filter-date-value/filter-date-value.component';
import {FilterDatesValueComponent} from 'core-components/filters/filter-dates-value/filter-dates-value.component';
import {FilterDateTimeValueComponent} from 'core-components/filters/filter-date-time-value/filter-date-time-value.component';
import {FilterDateTimesValueComponent} from 'core-components/filters/filter-date-times-value/filter-date-times-value.component';
import {FilterIntegerValueComponent} from 'core-components/filters/filter-integer-value/filter-integer-value.component';
import {FilterStringValueComponent} from 'core-components/filters/filter-string-value/filter-string-value.component';
import {FilterToggledMultiselectValueComponent} from 'core-components/filters/filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import {WorkPackageDetailsViewButtonComponent} from 'core-components/wp-buttons/wp-details-view-button/wp-details-view-button.component';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import {WpTableConfigurationDisplaySettingsTab} from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {WpTableConfigurationFiltersTab} from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';
import {WpTableConfigurationSortByTab} from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {WpTableConfigurationTimelinesTab} from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {WpTableConfigurationHighlightingTab} from 'core-components/wp-table/configuration-modal/tabs/highlighting-tab.component';
import {WpTableConfigurationRelationSelectorComponent} from "core-components/wp-table/configuration-modal/wp-table-configuration-relation-selector";
import {WorkPackageWatchersTabComponent} from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {WorkPackageWatcherEntryComponent} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watcher-entry.component';
import {WorkPackageCopyFullViewComponent} from 'core-components/wp-copy/wp-copy-full-view.component';
import {WorkPackageCopySplitViewComponent} from 'core-components/wp-copy/wp-copy-split-view.component';
import {WorkPackageTypeStatusComponent} from 'core-components/work-packages/wp-type-status/wp-type-status.component';
import {WorkPackageNewSplitViewComponent} from 'core-components/wp-new/wp-new-split-view.component';
import {WorkPackageNewFullViewComponent} from 'core-components/wp-new/wp-new-full-view.component';
import {WpTableExportModal} from 'core-components/modals/export-modal/wp-table-export.modal';
import {QuerySharingModal} from 'core-components/modals/share-modal/query-sharing.modal';
import {SaveQueryModal} from 'core-components/modals/save-modal/save-query.modal';
import {WpDestroyModal} from 'core-components/modals/wp-destroy-modal/wp-destroy.modal';
import {QuerySharingForm} from 'core-components/modals/share-modal/query-sharing-form.component';
import {WorkPackageEmbeddedGraphComponent} from 'core-components/wp-table/embedded/wp-embedded-graph.component';
import {WorkPackageByVersionGraphComponent} from 'core-components/wp-by-version-graph/wp-by-version-graph.component';
import {EmbeddedTablesMacroComponent} from 'core-components/wp-table/embedded/embedded-tables-macro.component';
import {WpButtonMacroModal} from 'core-components/modals/editor/macro-wp-button-modal/wp-button-macro.modal';
import {OpenprojectEditorModule} from 'core-app/modules/editor/openproject-editor.module';
import {WorkPackageTableSumsRowController} from 'core-components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import {ExternalQueryConfigurationComponent} from 'core-components/wp-table/external-configuration/external-query-configuration.component';
import {ExternalQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-query-configuration.service';
import {ExternalRelationQueryConfigurationComponent} from "core-components/wp-table/external-configuration/external-relation-query-configuration.component";
import {ExternalRelationQueryConfigurationService} from "core-components/wp-table/external-configuration/external-relation-query-configuration.service";
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableHighlightingService} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';
import {WorkPackageStatesInitializationService} from 'core-components/wp-list/wp-states-initialization.service';
import {WorkPackagesListService} from 'core-components/wp-list/wp-list.service';
import {WorkPackageTableAdditionalElementsService} from 'core-components/wp-fast-table/state/wp-table-additional-elements.service';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackagesListInvalidQueryService} from 'core-components/wp-list/wp-list-invalid-query.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {IWorkPackageCreateServiceToken} from 'core-components/wp-new/wp-create.service.interface';
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';
import {WorkPackageEditingService} from 'core-components/wp-edit-form/work-package-editing-service';
import {IWorkPackageEditingServiceToken} from 'core-components/wp-edit-form/work-package-editing.service.interface';
import {WorkPackageInlineCreateService} from 'core-components/wp-inline-create/wp-inline-create.service';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {WorkPackageRelationsService} from 'core-components/wp-relations/wp-relations.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageContextMenuHelperService} from 'core-components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import {WorkPackageWatchersService} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageService} from 'core-components/work-packages/work-package.service';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {WorkPackageRelationsHierarchyService} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {QueryFormDmService} from 'core-app/modules/hal/dm-services/query-form-dm.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {WpTableConfigurationService} from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageChildrenQueryComponent} from "core-components/wp-relations/embedded/children/wp-children-query.component";
import {WpRelationInlineAddExistingComponent} from "core-components/wp-relations/embedded/inline/add-existing/wp-relation-inline-add-existing.component";
import {WorkPackageRelationQueryComponent} from "core-components/wp-relations/embedded/relations/wp-relation-query.component";
import {WpRelationInlineCreateService} from "core-components/wp-relations/embedded/relations/wp-relation-inline-create.service";
import {WpChildrenInlineCreateService} from "core-components/wp-relations/embedded/children/wp-children-inline-create.service";
import {WorkPackagesBaseComponent} from "core-app/modules/work_packages/routing/wp-base/wp--base.component";
import {WorkPackagesListComponent} from "core-app/modules/work_packages/routing/wp-list/wp-list.component";
import {WorkPackageSplitViewComponent} from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";
import {WorkPackagesFullViewComponent} from "core-app/modules/work_packages/routing/wp-full-view/wp-full-view.component";
import {AttachmentsUploadComponent} from 'core-app/modules/attachments/attachments-upload/attachments-upload.component';
import {AttachmentListComponent} from 'core-app/modules/attachments/attachment-list/attachment-list.component';
import {WorkPackageFilterByTextInputComponent} from "core-components/filters/quick-filter-by-text-input/quick-filter-by-text-input.component";

@NgModule({
  imports: [
    // Commons
    OpenprojectCommonModule,
    // Display + Edit field functionality
    OpenprojectFieldsModule,
    // CKEditor
    OpenprojectEditorModule,

    ChartsModule,

    OpenprojectAttachmentsModule,

    // Work package custom actions
    //WpCustomActionsModule,
    DynamicModule.withComponents([WorkPackageFormAttributeGroupComponent, WorkPackageChildrenQueryComponent])
  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: OpenprojectWorkPackagesModule.bootstrapAttributeGroups,
      deps: [Injector],
      multi: true
    },
    WorkPackageTablePaginationService,

    // Timeline
    WorkPackageTableTimelineService,

    // External query configuration
    ExternalQueryConfigurationService,
    ExternalRelationQueryConfigurationService,

    // Table and query states services
    WorkPackageTableRelationColumnsService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableSumService,
    WorkPackageTableHighlightingService,
    WorkPackageStatesInitializationService,
    WorkPackagesListService,
    WorkPackageStaticQueriesService,
    WorkPackageTableRefreshService,
    WorkPackageTableAdditionalElementsService,
    WorkPackagesListInvalidQueryService,
    WorkPackageTableFocusService,
    WorkPackageTableSelection,

    // Provide both serves with tokens to avoid tight dependency cycles
    { provide: IWorkPackageCreateServiceToken, useClass: WorkPackageCreateService },
    { provide: IWorkPackageEditingServiceToken, useClass: WorkPackageEditingService },

    // Provide a separate service for creation events of WP Inline create
    // This can be hierarchically injected to provide isolated events on an embedded table
    WorkPackageInlineCreateService,
    WpChildrenInlineCreateService,
    WpRelationInlineCreateService,

    OpTableActionsService,

    WorkPackageRelationsService,
    WorkPackageCacheService,
    SchemaCacheService,

    KeepTabService,
    WorkPackageNotificationService,
    WorkPackagesListChecksumService,
    WorkPackageRelationsHierarchyService,
    WorkPackageFiltersService,
    WorkPackageService,
    ApiWorkPackagesService,

    WorkPackagesActivityService,
    WorkPackageWatchersService,

    WorkPackageContextMenuHelperService,

    QueryFormDmService,
    TableState,

    WpTableConfigurationService,
  ],
  declarations: [
    // Routing
    WorkPackagesBaseComponent,
    WorkPackagesListComponent,

    // WP New
    WorkPackageNewFullViewComponent,
    WorkPackageNewSplitViewComponent,
    WorkPackageTypeStatusComponent,

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

    WorkPackagesTableController,
    WorkPackageTablePaginationComponent,

    WpResizerDirective,

    WorkPackageTableSumsRowController,

    // WP Edit Fields
    WorkPackageEditFieldComponent,

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

    WorkPackageFilterContainerComponent,
    WorkPackageFilterButtonComponent,

    // Context menus
    OpTypesContextMenuDirective,
    OpColumnsContextMenu,
    OpSettingsMenuDirective,
    WorkPackageStatusDropdownDirective,
    WorkPackageCreateSettingsMenuDirective,
    WorkPackageSingleContextMenuDirective,
    WorkPackageQuerySelectableTitleComponent,
    WorkPackageQuerySelectDropdownComponent,

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
    WpRelationsAutocompleteComponent,
    WorkPackageBreadcrumbParentComponent,

    // Split view
    WorkPackageDetailsViewButtonComponent,
    WorkPackageSplitViewComponent,
    WorkPackageRelationsCountComponent,
    WorkPackageWatchersCountComponent,
    WorkPackageBreadcrumbComponent,
    WorkPackageEditFieldGroupComponent,
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

    // CustomActions
    WpCustomActionComponent,
    WpCustomActionsComponent,

    // Embedded graphs
    WorkPackageEmbeddedGraphComponent,
    // Work package graphs on version page
    WorkPackageByVersionGraphComponent,

    // CKEditor macros which could not be included in the
    // editor module to avoid circular dependencies
    EmbeddedTablesMacroComponent,
    WpButtonMacroModal,
  ],
  entryComponents: [
    // Split view
    WorkPackageSplitViewComponent,

    // Full view
    WorkPackagesFullViewComponent,

    // Single view tabs
    WorkPackageActivityTabComponent,
    WorkPackageRelationsTabComponent,
    WorkPackageWatchersTabComponent,

    // Single view
    WorkPackageOverviewTabComponent,
    WorkPackageCommentFieldComponent,

    // Inline create
    WpRelationInlineAddExistingComponent,
    WorkPackagesBaseComponent,
    WorkPackagesListComponent,

    // WP new
    WorkPackageNewFullViewComponent,
    WorkPackageNewSplitViewComponent,

    // WP copy
    WorkPackageCopyFullViewComponent,
    WorkPackageCopySplitViewComponent,

    // Embedded table
    WorkPackageEmbeddedTableComponent,
    WorkPackageEmbeddedTableEntryComponent,

    // External query configuration
    ExternalQueryConfigurationComponent,
    ExternalRelationQueryConfigurationComponent,

    WorkPackageFormAttributeGroupComponent,
    WorkPackageChildrenQueryComponent,
    WorkPackageRelationQueryComponent,

    WorkPackagesTableController,

    // Work package graphs on version page
    WorkPackageByVersionGraphComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationRelationSelectorComponent,
    WpTableConfigurationColumnsTab,
    WpTableConfigurationDisplaySettingsTab,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTab,
    WpTableConfigurationTimelinesTab,
    WpTableConfigurationHighlightingTab,
    WpTableExportModal,
    QuerySharingModal,
    SaveQueryModal,
    WpDestroyModal,

    // Queries in menu
    WorkPackageQuerySelectDropdownComponent,

    // Relations tab (ng1 -> ng2)
    WorkPackageRelationsHierarchyComponent,

    // CKEditor macros which could not be included in the
    // editor module to avoid circular dependencies
    EmbeddedTablesMacroComponent,
    WpButtonMacroModal,
  ],
  exports: [
    WorkPackagesTableController,
    WorkPackageTablePaginationComponent,
    WorkPackageEmbeddedTableComponent,
    WorkPackageFilterButtonComponent,
    WorkPackageFilterContainerComponent,
  ]
})
export class OpenprojectWorkPackagesModule {
  static bootstrapAttributeGroupsCalled = false;

  // The static property prevents running the function
  // multiple times. This happens e.g. when the module is included
  // into a plugin's module.
  public static bootstrapAttributeGroups(injector:Injector) {
    if (this.bootstrapAttributeGroupsCalled) {
      return () => {
        // no op
      };
    }

    this.bootstrapAttributeGroupsCalled = true;

    return () => {
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
    };
  }
}
