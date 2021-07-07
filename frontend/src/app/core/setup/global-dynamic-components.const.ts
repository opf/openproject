import { OptionalBootstrapDefinition } from 'core-app/core/setup/globals/dynamic-bootstrapper';
import { appBaseSelector, ApplicationBaseComponent } from 'core-app/core/routing/base/application-base.component';
import {
  EmbeddedTablesMacroComponent,
  wpEmbeddedTableMacroSelector,
} from 'core-app/features/work-packages/components/wp-table/embedded/embedded-tables-macro.component';
import {
  ColorsAutocompleterComponent,
  colorsAutocompleterSelector,
} from 'core-app/shared/components/colors/colors-autocompleter.component';
import {
  ZenModeButtonComponent,
  zenModeComponentSelector,
} from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {
  AttachmentsComponent,
  attachmentsSelector,
} from 'core-app/shared/components/attachments/attachments.component';
import {
  UserAutocompleterComponent,
  usersAutocompleterSelector,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
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
  NotificationsContainerComponent,
  notificationsContainerSelector,
} from 'core-app/shared/components/notifications/notifications-container.component';
import {
  CkeditorAugmentedTextareaComponent,
  ckeditorAugmentedTextareaSelector,
} from 'core-app/shared/components/editor/components/ckeditor-augmented-textarea/ckeditor-augmented-textarea.component';
import {
  PersistentToggleComponent,
  persistentToggleSelector,
} from 'core-app/shared/components/persistent-toggle/persistent-toggle.component';
import { OpPrincipalComponent, principalSelector } from 'core-app/shared/components/principal/principal.component';
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
  AutocompleteSelectDecorationComponent,
  autocompleteSelectDecorationSelector,
} from 'core-app/shared/components/autocompleter/autocomplete-select-decoration/autocomplete-select-decoration.component';
import {
  ContentTabsComponent,
  contentTabsSelector,
} from 'core-app/shared/components/tabs/content-tabs/content-tabs.component';
import {
  CopyToClipboardDirective,
  copyToClipboardSelector,
} from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.directive';
import {
  GlobalSearchInputComponent,
  globalSearchSelector,
} from 'core-app/core/global_search/input/global-search-input.component';
import {
  collapsibleSectionAugmentSelector,
  CollapsibleSectionComponent,
} from 'core-app/shared/components/collapsible-section/collapsible-section.component';
import {
  ProjectMenuAutocompleteComponent,
  projectMenuAutocompleteSelector,
} from 'core-app/shared/components/autocompleter//project-menu-autocomplete/project-menu-autocomplete.component';
import {
  RemoteFieldUpdaterComponent,
  remoteFieldUpdaterSelector,
} from 'core-app/shared/components/remote-field-updater/remote-field-updater.component';
import {
  WorkPackageOverviewGraphComponent,
  wpOverviewGraphSelector,
} from 'core-app/shared/components/work-package-graphs/overview/wp-overview-graph.component';
import {
  WorkPackageQuerySelectDropdownComponent,
  wpQuerySelectSelector,
} from 'core-app/features/work-packages/components/wp-query-select/wp-query-select-dropdown.component';
import {
  GlobalSearchTitleComponent,
  globalSearchTitleSelector,
} from 'core-app/core/global_search/title/global-search-title.component';
import {
  GlobalSearchTabsComponent,
  globalSearchTabsSelector,
} from 'core-app/core/global_search/tabs/global-search-tabs.component';
import {
  MembersAutocompleterComponent,
  membersAutocompleterSelector,
} from 'core-app/shared/components/autocompleter/members-autocompleter/members-autocompleter.component';
import {
  TriggerActionsEntryComponent,
  triggerActionsEntryComponentSelector,
} from 'core-app/shared/components/time_entries/edit/trigger-actions-entry.component';
import {
  BacklogsPageComponent,
  backlogsPageComponentSelector,
} from 'core-app/features/backlogs/backlogs-page/backlogs-page.component';
import {
  attributeValueMacro,
  AttributeValueMacroComponent,
} from 'core-app/shared/components/fields/macros/attribute-value-macro.component';
import {
  attributeLabelMacro,
  AttributeLabelMacroComponent,
} from 'core-app/shared/components/fields/macros/attribute-label-macro.component';
import {
  AttributeHelpTextComponent,
  attributeHelpTextSelector,
} from 'core-app/shared/components/attribute-help-texts/attribute-help-text.component';
import {
  quickInfoMacroSelector,
  WorkPackageQuickinfoMacroComponent,
} from 'core-app/shared/components/fields/macros/work-package-quickinfo-macro.component';
import {
  SlideToggleComponent,
  slideToggleSelector,
} from 'core-app/shared/components/slide-toggle/slide-toggle.component';
import { BackupComponent, backupSelector } from 'core-app/core/setup/globals/components/admin/backup.component';
import {
  EnterpriseBaseComponent,
  enterpriseBaseSelector,
} from 'core-app/features/enterprise/enterprise-base.component';
import {
  EEActiveSavedTrialComponent,
  enterpriseActiveSavedTrialSelector,
} from 'core-app/features/enterprise/enterprise-active-trial/ee-active-saved-trial.component';
import {
  EnterpriseBannerBootstrapComponent,
  enterpriseBannerSelector,
} from 'core-app/shared/components/enterprise-banner/enterprise-banner-bootstrap.component';
import {
  HomescreenNewFeaturesBlockComponent,
  homescreenNewFeaturesBlockSelector,
} from 'core-app/features/homescreen/blocks/new-features.component';
import { MainMenuToggleComponent, mainMenuToggleSelector } from 'core-app/core/main-menu/main-menu-toggle.component';
import {
  ConfirmFormSubmitController,
  confirmFormSubmitSelector,
} from 'core-app/shared/components/modals/confirm-form-submit/confirm-form-submit.directive';
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

