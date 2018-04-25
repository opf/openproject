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

import {APP_INITIALIZER, NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {UpgradeModule} from '@angular/upgrade/static';
import {FormsModule} from '@angular/forms';
import {TablePaginationComponent} from 'core-app/components/table-pagination/table-pagination.component';
import {SimpleTemplateRenderer} from 'core-components/angular/simple-template-renderer';
import {OpIcon} from 'core-components/common/icon/op-icon';
import {WorkPackagesListComponent} from 'core-components/routing/wp-list/wp-list.component';
import {States} from 'core-components/states.service';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {WorkPackageDisplayFieldService} from 'core-components/wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageEditingService} from 'core-components/wp-edit-form/work-package-editing-service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageInlineCreateComponent,} from 'core-components/wp-inline-create/wp-inline-create.component';
import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {WpResizerDirectiveUpgraded} from 'core-components/wp-resizer/wp-resizer.directive';
import {SortHeaderDirective} from 'core-components/wp-table/sort-header/sort-header.directive';
import {WorkPackageTablePaginationComponent} from 'core-components/wp-table/table-pagination/wp-table-pagination.component';
import {WorkPackageTimelineTableController} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import {WorkPackageTableTimelineRelations} from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {WorkPackageTableTimelineStaticElements} from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import {WorkPackageTableTimelineGrid} from 'core-components/wp-table/timeline/grid/wp-timeline-grid.directive';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {WorkPackageTableSumsRowController} from 'core-components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import {WorkPackagesTableController} from 'core-components/wp-table/wp-table.directive';
import {
  $localeToken,
  $qToken,
  $rootScopeToken,
  $sceToken,
  $stateToken,
  $timeoutToken,
  AutoCompleteHelperServiceToken,
  exportModalToken,
  FocusHelperToken,
  HookServiceToken,
  I18nToken,
  saveModalToken,
  settingsModalToken,
  shareModalToken,
  TextileServiceToken,
  upgradeService,
  upgradeServiceWithToken,
  wpDestroyModalToken,
  wpMoreMenuServiceToken
} from './angular4-transition-utils';
import {WpCustomActionComponent} from 'core-components/wp-custom-actions/wp-custom-actions/wp-custom-action.component';
import {WpCustomActionsComponent} from 'core-components/wp-custom-actions/wp-custom-actions.component';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {HideSectionComponent} from 'core-components/common/hide-section/hide-section.component';
import {HideSectionService} from 'core-components/common/hide-section/hide-section.service';
import {AddSectionDropdownComponent} from 'core-components/common/hide-section/add-section-dropdown/add-section-dropdown.component';
import {HideSectionLinkComponent} from 'core-components/common/hide-section/hide-section-link/hide-section-link.component';
import {GonRef} from 'core-components/common/gon-ref/gon-ref';
import {AuthorisationService} from 'core-components/common/model-auth/model-auth.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackagesListService} from 'core-components/wp-list/wp-list.service';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {LoadingIndicatorService} from 'core-components/common/loading-indicator/loading-indicator.service';
import {WorkPackageCreateButtonComponent} from 'core-components/wp-buttons/wp-create-button/wp-create-button.component';
import {WorkPackageFilterButtonComponent} from 'core-components/wp-buttons/wp-filter-button/wp-filter-button.directive';
import {WorkPackageDetailsViewButtonComponent} from 'core-components/wp-buttons/wp-details-view-button/wp-details-view-button.component';
import {WorkPackageTimelineButtonComponent} from 'core-components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component';
import {WorkPackageZenModeButtonComponent} from 'core-components/wp-buttons/wp-zen-mode-toggle-button/wp-zen-mode-toggle-button.component';
import {WorkPackageFilterContainerComponent} from 'core-components/filters/filter-container/filter-container.directive';
import WorkPackageFiltersService from 'core-components/filters/wp-filters/wp-filters.service';
import {UIRouterUpgradeModule} from '@uirouter/angular-hybrid';
import {WorkPackageSplitViewComponent} from 'core-components/routing/wp-split-view/wp-split-view.component';
import {WorkPackageBreadcrumbComponent} from 'core-components/work-packages/wp-breadcrumb/wp-breadcrumb.component';
import {WorkPackageRelationsCountComponent} from 'core-components/work-packages/wp-relations-count/wp-relations-count.component';
import {FirstRouteService} from 'core-components/routing/first-route-service';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {WorkPackageSubjectComponent} from 'core-components/work-packages/wp-subject/wp-subject.component';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {ConfigurationService} from 'core-components/common/config/configuration.service';
import {WorkPackageEditFieldComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field.component';
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';
import {WorkPackageWatcherButtonComponent} from 'core-components/work-packages/wp-watcher-button/wp-watcher-button.component';
import {WorkPackageSplitViewToolbarComponent} from 'core-components/wp-details/wp-details-toolbar.component';
import {WorkPackageOverviewTabComponent} from 'core-components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {CurrentProjectService} from 'core-components/projects/current-project.service';
import {WorkPackageSingleViewComponent} from 'core-components/work-packages/wp-single-view/wp-single-view.component';
import {WorkPackageStatusButtonComponent} from 'core-components/wp-buttons/wp-status-button/wp-status-button.component';
import {WorkPackageReplacementLabelComponent} from 'core-components/wp-edit/wp-edit-field/wp-replacement-label.component';
import {AuthoringComponent} from 'core-components/common/authoring/authoring.component';
import {Ng1WorkPackageAttachmentsUploadWrapper} from 'core-components/wp-attachments/wp-attachments-upload/wp-attachments-upload-ng1-wrapper';
import {WorkPackageAttachmentListComponent} from 'core-components/wp-attachments/wp-attachment-list/wp-attachment-list.component';
import {WorkPackageAttachmentListItemComponent} from 'core-components/wp-attachments/wp-attachment-list/wp-attachment-list-item.component';
import {OpDateTimeComponent} from 'core-components/common/date/op-date-time.component';
import {UserLinkComponent} from 'core-components/user/user-link/user-link.component';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {NewestActivityOnOverviewComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-on-overview.component';
import {WorkPackageCommentDirectiveUpgraded} from 'core-components/work-packages/work-package-comment/work-package-comment.directive.upgraded';
import {ActivityEntryDirectiveUpgraded} from 'core-components/wp-activity/activity-entry.directive.upgraded';
import {WorkPackagesFullViewComponent} from 'core-components/routing/wp-full-view/wp-full-view.component';
import {WorkPackageActivityTabComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import {WorkPackageRelationsTabComponent} from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {WorkPackageWatchersTabComponent} from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {Ng1RelationsDirectiveWrapper} from 'core-components/wp-relations/ng1-wp-relations-wrapper.directive';
import {WorkPackageWatcherEntryComponent} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watcher-entry.component';
import {WorkPackageNewFullViewComponent} from 'core-components/wp-new/wp-new-full-view.component';
import {WorkPackageTypeStatusComponent} from 'core-components/work-packages/wp-type-status/wp-type-status.component';
import {WorkPackageEditActionsBarComponent} from 'core-components/common/edit-actions-bar/wp-edit-actions-bar.component';
import {WorkPackageCopyFullViewComponent} from 'core-components/wp-copy/wp-copy-full-view.component';
import {WorkPackageNewSplitViewComponent} from 'core-components/wp-new/wp-new-split-view.component';
import {WorkPackageCopySplitViewComponent} from 'core-components/wp-copy/wp-copy-split-view.component';
import {FocusWithinDirective} from 'core-components/common/focus-within/focus-within.upgraded.directive';
import {ClickOnKeypressComponent} from 'core-app/ui_components/click-on-keypress-upgraded.component';
import {AutocompleteSelectDecorationComponent} from 'core-components/common/autocomplete-select-decoration/autocomplete-select-decoration.component';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {PortalModule} from '@angular/cdk/portal';
import {OPContextMenuComponent} from 'core-components/op-context-menu/op-context-menu.component';
import {WorkPackageRelationsHierarchyService} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {OpTypesContextMenuDirective} from 'core-components/op-context-menu/handlers/op-types-context-menu.directive';
import {WorkPackageContextMenuHelperService} from 'core-components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import {OpColumnsContextMenu} from 'core-components/op-context-menu/handlers/op-columns-context-menu.directive';
import {OpSettingsMenuDirective} from 'core-components/op-context-menu/handlers/op-settings-dropdown-menu.directive';
import {WorkPackageStatusDropdownDirective} from 'core-components/op-context-menu/handlers/wp-status-dropdown-menu.directive';
import {WorkPackageCreateSettingsMenuDirective} from 'core-components/op-context-menu/handlers/wp-create-settings-menu.directive';
import {WorkPackageSingleContextMenuDirective} from 'core-components/op-context-menu/wp-context-menu/wp-single-context-menu';
import {WorkPackageQuerySelectableTitleComponent} from 'core-components/wp-query-select/wp-query-selectable-title.component';
import {WorkPackageQuerySelectDropdownComponent} from 'core-components/wp-query-select/wp-query-select-dropdown.component';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {QueryMenuService} from 'core-components/wp-query-menu/wp-query-menu.service';
import {WorkPackageStatesInitializationService} from 'core-components/wp-list/wp-states-initialization.service';
import {WorkPackageTableAdditionalElementsService} from 'core-components/wp-fast-table/state/wp-table-additional-elements.service';
import {WorkPackagesListInvalidQueryService} from 'core-components/wp-list/wp-list-invalid-query.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageFieldService} from 'core-components/wp-field/wp-field.service';
import ExpressionService from 'core-components/common/xss/expression.service';
import {WorkPackageEditFieldService} from 'core-components/wp-edit/wp-edit-field/wp-edit-field.service';
import {WorkPackageEmbeddedTableComponent} from 'core-components/wp-table/embedded/wp-embedded-table.component';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {WorkPackageRelationsHierarchyComponent} from 'core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.directive';
import {Ng1RelationsCreateWrapper} from 'core-components/wp-relations/wp-relations-create/ng1-wp-relations-create.directive';
import {WpRelationsAutocompleteComponent} from 'core-components/wp-relations/wp-relations-create/wp-relations-autocomplete/wp-relations-autocomplete.upgraded.component';
import {WpRelationAddChildComponent} from 'core-components/wp-relations/wp-relation-add-child/wp-relation-add-child';
import {WpRelationParentComponent} from 'core-components/wp-relations/wp-relations-parent/wp-relations-parent.component';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';
import {QueryFormDmService} from 'core-app/modules/hal/dm-services/query-form-dm.service';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import {WpTableConfigurationDisplaySettingsTab} from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {WpTableConfigurationFiltersTab} from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';
import {WpTableConfigurationService} from 'core-components/wp-table/configuration-modal/wp-table-configuration.service';
import {WpTableConfigurationSortByTab} from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {WpTableConfigurationTimelinesTab} from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {QueryFilterComponent} from 'core-components/filters/query-filter/query-filter.component';
import {QueryFiltersComponent} from 'core-components/filters/query-filters/query-filters.component';
import {FilterDateValueComponent} from 'core-components/filters/filter-date-value/filter-date-value.component';
import {FilterDateTimeValueComponent} from 'core-components/filters/filter-date-time-value/filter-date-time-value.component';
import {FilterDateTimesValueComponent} from 'core-components/filters/filter-date-times-value/filter-date-times-value.component';
import {FilterDatesValueComponent} from 'core-components/filters/filter-dates-value/filter-dates-value.component';
import {FilterIntegerValueComponent} from 'core-components/filters/filter-integer-value/filter-integer-value.component';
import {FilterToggledMultiselectValueComponent} from 'core-components/filters/filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import {FilterStringValueComponent} from 'core-components/filters/filter-string-value/filter-string-value.component';
import {FilterBooleanValueComponent} from 'core-components/filters/filter-boolean-value/filter-boolean-value.component';
import {OpDatePickerComponent} from 'core-components/wp-edit/op-date-picker/op-date-picker.component';
import {AccessibleByKeyboardComponent} from 'core-components/a11y/accessible-by-keyboard.component';
import {WorkPackageFormQueryGroupComponent} from 'core-components/wp-form-group/wp-query-group.component';
import {WorkPackageFormAttributeGroupComponent} from 'core-components/wp-form-group/wp-attribute-group.component';
import {WorkPackageRelationsService} from 'core-components/wp-relations/wp-relations.service';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {AttributeHelpTextComponent} from 'core-components/common/help-texts/attribute-help-text.component';
import {AttributeHelpTextModal} from 'core-components/common/help-texts/attribute-help-text.modal';
import {AttributeHelpTextsService} from 'core-components/common/help-texts/attribute-help-text.service';
import {UserCacheService} from 'core-components/user/user-cache.service';
import {WorkPackageWatchersService} from 'core-components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import {ProjectCacheService} from 'core-components/projects/project-cache.service';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {NotificationsService} from 'core-components/common/notifications/notifications.service';
import {NotificationComponent} from 'core-components/common/notifications/notification.component';
import {NotificationsContainerComponent} from 'core-components/common/notifications/notifications-container.component';
import {UploadProgressComponent} from 'core-components/common/notifications/upload-progress.component';
import {ExternalQueryConfigurationComponent} from 'core-components/wp-table/external-configuration/external-query-configuration.component';
import {ExternalQueryConfigurationService} from 'core-components/wp-table/external-configuration/external-query-configuration.service';
import {WpTableExportModal} from "core-components/modals/export-modal/wp-table-export.modal";
import {ConfirmDialogModal} from "core-components/modals/confirm-dialog/confirm-dialog.modal";
import {ConfirmDialogService} from "core-components/modals/confirm-dialog/confirm-dialog.service";

@NgModule({
  imports: [
    BrowserModule,
    UpgradeModule,
    FormsModule,
    UIRouterUpgradeModule,
    // Angular CDK
    PortalModule,
    // Hal Module
    OpenprojectHalModule
  ],
  providers: [
    GonRef,
    HideSectionService,
    upgradeServiceWithToken('$rootScope', $rootScopeToken),
    upgradeServiceWithToken('I18n', I18nToken),
    upgradeServiceWithToken('$state', $stateToken),
    upgradeServiceWithToken('$sce', $sceToken),
    upgradeServiceWithToken('$q', $qToken),
    upgradeServiceWithToken('$timeout', $timeoutToken),
    upgradeServiceWithToken('$locale', $localeToken),
    upgradeServiceWithToken('textileService', TextileServiceToken),
    upgradeServiceWithToken('AutoCompleteHelper', AutoCompleteHelperServiceToken),
    NotificationsService,
    upgradeServiceWithToken('FocusHelper', FocusHelperToken),
    PathHelperService,
    upgradeServiceWithToken('wpMoreMenuService', wpMoreMenuServiceToken),
    TimezoneService,
    upgradeServiceWithToken('wpDestroyModal', wpDestroyModalToken),
    upgradeServiceWithToken('shareModal', shareModalToken),
    upgradeServiceWithToken('saveModal', saveModalToken),
    upgradeServiceWithToken('settingsModal', settingsModalToken),
    upgradeServiceWithToken('exportModal', exportModalToken),
    upgradeService('wpRelations', WorkPackageRelationsService),
    UrlParamsHelperService,
    WorkPackageCacheService,
    WorkPackageEditingService,
    SchemaCacheService,
    ProjectCacheService,
    UserCacheService,
    upgradeService('states', States),
    PaginationService,
    upgradeService('keepTab', KeepTabService),
    upgradeService('templateRenderer', SimpleTemplateRenderer),
    upgradeService('wpDisplayField', WorkPackageDisplayFieldService),
    WorkPackageNotificationService,
    WorkPackagesListChecksumService,
    WorkPackageRelationsHierarchyService,
    upgradeService('wpFiltersService', WorkPackageFiltersService),
    upgradeService('loadingIndicator', LoadingIndicatorService),
    ApiWorkPackagesService,
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
    WorkPackageTableRefreshService,
    WorkPackageTableAdditionalElementsService,
    WorkPackagesListInvalidQueryService,
    WorkPackageTableFocusService,
    WorkPackageTableSelection,
    WorkPackageFieldService,
    WorkPackageDisplayFieldService,
    WorkPackageEditFieldService,
    ExpressionService,
    WorkPackageCreateService,
    OpTableActionsService,
    upgradeService('authorisationService', AuthorisationService),
    ConfigurationService,
    upgradeService('currentProject', CurrentProjectService),
    QueryMenuService,
    // Split view
    upgradeService('firstRoute', FirstRouteService),
    PathHelperService,
    WorkPackagesActivityService,
    WorkPackageWatchersService,
    // Context menus
    OPContextMenuService,
    upgradeServiceWithToken('HookService', HookServiceToken),
    WorkPackageContextMenuHelperService,
    QueryFormDmService,
    TableState,

    // OP Modals service
    OpModalService,
    WpTableConfigurationService,
    ConfirmDialogService,

    AttributeHelpTextsService,
    // External query configuration
    ExternalQueryConfigurationService,
  ],
  declarations: [
    WorkPackagesListComponent,
    OpIcon,
    OpDatePickerComponent,
    AccessibleByKeyboardComponent,
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
    WorkPackageZenModeButtonComponent,
    WpResizerDirectiveUpgraded,
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

    // Add functionality to rails rendered templates
    HideSectionComponent,
    HideSectionLinkComponent,
    AddSectionDropdownComponent,
    AutocompleteSelectDecorationComponent,

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
    AttributeHelpTextComponent,
    WorkPackageReplacementLabelComponent,
    FocusWithinDirective,
    AuthoringComponent,
    Ng1WorkPackageAttachmentsUploadWrapper,
    WorkPackageAttachmentListComponent,
    WorkPackageAttachmentListItemComponent,
    OpDateTimeComponent,
    UserLinkComponent,
    ClickOnKeypressComponent,
    WorkPackageFormQueryGroupComponent,
    WorkPackageFormAttributeGroupComponent,

    // Activity Tab
    NewestActivityOnOverviewComponent,
    WorkPackageCommentDirectiveUpgraded,
    ActivityEntryDirectiveUpgraded,
    WorkPackageActivityTabComponent,

    // Relations Tab
    WorkPackageRelationsTabComponent,
    Ng1RelationsDirectiveWrapper,
    Ng1RelationsCreateWrapper,
    WorkPackageRelationsHierarchyComponent,
    WpRelationsAutocompleteComponent,
    WpRelationAddChildComponent,
    WpRelationParentComponent,

    // Watchers tab
    WorkPackageWatchersTabComponent,
    WorkPackageWatcherEntryComponent,

    // WP Edit Fields
    WorkPackageEditFieldComponent,

    // WP New
    WorkPackageNewFullViewComponent,
    WorkPackageNewSplitViewComponent,
    WorkPackageTypeStatusComponent,
    WorkPackageEditActionsBarComponent,

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
    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationColumnsTab,
    WpTableConfigurationDisplaySettingsTab,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTab,
    WpTableConfigurationTimelinesTab,
    AttributeHelpTextModal,
    WpTableExportModal,
    ConfirmDialogModal,

    // Notifications
    NotificationsContainerComponent,
    NotificationComponent,
    UploadProgressComponent,

    // External query configuration
    ExternalQueryConfigurationComponent,
  ],
  entryComponents: [
    WorkPackagesListComponent,
    WorkPackageTablePaginationComponent,
    WorkPackagesTableController,
    TablePaginationComponent,
    WpCustomActionsComponent,

    // Add functionality to rails rendered templates
    HideSectionComponent,
    HideSectionLinkComponent,
    AddSectionDropdownComponent,
    AutocompleteSelectDecorationComponent,

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

    // Relations tab (ng1 -> ng2)
    WorkPackageRelationsHierarchyComponent,

    // Modals
    WpTableConfigurationModalComponent,
    WpTableConfigurationColumnsTab,
    WpTableConfigurationDisplaySettingsTab,
    WpTableConfigurationFiltersTab,
    WpTableConfigurationSortByTab,
    WpTableConfigurationTimelinesTab,
    AttributeHelpTextModal,
    WpTableExportModal,
    ConfirmDialogModal,

    // Notifications
    NotificationsContainerComponent,
    OpDateTimeComponent,

    // Entries for ng1 downgraded components
    AttributeHelpTextComponent,

    // External query configuration
    ExternalQueryConfigurationComponent,
  ]
})
export class OpenProjectModule {
  constructor(private upgrade:UpgradeModule) {
  }

  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap() {
    // Already done in openproject-app.ts
    // this.upgrade.bootstrap(document.body, ['openproject'], {strictDi: false});
  }
}


