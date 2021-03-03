import { OptionalBootstrapDefinition } from "core-app/globals/dynamic-bootstrapper";
import { appBaseSelector, ApplicationBaseComponent } from "core-app/modules/router/base/application-base.component";
import {
  EmbeddedTablesMacroComponent,
  wpEmbeddedTableMacroSelector
} from "core-components/wp-table/embedded/embedded-tables-macro.component";
import {
  ColorsAutocompleter,
  colorsAutocompleterSelector
} from "core-app/modules/common/colors/colors-autocompleter.component";
import {
  ZenModeButtonComponent,
  zenModeComponentSelector
} from "core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component";
import { AttachmentsComponent, attachmentsSelector } from "core-app/modules/attachments/attachments.component";
import {
  UserAutocompleterComponent,
  usersAutocompleterSelector
} from "core-app/modules/autocompleter/user-autocompleter/user-autocompleter.component";
import {
  GlobalSearchWorkPackagesComponent,
  globalSearchWorkPackagesSelector
} from "core-app/modules/global_search/global-search-work-packages.component";
import {
  HomescreenNewFeaturesBlockComponent,
  homescreenNewFeaturesBlockSelector
} from "core-components/homescreen/blocks/new-features.component";
import {
  CustomDateActionAdminComponent,
  customDateActionAdminSelector
} from "core-components/wp-custom-actions/date-action/custom-date-action-admin.component";
import { BoardsMenuComponent, boardsMenuSelector } from "core-app/modules/boards/boards-sidebar/boards-menu.component";
import {
  GlobalSearchWorkPackagesEntryComponent,
  globalSearchWorkPackagesSelectorEntry
} from "core-app/modules/global_search/global-search-work-packages-entry.component";
import {
  NotificationsContainerComponent,
  notificationsContainerSelector
} from "core-app/modules/common/notifications/notifications-container.component";
import {
  adminTypeFormConfigurationSelector,
  TypeFormConfigurationComponent
} from "core-app/modules/admin/types/type-form-configuration.component";
import {
  CkeditorAugmentedTextareaComponent,
  ckeditorAugmentedTextareaSelector
} from "core-app/ckeditor/ckeditor-augmented-textarea.component";
import {
  PersistentToggleComponent,
  persistentToggleSelector
} from "core-app/modules/common/persistent-toggle/persistent-toggle.component";
import { UserAvatarComponent, userAvatarSelector } from "core-components/user/user-avatar/user-avatar.component";
import {
  HideSectionLinkComponent,
  hideSectionLinkSelector
} from "core-app/modules/common/hide-section/hide-section-link/hide-section-link.component";
import {
  ShowSectionDropdownComponent,
  showSectionDropdownSelector
} from "core-app/modules/common/hide-section/show-section-dropdown.component";
import {
  AddSectionDropdownComponent,
  addSectionDropdownSelector
} from "core-app/modules/common/hide-section/add-section-dropdown/add-section-dropdown.component";
import {
  AutocompleteSelectDecorationComponent,
  autocompleteSelectDecorationSelector
} from "core-app/modules/autocompleter/autocomplete-select-decoration/autocomplete-select-decoration.component";
import {
  ContentTabsComponent,
  contentTabsSelector
} from "core-app/modules/common/tabs/content-tabs/content-tabs.component";
import {
  CopyToClipboardDirective,
  copyToClipboardSelector
} from "core-app/modules/common/copy-to-clipboard/copy-to-clipboard.directive";
import {
  ConfirmFormSubmitController,
  confirmFormSubmitSelector
} from "core-components/modals/confirm-form-submit/confirm-form-submit.directive";
import { MainMenuResizerComponent, mainMenuResizerSelector } from "core-components/resizer/main-menu-resizer.component";
import {
  GlobalSearchInputComponent,
  globalSearchSelector
} from "core-app/modules/global_search/input/global-search-input.component";
import {
  collapsibleSectionAugmentSelector,
  CollapsibleSectionComponent
} from "core-app/modules/common/collapsible-section/collapsible-section.component";
import {
  EnterpriseBannerBootstrapComponent,
  enterpriseBannerSelector
} from "core-components/enterprise-banner/enterprise-banner-bootstrap.component";
import {
  ProjectMenuAutocompleteComponent,
  projectMenuAutocompleteSelector
} from "core-components/projects/project-menu-autocomplete/project-menu-autocomplete.component";
import {
  RemoteFieldUpdaterComponent,
  remoteFieldUpdaterSelector
} from "core-app/modules/common/remote-field-updater/remote-field-updater.component";
import {
  WorkPackageOverviewGraphComponent,
  wpOverviewGraphSelector
} from "core-app/modules/work-package-graphs/overview/wp-overview-graph.component";
import {
  WorkPackageQuerySelectDropdownComponent,
  wpQuerySelectSelector
} from "core-components/wp-query-select/wp-query-select-dropdown.component";
import {
  GlobalSearchTitleComponent,
  globalSearchTitleSelector
} from "core-app/modules/global_search/title/global-search-title.component";
import {
  GlobalSearchTabsComponent,
  globalSearchTabsSelector
} from "core-app/modules/global_search/tabs/global-search-tabs.component";
import { MainMenuToggleComponent, mainMenuToggleSelector } from "core-components/main-menu/main-menu-toggle.component";
import {
  MembersAutocompleterComponent,
  membersAutocompleterSelector
} from "core-app/modules/members/members-autocompleter.component";
import { EnterpriseBaseComponent, enterpriseBaseSelector } from "core-components/enterprise/enterprise-base.component";
import {
  EEActiveSavedTrialComponent,
  enterpriseActiveSavedTrialSelector
} from "core-components/enterprise/enterprise-active-trial/ee-active-saved-trial.component";
import {
  TriggerActionsEntryComponent,
  triggerActionsEntryComponentSelector
} from "core-app/modules/time_entries/edit/trigger-actions-entry.component";
import {
  BacklogsPageComponent,
  backlogsPageComponentSelector
} from "core-app/modules/backlogs/backlogs-page/backlogs-page.component";
import {
  attributeValueMacro,
  AttributeValueMacroComponent
} from "core-app/modules/fields/macros/attribute-value-macro.component";
import {
  attributeLabelMacro,
  AttributeLabelMacroComponent
} from "core-app/modules/fields/macros/attribute-label-macro.component";
import {
  AttributeHelpTextComponent,
  attributeHelpTextSelector
} from "core-app/modules/fields/help-texts/attribute-help-text.component";
import {
  quickInfoMacroSelector,
  WorkPackageQuickinfoMacroComponent
} from "core-app/modules/fields/macros/work-package-quickinfo-macro.component";
import {
  EditableQueryPropsComponent,
  editableQueryPropsSelector
} from "core-app/modules/admin/editable-query-props/editable-query-props.component";
import { SlideToggleComponent, slideToggleSelector } from "core-app/modules/common/slide-toggle/slide-toggle.component";

export const globalDynamicComponents:OptionalBootstrapDefinition[] = [
  { selector: appBaseSelector, cls: ApplicationBaseComponent },
  { selector: attributeHelpTextSelector, cls: AttributeHelpTextComponent },
  { selector: wpEmbeddedTableMacroSelector, cls: EmbeddedTablesMacroComponent, embeddable: true },
  { selector: colorsAutocompleterSelector, cls: ColorsAutocompleter },
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
  { selector: adminTypeFormConfigurationSelector, cls: TypeFormConfigurationComponent, },
  { selector: ckeditorAugmentedTextareaSelector, cls: CkeditorAugmentedTextareaComponent, embeddable: true },
  { selector: persistentToggleSelector, cls: PersistentToggleComponent },
  { selector: userAvatarSelector, cls: UserAvatarComponent },
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
  { selector: slideToggleSelector, cls: SlideToggleComponent }
];




