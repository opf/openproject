import { OptionalBootstrapDefinition } from 'core-app/core/setup/globals/dynamic-bootstrapper';
import { appBaseSelector, ApplicationBaseComponent } from 'core-app/core/routing/base/application-base.component';
import {
  ColorsAutocompleterComponent,
  colorsAutocompleterSelector,
} from 'core-app/shared/components/colors/colors-autocompleter.component';
import {
  ZenModeButtonComponent,
  zenModeComponentSelector,
} from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {
  attachmentsSelector,
  OpAttachmentsComponent,
} from 'core-app/shared/components/attachments/attachments.component';
import {
  GlobalSearchWorkPackagesComponent,
  globalSearchWorkPackagesSelector,
} from 'core-app/core/global_search/global-search-work-packages.component';
import {
  CustomDateActionAdminComponent,
  customDateActionAdminSelector,
} from 'core-app/features/work-packages/components/wp-custom-actions/date-action/custom-date-action-admin.component';
import { BoardsMenuComponent, boardsMenuSelector } from 'core-app/features/boards/boards-sidebar/boards-menu.component';
import {
  GlobalSearchWorkPackagesEntryComponent,
  globalSearchWorkPackagesSelectorEntry,
} from 'core-app/core/global_search/global-search-work-packages-entry.component';
import {
  ToastsContainerComponent,
  toastsContainerSelector,
} from 'core-app/shared/components/toaster/toasts-container.component';
import { OpSidemenuComponent, sidemenuSelector } from 'core-app/shared/components/sidemenu/sidemenu.component';
import {
  CkeditorAugmentedTextareaComponent,
  ckeditorAugmentedTextareaSelector,
} from 'core-app/shared/components/editor/components/ckeditor-augmented-textarea/ckeditor-augmented-textarea.component';
import {
  PersistentToggleComponent,
  persistentToggleSelector,
} from 'core-app/shared/components/persistent-toggle/persistent-toggle.component';
import {
  HideSectionLinkComponent,
  hideSectionLinkSelector,
} from 'core-app/shared/components/hide-section/hide-section-link/hide-section-link.component';
import {
  ShowSectionDropdownComponent,
  showSectionDropdownSelector,
} from 'core-app/shared/components/hide-section/show-section-dropdown.component';
import {
  AddSectionDropdownComponent,
  addSectionDropdownSelector,
} from 'core-app/shared/components/hide-section/add-section-dropdown/add-section-dropdown.component';
import {
  ContentTabsComponent,
  contentTabsSelector,
} from 'core-app/shared/components/tabs/content-tabs/content-tabs.component';
import {
  CopyToClipboardComponent,
  copyToClipboardSelector,
} from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.component';
import {
  collapsibleSectionAugmentSelector,
  CollapsibleSectionComponent,
} from 'core-app/shared/components/collapsible-section/collapsible-section.component';
import {
  headerProjectSelectSelector,
  OpHeaderProjectSelectComponent,
} from 'core-app/shared/components/header-project-select/header-project-select.component';
import {
  RemoteFieldUpdaterComponent,
  remoteFieldUpdaterSelector,
} from 'core-app/shared/components/remote-field-updater/remote-field-updater.component';
import {
  WorkPackageOverviewGraphComponent,
  wpOverviewGraphSelector,
} from 'core-app/shared/components/work-package-graphs/overview/wp-overview-graph.component';
import {
  opViewSelectSelector,
  ViewSelectComponent,
} from 'core-app/shared/components/op-view-select/op-view-select.component';
import {
  GlobalSearchTitleComponent,
  globalSearchTitleSelector,
} from 'core-app/core/global_search/title/global-search-title.component';
import {
  GlobalSearchTabsComponent,
  globalSearchTabsSelector,
} from 'core-app/core/global_search/tabs/global-search-tabs.component';
import {
  TriggerActionsEntryComponent,
  triggerActionsEntryComponentSelector,
} from 'core-app/shared/components/time_entries/edit/trigger-actions-entry.component';
import {
  BacklogsPageComponent,
  backlogsPageComponentSelector,
} from 'core-app/features/backlogs/backlogs-page/backlogs-page.component';
import {
  AttributeHelpTextComponent,
  attributeHelpTextSelector,
} from 'core-app/shared/components/attribute-help-texts/attribute-help-text.component';
import { SpotSwitchComponent, spotSwitchSelector } from 'core-app/spot/components/switch/switch.component';
import { BackupComponent, backupSelector } from 'core-app/core/setup/globals/components/admin/backup.component';
import {
  EnterpriseBaseComponent,
  enterpriseBaseSelector,
} from 'core-app/features/enterprise/enterprise-base.component';
import {
  FreeTrialButtonComponent,
  freeTrialButtonSelector,
} from 'core-app/features/enterprise/free-trial-button/free-trial-button.component';
import {
  EnterpriseBannerComponent,
  enterpriseBannerSelector,
} from 'core-app/shared/components/enterprise-banner/enterprise-banner.component';
import {
  EnterprisePageComponent,
  enterprisePageSelector,
} from 'core-app/shared/components/enterprise-page/enterprise-page.component';
import {
  nonWorkingDaysListSelector,
  OpNonWorkingDaysListComponent,
} from 'core-app/shared/components/op-non-working-days-list/op-non-working-days-list.component';
import {
  EEActiveSavedTrialComponent,
  enterpriseActiveSavedTrialSelector,
} from 'core-app/features/enterprise/enterprise-active-trial/ee-active-saved-trial.component';
import { NoResultsComponent, noResultsSelector } from 'app/shared/components/no-results/no-results.component';
import {
  HomescreenNewFeaturesBlockComponent,
  homescreenNewFeaturesBlockSelector,
} from 'core-app/features/homescreen/blocks/new-features.component';
import { MainMenuToggleComponent, mainMenuToggleSelector } from 'core-app/core/main-menu/main-menu-toggle.component';
import {
  MainMenuResizerComponent,
  mainMenuResizerSelector,
} from 'core-app/shared/components/resizer/resizer/main-menu-resizer.component';
import {
  adminTypeFormConfigurationSelector,
  TypeFormConfigurationComponent,
} from 'core-app/features/admin/types/type-form-configuration.component';
import {
  EditableQueryPropsComponent,
  editableQueryPropsSelector,
} from 'core-app/features/admin/editable-query-props/editable-query-props.component';
import {
  InAppNotificationBellComponent,
  opInAppNotificationBellSelector,
} from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import { IanMenuComponent, ianMenuSelector } from 'core-app/features/in-app-notifications/center/menu/menu.component';
import {
  opTeamPlannerSidemenuSelector,
  TeamPlannerSidemenuComponent,
} from 'core-app/features/team-planner/team-planner/sidemenu/team-planner-sidemenu.component';
import {
  CalendarSidemenuComponent,
  opCalendarSidemenuSelector,
} from 'core-app/features/calendar/sidemenu/calendar-sidemenu.component';
import {
  OpModalOverlayComponent,
  opModalOverlaySelector,
} from 'core-app/shared/components/modal/modal-overlay.component';
import {
  OpModalSingleDatePickerComponent,
  opModalSingleDatePickerSelector,
} from 'core-app/shared/components/datepicker/modal-single-date-picker/modal-single-date-picker.component';
import {
  OpBasicSingleDatePickerComponent,
  opBasicSingleDatePickerSelector,
} from 'core-app/shared/components/datepicker/basic-single-date-picker/basic-single-date-picker.component';
import {
  SpotDropModalPortalComponent,
  spotDropModalPortalComponentSelector,
} from 'core-app/spot/components/drop-modal/drop-modal-portal.component';
import {
  StaticAttributeHelpTextComponent,
  staticAttributeHelpTextSelector,
} from 'core-app/shared/components/attribute-help-texts/static-attribute-help-text.component';
import {
  opStorageLoginButtonSelector,
  StorageLoginButtonComponent,
} from 'core-app/shared/components/storages/storage-login-button/storage-login-button.component';
import {
  TimerAccountMenuComponent,
  timerAccountSelector,
} from 'core-app/shared/components/time_entries/timer/timer-account-menu.component';
import {
  DraggableAutocompleteComponent,
  opDraggableAutocompleteSelector,
} from 'core-app/shared/components/autocompleter/draggable-autocomplete/draggable-autocomplete.component';

