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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { environment } from '../environments/environment';
import { OpApplicationController } from './controllers/op-application.controller';
import MainMenuController from './controllers/dynamic/menus/main.controller';
import OpDisableWhenCheckedController from './controllers/disable-when-checked.controller';
import OpDisableWhenValueSelectedController from './controllers/disable-when-value-selected.controller';
import PrintController from './controllers/print.controller';
import RefreshOnFormChangesController from './controllers/refresh-on-form-changes.controller';
import FormPreviewController from './controllers/form-preview.controller';
import AsyncDialogController from './controllers/async-dialog.controller';
import PollForChangesController from './controllers/poll-for-changes.controller';
import TableHighlightingController from './controllers/table-highlighting.controller';
import OpShowWhenCheckedController from './controllers/show-when-checked.controller';
import OpShowWhenValueSelectedController from './controllers/show-when-value-selected.controller';
import FlashController from './controllers/flash.controller';
import RequirePasswordConfirmationController from './controllers/require-password-confirmation.controller';
import PasswordRequirementsController from './controllers/password-requirements.controller';
import PreviewController from './controllers/dynamic/work-packages/date-picker/preview.controller';
import KeepScrollPositionController from './controllers/keep-scroll-position.controller';
import PatternInputController from './controllers/pattern-input.controller';
import HoverCardTriggerController from './controllers/hover-card-trigger.controller';
import ScrollIntoViewController from './controllers/scroll-into-view.controller';
import ReloadFrameOnEventController from './controllers/reload-frame-on-event.controller';
import CkeditorFocusController from './controllers/ckeditor-focus.controller';
import IndexController from './controllers/dynamic/work-packages/activities-tab/index.controller';
import AutoScrollingController from './controllers/dynamic/work-packages/activities-tab/auto-scrolling.controller';
import PollingController from './controllers/dynamic/work-packages/activities-tab/polling.controller';
import EditorController from './controllers/dynamic/work-packages/activities-tab/editor.controller';
import LazyPageController from './controllers/dynamic/work-packages/activities-tab/lazy-page.controller';
import EditablePageHeaderTitleController from './controllers/dynamic/editable-page-header-title.controller';
import WorkingHoursFormController from './controllers/dynamic/users/working-hours-form.controller';
import DailyRemindersController from './controllers/dynamic/my/daily-reminders.controller';
import HeaderProjectSelectController from './controllers/header-project-select.controller';
import ResourceTimelineController from './controllers/dynamic/resource-management/resource-timeline.controller';
import NonWorkingTimesController from './controllers/dynamic/users/non-working-times.controller';
import NonWorkingTimesFormController from './controllers/dynamic/users/non-working-times-form.controller';
import OpPasswordForceChangeController from './controllers/password-force-change.controller';

import AutoSubmit from '@stimulus-components/auto-submit';
import RevealController from '@stimulus-components/reveal';
import AutoThemeSwitcher from './controllers/auto-theme-switcher.controller';
import { OpenProjectStimulusApplication } from 'core-stimulus/openproject-stimulus-application';
import { Application } from '@hotwired/stimulus';
import { Application as LiveComponentApplication, LiveComponent } from '@camertron/live-component';
import { OpLiveComponentTransport } from './live-component-transport';
import PageHeaderLiveController from './controllers/dynamic/documents/page-header-live.controller';
import { BeforeunloadController } from './controllers/beforeunload.controller';
import ExternalLinksController from './controllers/external-links.controller';
import DisableWhenClickedController from 'core-stimulus/controllers/disable-when-clicked.controller';
import HighlightTargetElementController from 'core-stimulus/controllers/highlight-target-element.controller';
import SelectAutosizeController from 'core-stimulus/controllers/select-autosize.controller';
import OpZenModeController from 'core-stimulus/controllers/zen-mode.controller';
import CheckAllController from 'core-stimulus/controllers/check-all.controller';
import CheckableController from 'core-stimulus/controllers/checkable.controller';
import ExpandableTextController from 'core-stimulus/controllers/expandable-text.controller';
import { installElements } from '@openproject/stimulus-elements';

declare global {
  interface Window {
    Stimulus:Application;
  }
}