export const globalDynamicComponents:OptionalBootstrapDefinition[] = [
  { selector: appBaseSelector, cls: ApplicationBaseComponent },
  { selector: attributeHelpTextSelector, cls: AttributeHelpTextComponent },
  { selector: wpEmbeddedTableMacroSelector, cls: EmbeddedTablesMacroComponent, embeddable: true },
  { selector: colorsAutocompleterSelector, cls: ColorsAutocompleterComponent },
  { selector: zenModeComponentSelector, cls: ZenModeButtonComponent },
  { selector: attachmentsSelector, cls: AttachmentsComponent, embeddable: true },
  { selector: usersAutocompleterSelector, cls: UserAutocompleterComponent },
  { selector: membersAutocompleterSelector, cls: MembersAutocompleterComponent },
  { selector: globalSearchTabsSelector, cls: GlobalSearchTabsComponent },
  { selector: globalSearchWorkPackagesSelector, cls: GlobalSearchWorkPackagesComponent },
  { selector: homescreenNewFeaturesBlockSelector, cls: HomescreenNewFeaturesBlockComponent },
  { selector: customDateActionAdminSelector, cls: CustomDateActionAdminComponent },
  { selector: boardsMenuSelector, cls: BoardsMenuComponent },
  { selector: globalSearchWorkPackagesSelectorEntry, cls: GlobalSearchWorkPackagesEntryComponent },
  { selector: notificationsContainerSelector, cls: NotificationsContainerComponent },
  { selector: adminTypeFormConfigurationSelector, cls: TypeFormConfigurationComponent },
  { selector: ckeditorAugmentedTextareaSelector, cls: CkeditorAugmentedTextareaComponent, embeddable: true },
  { selector: persistentToggleSelector, cls: PersistentToggleComponent },
  { selector: principalSelector, cls: OpPrincipalComponent },
  { selector: hideSectionLinkSelector, cls: HideSectionLinkComponent },
  { selector: showSectionDropdownSelector, cls: ShowSectionDropdownComponent },
  { selector: addSectionDropdownSelector, cls: AddSectionDropdownComponent },
  { selector: autocompleteSelectDecorationSelector, cls: AutocompleteSelectDecorationComponent },
  { selector: contentTabsSelector, cls: ContentTabsComponent },
  { selector: globalSearchTitleSelector, cls: GlobalSearchTitleComponent },
  { selector: copyToClipboardSelector, cls: CopyToClipboardDirective },
  { selector: confirmFormSubmitSelector, cls: ConfirmFormSubmitController },
  { selector: mainMenuResizerSelector, cls: MainMenuResizerComponent },
  { selector: mainMenuToggleSelector, cls: MainMenuToggleComponent },
  { selector: globalSearchSelector, cls: GlobalSearchInputComponent },
  { selector: collapsibleSectionAugmentSelector, cls: CollapsibleSectionComponent },
  { selector: enterpriseBannerSelector, cls: EnterpriseBannerBootstrapComponent },
  { selector: enterpriseBaseSelector, cls: EnterpriseBaseComponent },
  { selector: enterpriseActiveSavedTrialSelector, cls: EEActiveSavedTrialComponent },
  { selector: projectMenuAutocompleteSelector, cls: ProjectMenuAutocompleteComponent },
  { selector: remoteFieldUpdaterSelector, cls: RemoteFieldUpdaterComponent },
  { selector: wpOverviewGraphSelector, cls: WorkPackageOverviewGraphComponent },
  { selector: wpQuerySelectSelector, cls: WorkPackageQuerySelectDropdownComponent },
  { selector: triggerActionsEntryComponentSelector, cls: TriggerActionsEntryComponent, embeddable: true },
  { selector: backlogsPageComponentSelector, cls: BacklogsPageComponent },
  { selector: attributeValueMacro, cls: AttributeValueMacroComponent, embeddable: true },
  { selector: attributeLabelMacro, cls: AttributeLabelMacroComponent, embeddable: true },
  { selector: quickInfoMacroSelector, cls: WorkPackageQuickinfoMacroComponent, embeddable: true },
  { selector: editableQueryPropsSelector, cls: EditableQueryPropsComponent },
  { selector: slideToggleSelector, cls: SlideToggleComponent },
  { selector: backupSelector, cls: BackupComponent },
  { selector: opInAppNotificationBellSelector, cls: InAppNotificationBellComponent },
];
