/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import MatchPreviewDialogController, { MatchPreviewDialogSubmittedEvent } from './match-preview-dialog.controller';

export default class GroupSyncFormController extends Controller {
  static targets = [
    'inputsWrapper',
    'enabledCheckbox',
    'regexpInput',
  ];

  static outlets = ['openid-connect--match-preview-dialog'];

  declare readonly inputsWrapperTarget:HTMLDivElement;
  declare readonly enabledCheckboxTarget:HTMLInputElement;
  declare readonly regexpInputTarget:HTMLInputElement;
  declare readonly openidConnectMatchPreviewDialogOutlet:MatchPreviewDialogController;

  connect() {
    this.updateFormInputs();

    this.regexpInputTarget.addEventListener(
      'input',
      () => { this.openidConnectMatchPreviewDialogOutlet.updateRegexpValue(this.regexpInputTarget.value); }
    );
  }

  openidConnectMatchPreviewDialogOutletConnected() {
    this.openidConnectMatchPreviewDialogOutlet.updateRegexpValue(this.regexpInputTarget.value);
  }

  updateFormInputs() {
    if (this.enabledCheckboxTarget.checked) {
      this.showGroupSyncInputs();
    } else {
      this.hideGroupSyncInputs();
    }
  }

  previewSubmitted({ detail: { regularExpressions } }:MatchPreviewDialogSubmittedEvent) {
    this.regexpInputTarget.value = regularExpressions;
  }

  showGroupSyncInputs() {
    this.inputsWrapperTarget.classList.remove('d-none');
  }

  hideGroupSyncInputs() {
    this.inputsWrapperTarget.classList.add('d-none');
  }
}