OpenProjectStimulusApplication.preregister('application', OpApplicationController);
OpenProjectStimulusApplication.preregister('async-dialog', AsyncDialogController);
OpenProjectStimulusApplication.preregister('disable-when-checked', OpDisableWhenCheckedController);
OpenProjectStimulusApplication.preregister('disable-when-clicked', DisableWhenClickedController);
OpenProjectStimulusApplication.preregister('disable-when-value-selected', OpDisableWhenValueSelectedController);
OpenProjectStimulusApplication.preregister('flash', FlashController);
OpenProjectStimulusApplication.preregister('menus--main', MainMenuController);
OpenProjectStimulusApplication.preregister('require-password-confirmation', RequirePasswordConfirmationController);
OpenProjectStimulusApplication.preregister('password-requirements', PasswordRequirementsController);
OpenProjectStimulusApplication.preregister('poll-for-changes', PollForChangesController);
OpenProjectStimulusApplication.preregister('print', PrintController);
OpenProjectStimulusApplication.preregister('refresh-on-form-changes', RefreshOnFormChangesController);
OpenProjectStimulusApplication.preregister('form-preview', FormPreviewController);
OpenProjectStimulusApplication.preregister('hover-card-trigger', HoverCardTriggerController);
OpenProjectStimulusApplication.preregister('show-when-checked', OpShowWhenCheckedController);
OpenProjectStimulusApplication.preregister('show-when-value-selected', OpShowWhenValueSelectedController);
OpenProjectStimulusApplication.preregister('table-highlighting', TableHighlightingController);
OpenProjectStimulusApplication.preregister('zen-mode', OpZenModeController);
OpenProjectStimulusApplication.preregister('work-packages--date-picker--preview', PreviewController);
OpenProjectStimulusApplication.preregister('keep-scroll-position', KeepScrollPositionController);
OpenProjectStimulusApplication.preregister('pattern-input', PatternInputController);
OpenProjectStimulusApplication.preregister('scroll-into-view', ScrollIntoViewController);
OpenProjectStimulusApplication.preregister('reload-frame-on-event', ReloadFrameOnEventController);
OpenProjectStimulusApplication.preregister('ckeditor-focus', CkeditorFocusController);
OpenProjectStimulusApplication.preregister('auto-submit', AutoSubmit);
OpenProjectStimulusApplication.preregister('reveal', RevealController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--index', IndexController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--auto-scrolling', AutoScrollingController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--polling', PollingController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--editor', EditorController);
OpenProjectStimulusApplication.preregister('work-packages--activities-tab--lazy-page', LazyPageController);
OpenProjectStimulusApplication.preregister('beforeunload', BeforeunloadController);
OpenProjectStimulusApplication.preregister('auto-theme-switcher', AutoThemeSwitcher);
OpenProjectStimulusApplication.preregister('external-links', ExternalLinksController);
OpenProjectStimulusApplication.preregister('highlight-target-element', HighlightTargetElementController);
OpenProjectStimulusApplication.preregister('select-autosize', SelectAutosizeController);
OpenProjectStimulusApplication.preregister('editable-page-header-title', EditablePageHeaderTitleController);
OpenProjectStimulusApplication.preregister('users--working-hours-form', WorkingHoursFormController);
OpenProjectStimulusApplication.preregister('my--daily-reminders', DailyRemindersController);
OpenProjectStimulusApplication.preregister('resource-management--resource-timeline', ResourceTimelineController);
OpenProjectStimulusApplication.preregister('users--non-working-times', NonWorkingTimesController);
OpenProjectStimulusApplication.preregister('users--non-working-times-form', NonWorkingTimesFormController);
OpenProjectStimulusApplication.preregister('password-force-change', OpPasswordForceChangeController);
OpenProjectStimulusApplication.preregister('check-all', CheckAllController);
OpenProjectStimulusApplication.preregister('header-project-select', HeaderProjectSelectController);
OpenProjectStimulusApplication.preregister('checkable', CheckableController);
OpenProjectStimulusApplication.preregister('expandable-text', ExpandableTextController);

// Manual LiveComponent registration. The library's @live decorator derives
// identifiers with String#replace('::', '-'), which only replaces the first
// occurrence and breaks two-level namespaces (v0.4.0 bug).
const PAGE_HEADER_LC_IDENTIFIER = 'documents-showeditview-pageheadercomponent';
if (!window.customElements.get(PAGE_HEADER_LC_IDENTIFIER)) {
  window.customElements.define(PAGE_HEADER_LC_IDENTIFIER, class extends LiveComponent {});
}
PageHeaderLiveController.identifier = PAGE_HEADER_LC_IDENTIFIER;
OpenProjectStimulusApplication.preregister(PAGE_HEADER_LC_IDENTIFIER, PageHeaderLiveController);

installElements();

const instance = OpenProjectStimulusApplication.start();
window.Stimulus = instance;

LiveComponentApplication.start(instance, new OpLiveComponentTransport('/live_components/render'));

instance.debug = !environment.production;
instance.handleError = (error, message, detail) => {
  console.warn(error, message, detail);
};