export const globalDynamicComponents:OptionalBootstrapDefinition[] = [
  { selector: appBaseSelector, cls: ApplicationBaseComponent },
  { selector: attributeHelpTextSelector, cls: AttributeHelpTextComponent },
  { selector: staticAttributeHelpTextSelector, cls: StaticAttributeHelpTextComponent },
  { selector: colorsAutocompleterSelector, cls: ColorsAutocompleterComponent },
  { selector: zenModeComponentSelector, cls: ZenModeButtonComponent },
  { selector: attachmentsSelector, cls: OpAttachmentsComponent, embeddable: true },
  { selector: globalSearchTabsSelector, cls: GlobalSearchTabsComponent },
  { selector: globalSearchWorkPackagesSelector, cls: GlobalSearchWorkPackagesComponent },
  { selector: homescreenNewFeaturesBlockSelector, cls: HomescreenNewFeaturesBlockComponent },
  { selector: customDateActionAdminSelector, cls: CustomDateActionAdminComponent },
  { selector: boardsMenuSelector, cls: BoardsMenuComponent },
  { selector: globalSearchWorkPackagesSelectorEntry, cls: GlobalSearchWorkPackagesEntryComponent },
  { selector: toastsContainerSelector, cls: ToastsContainerComponent },
  { selector: sidemenuSelector, cls: OpSidemenuComponent },
  { selector: adminTypeFormConfigurationSelector, cls: TypeFormConfigurationComponent },
  { selector: ckeditorAugmentedTextareaSelector, cls: CkeditorAugmentedTextareaComponent, embeddable: true },
  { selector: persistentToggleSelector, cls: PersistentToggleComponent },
  { selector: hideSectionLinkSelector, cls: HideSectionLinkComponent },
  { selector: showSectionDropdownSelector, cls: ShowSectionDropdownComponent },
  { selector: addSectionDropdownSelector, cls: AddSectionDropdownComponent },
  { selector: contentTabsSelector, cls: ContentTabsComponent },
  { selector: globalSearchTitleSelector, cls: GlobalSearchTitleComponent },
  { selector: copyToClipboardSelector, cls: CopyToClipboardComponent },
  { selector: mainMenuResizerSelector, cls: MainMenuResizerComponent },
  { selector: mainMenuToggleSelector, cls: MainMenuToggleComponent },
  { selector: collapsibleSectionAugmentSelector, cls: CollapsibleSectionComponent },
  { selector: enterpriseBannerSelector, cls: EnterpriseBannerComponent },
  { selector: nonWorkingDaysListSelector, cls: OpNonWorkingDaysListComponent },
  { selector: enterprisePageSelector, cls: EnterprisePageComponent },
  { selector: noResultsSelector, cls: NoResultsComponent },
  { selector: enterpriseBaseSelector, cls: EnterpriseBaseComponent },
  { selector: freeTrialButtonSelector, cls: FreeTrialButtonComponent },
  { selector: enterpriseActiveSavedTrialSelector, cls: EEActiveSavedTrialComponent },
  { selector: headerProjectSelectSelector, cls: OpHeaderProjectSelectComponent },
  { selector: wpOverviewGraphSelector, cls: WorkPackageOverviewGraphComponent },
  { selector: opViewSelectSelector, cls: ViewSelectComponent },
  { selector: opTeamPlannerSidemenuSelector, cls: TeamPlannerSidemenuComponent },
  { selector: opCalendarSidemenuSelector, cls: CalendarSidemenuComponent },
  { selector: triggerActionsEntryComponentSelector, cls: TriggerActionsEntryComponent, embeddable: true },
  { selector: backlogsPageComponentSelector, cls: BacklogsPageComponent },
  { selector: editableQueryPropsSelector, cls: EditableQueryPropsComponent },
  { selector: backupSelector, cls: BackupComponent },
  { selector: opInAppNotificationBellSelector, cls: InAppNotificationBellComponent },
  { selector: ianMenuSelector, cls: IanMenuComponent },

  { selector: opModalOverlaySelector, cls: OpModalOverlayComponent },
  { selector: spotDropModalPortalComponentSelector, cls: SpotDropModalPortalComponent },
  { selector: spotSwitchSelector, cls: SpotSwitchComponent },
  { selector: opStorageLoginButtonSelector, cls: StorageLoginButtonComponent },

  { selector: opModalSingleDatePickerSelector, cls: OpModalSingleDatePickerComponent, embeddable: true },
  { selector: opBasicSingleDatePickerSelector, cls: OpBasicSingleDatePickerComponent, embeddable: true },

  // It is important to initialize the remoteFieldUpdaterSelector after the datepickers,
  // because we need to access the input field of the datepickers inside the remoteFieldUpdaterSelector
  { selector: remoteFieldUpdaterSelector, cls: RemoteFieldUpdaterComponent },

  { selector: timerAccountSelector, cls: TimerAccountMenuComponent },

  { selector: opDraggableAutocompleteSelector, cls: DraggableAutocompleteComponent },
];
