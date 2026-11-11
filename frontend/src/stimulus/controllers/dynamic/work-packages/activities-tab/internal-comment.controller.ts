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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { renderStreamMessage } from '@hotwired/turbo';
import type EditorController from './editor.controller';
import BaseController from './base.controller';

export default class InternalCommentController extends BaseController {
  static outlets = ['work-packages--activities-tab--editor'];
  declare readonly workPackagesActivitiesTabEditorOutlet:EditorController;
  private get editorOutlet() { return this.workPackagesActivitiesTabEditorOutlet; }

  static targets = ['confirmationDialog', 'modeMenu', 'formContainer', 'learnMoreLink'];
  declare readonly confirmationDialogTarget:HTMLDialogElement;
  declare readonly modeMenuTarget:HTMLElement;
  declare readonly formContainerTarget:HTMLElement;
  declare readonly learnMoreLinkTarget:HTMLAnchorElement;
  declare hasModeMenuTarget:boolean;
  declare hasLearnMoreLinkTarget:boolean;

  static classes = ['hidden'];
  declare readonly hiddenClass:string;

  static values = {
    mode: { type: String, default: 'public' },
  };

  declare modeValue:string;

  connect():void {
    super.connect();
    this.restoreMode();
  }

  disconnect():void {
    super.disconnect();
    this.rescueMode();
  }

  onSubmitEnd(_event:CustomEvent):void {
    const defaultMode = this.modeItems[0];
    if (defaultMode) this.selectMode(defaultMode);
  }

  onModeSelected():void {
    const item = this.selectedModeItem;
    if (!item) return;

    this.applyMode(item);
    this.persistMode(this.modeValue);

    if (this.isInternal(item)) {
      void this.sanitizeInternalMentions();
    }
  }

  restrictToInternal():void {
    const internalItem = this.modeItems.find((item) => this.isInternal(item));
    if (internalItem) this.selectMode(internalItem);
  }

  async modeValueChanged(currentValue:string, previousValue:string):Promise<void> {
    if (currentValue === previousValue) return;

    const previousItem = this.modeItem(previousValue);
    const currentItem = this.modeItem(currentValue);
    if (!previousItem || !currentItem) return;
    if (!this.isInternal(previousItem) || this.isInternal(currentItem)) return;

    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: 'none' });
      if (editorData.length === 0) return;

      const confirmed = await this.askForConfirmation();
      if (!confirmed) this.selectMode(previousItem);

      this.editorOutlet.focusEditor();
    }
  }

  private get modeItems():HTMLElement[] {
    if (!this.hasModeMenuTarget) return [];

    return Array.from(this.modeMenuTarget.querySelectorAll<HTMLElement>('[role="menuitemradio"]'));
  }

  private get selectedModeItem():HTMLElement|undefined {
    return this.modeItems.find((item) => item.getAttribute('aria-checked') === 'true');
  }

  private modeItem(mode:string):HTMLElement|undefined {
    return this.modeItems.find((item) => item.dataset.value === mode);
  }

  private isInternal(item:HTMLElement):boolean {
    return item.dataset.internal === 'true';
  }

  // The menu keeps the checked item, its label and the form input in sync when an item is clicked.
  private selectMode(item:HTMLElement):void {
    if (item === this.selectedModeItem) {
      this.applyMode(item);
    } else {
      item.click();
    }
  }

  private applyMode(item:HTMLElement):void {
    this.modeItems.forEach(({ dataset: { highlightClass } }) => {
      if (highlightClass) this.formContainerTarget.classList.remove(highlightClass);
    });
    if (item.dataset.highlightClass) this.formContainerTarget.classList.add(item.dataset.highlightClass);

    this.showModeIcon(item);
    this.toggleLearnMoreLink(this.isInternal(item));
    this.modeValue = item.dataset.value ?? this.modeValue;
  }

  private showModeIcon(item:HTMLElement):void {
    const icon = item.querySelector('.ActionListItem-visual--leading svg');
    const buttonVisual = this.modeMenuTarget.querySelector('.Button-leadingVisual');

    if (icon && buttonVisual) buttonVisual.replaceChildren(icon.cloneNode(true));
  }

  private toggleLearnMoreLink(isInternal:boolean):void {
    if (!this.hasLearnMoreLinkTarget) return;
    if (this.isMobile()) return; // hidden on mobile

    this.learnMoreLinkTarget.classList.toggle(this.hiddenClass, !isInternal);
  }

  private async sanitizeInternalMentions():Promise<void> {
    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: 'none' });
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

  private persistMode(mode:string):void {
    try {
      localStorage.setItem(this.storageKey, mode);
    } catch (error) {
      window.ErrorReporter.captureException(error as Error);
    }
  }

  private rescueMode():void {
    if (!this.hasModeMenuTarget) return;

    this.persistMode(this.modeValue);
  }

  private restoreMode():void {
    if (!this.hasModeMenuTarget) return;

    try {
      const storedMode = localStorage.getItem(this.storageKey);
      if (storedMode !== null) {
        const item = this.modeItem(storedMode);
        if (item) this.selectMode(item);
        // Remove the stored mode after restoration to ensure it is only persisted
        // temporarily (e.g., across a single navigation or reload).
        // This prevents a stale mode from being applied unintentionally in future sessions.
        localStorage.removeItem(this.storageKey);
      }
    } catch (error) {
      window.ErrorReporter.captureException(error as Error);
    }
  }

  private get ckEditorInstance() {
    return this.editorOutlet.ckEditorInstance;
  }

  private get storageKey():string {
    return `work-package-${this.workPackageId}-comment-mode`;
  }

  private get workPackageId():string {
    return String(this.indexOutlet.workPackageIdValue);
  }
}
