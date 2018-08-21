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
import {APP_INITIALIZER, ApplicationRef, Injector, NgModule} from '@angular/core';
import {FormsModule} from '@angular/forms';
import {BrowserModule} from '@angular/platform-browser';
import {TablePaginationComponent} from 'core-app/components/table-pagination/table-pagination.component';
import {QueryFormDmService} from 'core-app/modules/hal/dm-services/query-form-dm.service';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';

import {TimezoneService} from 'core-components/datetime/timezone.service';
import {FilterBooleanValueComponent} from 'core-components/filters/filter-boolean-value/filter-boolean-value.component';
import {WorkPackageFilterContainerComponent} from 'core-components/filters/filter-container/filter-container.directive';
import {FilterDateTimeValueComponent} from 'core-components/filters/filter-date-time-value/filter-date-time-value.component';
import {FilterDateTimesValueComponent} from 'core-components/filters/filter-date-times-value/filter-date-times-value.component';
import {FilterDateValueComponent} from 'core-components/filters/filter-date-value/filter-date-value.component';
import {FilterDatesValueComponent} from 'core-components/filters/filter-dates-value/filter-dates-value.component';
import {FilterIntegerValueComponent} from 'core-components/filters/filter-integer-value/filter-integer-value.component';
import {FilterStringValueComponent} from 'core-components/filters/filter-string-value/filter-string-value.component';
import {FilterToggledMultiselectValueComponent} from 'core-components/filters/filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import {QueryFilterComponent} from 'core-components/filters/query-filter/query-filter.component';
import {QueryFiltersComponent} from 'core-components/filters/query-filters/query-filters.component';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {OpColumnsContextMenu} from 'core-components/op-context-menu/handlers/op-columns-context-menu.directive';
import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OpSettingsMenuDirective} from 'core-components/op-context-menu/handlers/op-settings-dropdown-menu.directive';
import {OpTypesContextMenuDirective} from 'core-components/op-context-menu/handlers/op-types-context-menu.directive';
import {WorkPackageCreateSettingsMenuDirective} from 'core-components/op-context-menu/handlers/wp-create-settings-menu.directive';
import {WorkPackageStatusDropdownDirective} from 'core-components/op-context-menu/handlers/wp-status-dropdown-menu.directive';
import {OPContextMenuComponent} from 'core-components/op-context-menu/op-context-menu.component';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {WorkPackageSingleContextMenuDirective} from 'core-components/op-context-menu/wp-context-menu/wp-single-context-menu';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {CurrentProjectService} from 'core-components/projects/current-project.service';
import {ProjectCacheService} from 'core-components/projects/project-cache.service';
import {FirstRouteService} from 'core-components/routing/first-route-service';
import {WorkPackagesFullViewComponent} from 'core-components/routing/wp-full-view/wp-full-view.component';
import {WorkPackagesListComponent} from 'core-components/routing/wp-list/wp-list.component';
import {WorkPackageSplitViewComponent} from 'core-components/routing/wp-split-view/wp-split-view.component';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {States} from 'core-components/states.service';
import {ExpandableSearchComponent} from 'core-components/expandable-search/expandable-search.component';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {UserCacheService} from 'core-components/user/user-cache.service';
import {UserLinkComponent} from 'core-components/user/user-link/user-link.component';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageBreadcrumbComponent} from 'core-components/work-packages/wp-breadcrumb/wp-breadcrumb.component';
import {WorkPackageRelationsCountComponent} from 'core-components/work-packages/wp-relations-count/wp-relations-count.component';
import {WorkPackageSingleViewComponent} from 'core-components/work-packages/wp-single-view/wp-single-view.component';
import {WorkPackageSubjectComponent} from 'core-components/work-packages/wp-subject/wp-subject.component';
import {WorkPackageTypeStatusComponent} from 'core-components/work-packages/wp-type-status/wp-type-status.component';
import {WorkPackageWatcherButtonComponent} from 'core-components/work-packages/wp-watcher-button/wp-watcher-button.component';
import {WorkPackageCreateButtonComponent} from 'core-components/wp-buttons/wp-create-button/wp-create-button.component';
import {WorkPackageDetailsViewButtonComponent} from 'core-components/wp-buttons/wp-details-view-button/wp-details-view-button.component';
import {WorkPackageFilterButtonComponent} from 'core-components/wp-buttons/wp-filter-button/wp-filter-button.component';
import {WorkPackageStatusButtonComponent} from 'core-components/wp-buttons/wp-status-button/wp-status-button.component';
import {WorkPackageTimelineButtonComponent} from 'core-components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component';
import {ZenModeButtonComponent} from 'core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {WorkPackageCopyFullViewComponent} from 'core-components/wp-copy/wp-copy-full-view.component';
import {WorkPackageCopySplitViewComponent} from 'core-components/wp-copy/wp-copy-split-view.component';
import {WpCustomActionsComponent} from 'core-components/wp-custom-actions/wp-custom-actions.component';
import {WpCustomActionComponent} from 'core-components/wp-custom-actions/wp-custom-actions/wp-custom-action.component';
import {WorkPackageSplitViewToolbarComponent} from 'core-components/wp-details/wp-details-toolbar.component';
import {WorkPackageEditingService} from 'core-components/wp-edit-form/work-package-editing-service';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {WorkPackageEditFieldComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field.component';
import {WorkPackageReplacementLabelComponent} from 'core-components/wp-edit/wp-edit-field/wp-replacement-label.component';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {WorkPackageTableAdditionalElementsService} from 'core-components/wp-fast-table/state/wp-table-additional-elements.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageInlineCreateComponent} from 'core-components/wp-inline-create/wp-inline-create.component';
import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {WpResizerDirective} from 'core-components/resizer/wp-resizer.component';
import {MainMenuResizerComponent} from 'core-components/resizer/main-menu-resizer.component';
import {WorkPackageFormAttributeGroupComponent} from 'core-components/wp-form-group/wp-attribute-group.component';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {WorkPackagesListInvalidQueryService} from 'core-components/wp-list/wp-list-invalid-query.service';
import {WorkPackagesListService} from 'core-components/wp-list/wp-list.service';
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackageStatesInitializationService} from 'core-components/wp-list/wp-states-initialization.service';
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';
import {WorkPackageNewFullViewComponent} from 'core-components/wp-new/wp-new-full-view.component';
import {WorkPackageNewSplitViewComponent} from 'core-components/wp-new/wp-new-split-view.component';
import {WorkPackageQuerySelectDropdownComponent} from 'core-components/wp-query-select/wp-query-select-dropdown.component';
import {WorkPackageQuerySelectableTitleComponent} from 'core-components/wp-query-select/wp-query-selectable-title.component';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {WpRelationAddChildComponent} from 'core-components/wp-relations/wp-relation-add-child/wp-relation-add-child';
import {WorkPackageRelationsHierarchyComponent} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.directive';
import {WorkPackageRelationsHierarchyService} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WpRelationParentComponent} from 'core-components/wp-relations/wp-relations-parent/wp-relations-parent.component';
import {WorkPackageRelationsService} from 'core-components/wp-relations/wp-relations.service';
import {NewestActivityOnOverviewComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-on-overview.component';
import {WorkPackageActivityTabComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {WorkPackageOverviewTabComponent} from 'core-components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {WorkPackageRelationsTabComponent} from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {WorkPackageWatchersTabComponent} from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {WorkPackageWatcherEntryComponent} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watcher-entry.component';
import {WorkPackageWatchersService} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import {WpTableConfigurationDisplaySettingsTab} from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {WpTableConfigurationFiltersTab} from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';
import {WpTableConfigurationSortByTab} from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {WpTableConfigurationTimelinesTab} from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {WpTableConfigurationService} from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import {WorkPackageContextMenuHelperService} from 'core-components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {SortHeaderDirective} from 'core-components/wp-table/sort-header/sort-header.directive';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {WorkPackageTablePaginationComponent} from 'core-components/wp-table/table-pagination/wp-table-pagination.component';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {WorkPackageTimelineTableController} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import {WorkPackageTableTimelineRelations} from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {WorkPackageTableTimelineStaticElements} from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import {WorkPackageTableTimelineGrid} from 'core-components/wp-table/timeline/grid/wp-timeline-grid.directive';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {WorkPackageTableSumsRowController} from 'core-components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import {WorkPackagesTableController} from 'core-components/wp-table/wp-table.directive';
import {ExternalQueryConfigurationComponent} from 'core-components/wp-table/external-configuration/external-query-configuration.component';
import {ExternalQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-query-configuration.service';
import {WpTableExportModal} from "core-components/modals/export-modal/wp-table-export.modal";
import {ConfirmDialogModal} from "core-components/modals/confirm-dialog/confirm-dialog.modal";
import {ConfirmDialogService} from "core-components/modals/confirm-dialog/confirm-dialog.service";
import {DynamicContentModal} from "core-components/modals/modal-wrapper/dynamic-content.modal";
import {PasswordConfirmationModal} from "core-components/modals/request-for-confirmation/password-confirmation.modal";
import {QuerySharingModal} from "core-components/modals/share-modal/query-sharing.modal";
import {SaveQueryModal} from "core-components/modals/save-modal/save-query.modal";
import {QuerySharingForm} from "core-components/modals/share-modal/query-sharing-form.component";
import {WpDestroyModal} from "core-components/modals/wp-destroy-modal/wp-destroy.modal";
import {WorkPackageChildrenQueryComponent} from 'core-components/wp-relations/wp-relation-children/wp-children-query.component';
import {OpTitleService} from 'core-components/html/op-title.service';
import {WorkPackageRelationsComponent} from "core-components/wp-relations/wp-relations.component";
import {WorkPackageRelationsGroupComponent} from "core-components/wp-relations/wp-relations-group/wp-relations-group.component";
import {WorkPackageRelationRowComponent} from "core-components/wp-relations/wp-relation-row/wp-relation-row.component";
import {WorkPackageRelationsCreateComponent} from "core-components/wp-relations/wp-relations-create/wp-relations-create.component";
import {WpRelationsAutocompleteComponent} from "core-components/wp-relations/wp-relations-create/wp-relations-autocomplete/wp-relations-autocomplete.upgraded.component";
import {OpenprojectFieldsModule} from "core-app/modules/fields/openproject-fields.module";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {OpenprojectAccessibilityModule} from "core-app/modules/a11y/openproject-a11y.module";
import {ActivityEntryComponent} from "core-components/wp-activity/activity-entry.component";
import {UserActivityComponent} from "core-components/wp-activity/user/user-activity.component";
import {ActivityLinkComponent} from "core-components/wp-activity/activity-link.component";
import {RevisionActivityComponent} from "core-components/wp-activity/revision/revision-activity.component";
import {CommentService} from "core-components/wp-activity/comment-service";
import {WorkPackageCommentComponent} from "core-components/work-packages/work-package-comment/work-package-comment.component";
import {OpCkeditorFormComponent} from "core-components/ckeditor/op-ckeditor-form.component";
import {OpDragScrollDirective} from "core-app/modules/common/ui/op-drag-scroll.directive";
import {UIRouterModule} from "@uirouter/angular";
import {initializeUiRouterConfiguration} from "core-components/routing/ui-router.config";
import {WorkPackagesBaseComponent} from "core-components/routing/main/work-packages-base.component";
import {WorkPackageService} from "core-components/work-packages/work-package.service";
import {OpenprojectPluginsModule} from "core-app/modules/plugins/openproject-plugins.module";
import {ConfirmFormSubmitController} from "core-components/modals/confirm-form-submit/confirm-form-submit.directive";
import {ProjectMenuAutocompleteComponent} from "core-components/projects/project-menu-autocomplete/project-menu-autocomplete.component";
import {MainMenuToggleComponent} from "core-components/resizer/main-menu-toggle.component";
import {MainMenuToggleService} from "core-components/resizer/main-menu-toggle.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {OpenProjectFileUploadService} from "core-components/api/op-file-upload/op-file-upload.service";
import {AttributeHelpTextModal} from "./modules/common/help-texts/attribute-help-text.modal";
import {WorkPackageEmbeddedTableEntryComponent} from "core-components/wp-table/embedded/wp-embedded-table-entry.component";
import {LinkedPluginsModule} from "core-app/modules/plugins/linked-plugins.module";
import {HookService} from "core-app/modules/plugins/hook-service";
import {ModalWrapperAugmentService} from "core-app/globals/augmenting/modal-wrapper.augment.service";
import {EmbeddedTablesMacroComponent} from "core-components/wp-table/embedded/embedded-tables-macro.component";
import {WpButtonMacroModal} from "core-components/modals/editor/macro-wp-button-modal/wp-button-macro.modal";
import {EditorMacrosService} from "core-components/modals/editor/editor-macros.service";
import {WikiIncludePageMacroModal} from "core-components/modals/editor/macro-wiki-include-page-modal/wiki-include-page-macro.modal";
import {CodeBlockMacroModal} from "core-components/modals/editor/macro-code-block-modal/code-block-macro.modal";
import {CKEditorSetupService} from "core-components/ckeditor/ckeditor-setup.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {CKEditorPreviewService} from "core-components/ckeditor/ckeditor-preview.service";
import {ChildPagesMacroModal} from "core-components/modals/editor/macro-child-pages-modal/child-pages-macro.modal";
import {AttachmentListComponent} from 'core-components/attachments/attachment-list/attachment-list.component';
import {AttachmentListItemComponent} from 'core-components/attachments/attachment-list/attachment-list-item.component';
import {AttachmentsUploadComponent} from 'core-components/attachments/attachments-upload/attachments-upload.component';
import {AttachmentsComponent} from 'core-components/attachments/attachments.component';
import {CurrentUserService} from 'core-components/user/current-user.service';

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
    // Display + Edit field functionality
    OpenprojectFieldsModule,
    // Plugin hooks and modules
    OpenprojectPluginsModule,
    // Linked plugins dynamically generated by bundler
    LinkedPluginsModule
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
    TimezoneService,
    WorkPackageRelationsService,
    UrlParamsHelperService,
    WorkPackageCacheService,
    SchemaCacheService,
    ProjectCacheService,
    UserCacheService,
    CurrentUserService,
    {provide: States, useValue: new States()},
    PaginationService,
    KeepTabService,
    WorkPackageNotificationService,
    WorkPackagesListChecksumService,
    WorkPackageRelationsHierarchyService,
    WorkPackageFiltersService,
    WorkPackageService,
    ApiWorkPackagesService,
    OpenProjectFileUploadService,
    // Table and query states services
    WorkPackageTableRelationColumnsService,
    WorkPackageTablePaginationService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableTimelineService,
    WorkPackageTableSumService,
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
    OpTableActionsService,
    CurrentProjectService,
    FirstRouteService,
    // Split view
    CommentService,
    WorkPackagesActivityService,
    WorkPackageWatchersService,
    // Context menus
    OPContextMenuService,
    WorkPackageContextMenuHelperService,
    QueryFormDmService,
    TableState,

    // OP Modals service
    OpModalService,
    WpTableConfigurationService,
    ConfirmDialogService,

    // CKEditor
    CKEditorSetupService,
    EditorMacrosService,
    CKEditorPreviewService,

    // Main Menu
    MainMenuToggleService,

    // External query configuration
    ExternalQueryConfigurationService,

    // Augmenting Rails
    ModalWrapperAugmentService,

  ],
  declarations: [
    ConfirmFormSubmitController,
    WorkPackagesBaseComponent,
    WorkPackagesListComponent,
    OpContextMenuTrigger,
    TablePaginationComponent,
    WorkPackageTablePaginationComponent,
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements,
    WorkPackageTableTimelineGrid,
    WorkPackageTimelineTableController,
    WorkPackagesTableController,
    WorkPackageCreateButtonComponent,
    WorkPackageFilterButtonComponent,
    WorkPackageDetailsViewButtonComponent,
    WorkPackageTimelineButtonComponent,
    ZenModeButtonComponent,
    WpResizerDirective,
    MainMenuResizerComponent,
    WpCustomActionComponent,
    WpCustomActionsComponent,
    WorkPackageTableSumsRowController,
    SortHeaderDirective,

    // Query filters
    WorkPackageFilterContainerComponent,
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


    // Split view
    WorkPackageSplitViewComponent,
    WorkPackageRelationsCountComponent,
    WorkPackageBreadcrumbComponent,
    WorkPackageEditFieldGroupComponent,
    WorkPackageSplitViewToolbarComponent,
    WorkPackageWatcherButtonComponent,
    WorkPackageSubjectComponent,

    // Full view
    WorkPackagesFullViewComponent,

    // Single view
    WorkPackageOverviewTabComponent,
    WorkPackageSingleViewComponent,
    WorkPackageStatusButtonComponent,
    WorkPackageReplacementLabelComponent,
    UserLinkComponent,
    WorkPackageChildrenQueryComponent,
    WorkPackageFormAttributeGroupComponent,

    // Activity Tab
    NewestActivityOnOverviewComponent,
    WorkPackageCommentComponent,
    ActivityEntryComponent,
    UserActivityComponent,
    RevisionActivityComponent,
    ActivityLinkComponent,
    WorkPackageActivityTabComponent,

    // Relations Tab
    WorkPackageRelationsTabComponent,
    WorkPackageRelationsComponent,
    WorkPackageRelationsGroupComponent,
    WorkPackageRelationRowComponent,
    WorkPackageRelationsCreateComponent,
    WorkPackageRelationsHierarchyComponent,
    WpRelationsAutocompleteComponent,
    WpRelationAddChildComponent,
    WpRelationParentComponent,

    // Watchers tab
    WorkPackageWatchersTabComponent,
    WorkPackageWatcherEntryComponent,

    // Searchbar
    ExpandableSearchComponent,

    // WP Edit Fields
    WorkPackageEditFieldComponent,

    // WP New
    WorkPackageNewFullViewComponent,
    WorkPackageNewSplitViewComponent,
    WorkPackageTypeStatusComponent,

    // WP Copy
    WorkPackageCopyFullViewComponent,
    WorkPackageCopySplitViewComponent,

    // Context menus
    OpTypesContextMenuDirective,
    OPContextMenuComponent,
    OpColumnsContextMenu,
    OpSettingsMenuDirective,
    WorkPackageStatusDropdownDirective,
    WorkPackageCreateSettingsMenuDirective,
    WorkPackageSingleContextMenuDirective,
    WorkPackageQuerySelectableTitleComponent,
    WorkPackageQuerySelectDropdownComponent,

    // Inline create
    WorkPackageInlineCreateComponent,

    // Embedded table
    WorkPackageEmbeddedTableComponent,
    WorkPackageEmbeddedTableEntryComponent,
    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationColumnsTab,
    WpTableConfigurationDisplaySettingsTab,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTab,
    WpTableConfigurationTimelinesTab,
    WpTableExportModal,
    ConfirmDialogModal,
    DynamicContentModal,
    PasswordConfirmationModal,
    QuerySharingModal,
    SaveQueryModal,
    QuerySharingForm,
    WpDestroyModal,
    WpButtonMacroModal,
    WikiIncludePageMacroModal,
    CodeBlockMacroModal,
    ChildPagesMacroModal,

    // External query configuration
    ExternalQueryConfigurationComponent,

    // Main menu
    MainMenuResizerComponent,
    MainMenuToggleComponent,

    // Project autocompleter
    ProjectMenuAutocompleteComponent,

    // Form configuration
    OpDragScrollDirective,

    // CkEditor and Macros
    OpCkeditorFormComponent,
    EmbeddedTablesMacroComponent,

    // Attachments
    AttachmentsComponent,
    AttachmentListComponent,
    AttachmentListItemComponent,
    AttachmentsUploadComponent,
  ],
  entryComponents: [
    WorkPackagesBaseComponent,
    WorkPackagesListComponent,
    WorkPackageTablePaginationComponent,
    WorkPackagesTableController,
    TablePaginationComponent,
    WpCustomActionsComponent,

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
    WorkPackageEditFieldGroupComponent,

    // Searchbar
    ExpandableSearchComponent,

    // Project Auto completer
    ProjectMenuAutocompleteComponent,

    // WP new
    WorkPackageNewFullViewComponent,
    WorkPackageNewSplitViewComponent,

    // WP copy
    WorkPackageCopyFullViewComponent,
    WorkPackageCopySplitViewComponent,

    OPContextMenuComponent,
    WorkPackageQuerySelectDropdownComponent,

    // Embedded table
    WorkPackageEmbeddedTableComponent,
    WorkPackageEmbeddedTableEntryComponent,

    // Relations tab (ng1 -> ng2)
    WorkPackageRelationsHierarchyComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationColumnsTab,
    WpTableConfigurationDisplaySettingsTab,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTab,
    WpTableConfigurationTimelinesTab,
    WpTableExportModal,
    DynamicContentModal,
    ConfirmDialogModal,
    PasswordConfirmationModal,
    QuerySharingModal,
    SaveQueryModal,
    WpDestroyModal,
    AttributeHelpTextModal,
    WpButtonMacroModal,
    WikiIncludePageMacroModal,
    CodeBlockMacroModal,
    ChildPagesMacroModal,

    // External query configuration
    ExternalQueryConfigurationComponent,

    // Main menu
    MainMenuResizerComponent,
    MainMenuToggleComponent,

    // CKEditor and macros
    OpCkeditorFormComponent,
    EmbeddedTablesMacroComponent,

    // Attachments
    AttachmentsComponent,

    // Zen mode button
    ZenModeButtonComponent,
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
    const ModalWrapper = injector.get(ModalWrapperAugmentService);
    const EditorMacros = injector.get(EditorMacrosService);

    // Setup modal wrapping
    ModalWrapper.setupListener();

    // Setup query configuration listener
    ExternalQueryConfiguration.setupListener();
  };
}
