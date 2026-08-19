/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import { renderStreamMessage } from '@hotwired/turbo';
import type EditorController from './editor.controller';
import BaseController from './base.controller';

export default class InternalCommentController extends BaseController {
  static outlets = ['work-packages--activities-tab--editor'];
  declare readonly workPackagesActivitiesTabEditorOutlet:EditorController;
  private get editorOutlet() { return this.workPackagesActivitiesTabEditorOutlet; }

  static targets = ['confirmationDialog', 'internalCheckbox', 'formContainer', 'learnMoreLink'];
  declare readonly confirmationDialogTarget:HTMLDialogElement;
  declare readonly internalCheckboxTarget:HTMLInputElement;
  declare readonly formContainerTarget:HTMLElement;
  declare readonly learnMoreLinkTarget:HTMLAnchorElement;
  declare hasInternalCheckboxTarget:boolean;

  static classes = ['highlight', 'hidden'];
  declare readonly highlightClass:string;
  declare readonly hiddenClass:string;

  static values = {
    isInternal: { type: Boolean, default: false },
  };

  declare isInternalValue:boolean;

  connect():void {
    super.connect();
    this.restoreInternalState();
  }

  disconnect():void {
    super.disconnect();
    this.rescueInternalState();
  }

  onSubmitEnd(_event:CustomEvent):void {
    this.updateInternalState({ persist: false });
  }

  updateInternalState({ persist = true } = {}):void {
    if (!this.hasInternalCheckboxTarget) return;

    const isChecked = this.internalCheckboxTarget.checked;

    if (persist) {
      this.setInternalStateWithPersistence(isChecked);
    } else {
      this.setInternalStateWithoutPersistence(isChecked);
    }

    if (isChecked) {
      void this.sanitizeInternalMentions();
    }
  }

  async isInternalValueChanged(currentValue:boolean, previousValue:boolean):Promise<void> {
    if (currentValue === previousValue) return;

    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: false });
      if (editorData.length === 0) return;

      if (!currentValue && previousValue) {
        const confirmed = await this.askForConfirmation();

        if (confirmed) {
          this.editorOutlet.focusEditor();
        } else {
          this.internalCheckboxTarget.checked = true;
          this.setInternalStateWithPersistence(this.internalCheckboxTarget.checked);
          this.editorOutlet.focusEditor();
        }
      }
    }
  }

  private setInternalStateWithPersistence(isChecked:boolean):void {
    this.setInternalStateWithoutPersistence(isChecked);
    this.persistInternalState(isChecked);
  }

  private toggleLearnMoreLink(isChecked:boolean):void {
    if (this.isMobile()) return; // hidden on mobile

    this.learnMoreLinkTarget.classList.toggle(this.hiddenClass, !isChecked);
  }

  private async sanitizeInternalMentions():Promise<void> {
    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: false });
      if (editorData.length === 0) return;

      const sanitizePath = `/work_packages/${this.workPackageId}/activities/sanitize_internal_mentions`;

      try {
        const response = await fetch(sanitizePath, {
          method: 'POST',
          body: JSON.stringify({ journal: { notes: editorData } }),
          headers: {
            'X-CSRF-Token': this.csrfToken,
            'Content-Type': 'application/json',
          },
        });

        const sanitizedNotesResponse = await response.text();

        if (response.ok) {
          this.ckEditorInstance.setData(sanitizedNotesResponse);
        } else {
          renderStreamMessage(sanitizedNotesResponse);
          throw new Error(`Failed to sanitize internal mentions. Response status: ${response.status}`);
        }
      } catch (error) {
        console.error(error);
      }
    }
  }

  private askForConfirmation():Promise<boolean> {
    this.confirmationDialogTarget.returnValue = ''; // Reset the return value on every confirmation dialog
    this.confirmationDialogTarget.showModal();

    return new Promise((resolve) => {
      const confirmButton = this.confirmationDialogTarget.querySelector('[data-submit-dialog-id]');
      confirmButton?.addEventListener('click', () => {
        this.confirmationDialogTarget.returnValue = 'confirm';
      }, { once: true });

      this.confirmationDialogTarget.addEventListener('close', () => {
        resolve(this.confirmationDialogTarget.returnValue === 'confirm');
      }, { once: true });
    });
  }

  private persistInternalState(isChecked:boolean):void {
    try {
      localStorage.setItem(this.storageKey, JSON.stringify(isChecked));
    } catch (error) {
      window.ErrorReporter.captureException(error as Error);
    }
  }

  private rescueInternalState():void {
    if (!this.hasInternalCheckboxTarget) return;

    this.persistInternalState(this.internalCheckboxTarget.checked);
  }

  private restoreInternalState():void {
    if (!this.hasInternalCheckboxTarget) return;

    try {
      const storedState = localStorage.getItem(this.storageKey);
      if (storedState !== null) {
        const isChecked = JSON.parse(storedState) as boolean;
        this.internalCheckboxTarget.checked = isChecked;
        this.setInternalStateWithoutPersistence(isChecked);
        // Remove the stored state after restoration to ensure the internal comment state
        // is only persisted temporarily (e.g., across a single navigation or reload).
        // This prevents stale state from being applied unintentionally in future sessions.
        localStorage.removeItem(this.storageKey);
      }
    } catch (error) {
      window.ErrorReporter.captureException(error as Error);
    }
  }

  private setInternalStateWithoutPersistence(isChecked:boolean):void {
    this.formContainerTarget.classList.toggle(this.highlightClass, isChecked);
    this.toggleLearnMoreLink(isChecked);
    this.isInternalValue = isChecked;
  }

  private get ckEditorInstance() {
    return this.editorOutlet.ckEditorInstance;
  }

  private get storageKey():string {
    return `work-package-${this.workPackageId}-internal-comment-state`;
  }

  private get workPackageId():string {
    return String(this.indexOutlet.workPackageIdValue);
  }
}
