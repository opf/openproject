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

const PRISTINE_STATE_KEY = 'workflow-pristine-state';
const STATUS_STATE_KEY = 'workflow-status-state';
const CONFIRMATION_TRIGGER_ATTR = 'data-admin--workflow-checkbox-state-confirmation-trigger';

type CheckboxesState = Record<string, boolean>;

interface SavedState {
  formKey:string;
  checkboxes:CheckboxesState;
}

/**
 * Handles two things:
 * 1) Saving and restoring checked state of each checkbox when updating statuses,
 * since this refreshes the turbo frame and the checked state is not directly saved
 * to the DB
 *
 * 2) Marking the checkbox matrix as dirty when changes are made but not saved, and
 * triggering a confirmation dialog when navigating away:
 *   - Listens for clicks on any element with data-admin--workflow-checkbox-state-confirmation-trigger
 *     via document-level event delegation, so it works even after the EditComponent
 *     is replaced by a turbo-stream after the frame content loads.
 */
export default class WorkflowCheckboxStateController extends Controller<HTMLFormElement> {
  static targets = [ 'confirmationDialog', 'ignoreButton', 'saveButton' ];
  declare readonly confirmationDialogTarget:HTMLDialogElement;
  declare readonly ignoreButtonTarget:HTMLButtonElement;
  declare readonly saveButtonTarget:HTMLButtonElement;

  static values = {
    hasStatusChanges: Boolean,
    hasCheckboxChanges: Boolean,
    isDirty: Boolean
  };

  declare hasStatusChangesValue:boolean;
  declare hasCheckboxChangesValue:boolean;
  declare isDirtyValue:boolean;

  private initialCheckboxState:CheckboxesState = {};

  connect() {
    this.element.addEventListener('change', this.onCheckboxChange);
    this.element.addEventListener('submit', this.onFormSubmit);

    this.initialCheckboxState = this.popState(PRISTINE_STATE_KEY) ?? this.captureState();
    this.pushState(PRISTINE_STATE_KEY, this.initialCheckboxState);

    const statusCheckboxes = this.popState(STATUS_STATE_KEY);
    if (statusCheckboxes) {
      this.applyState(statusCheckboxes);
      // Recompute dirty flag: the restored state may differ from DB pristine.
      this.recomputeDirtyFlag();
    } else {
      // Apply indeterminate checkboxes only on fresh server rendered content.
      this.initIndeterminateCheckboxes();
    }

    // Use document-level delegation so this works even when the EditComponent
    // (which lives outside the turbo frame) is replaced by a turbo-stream after
    // the frame has already connected this controller.
    document.addEventListener('click', this.onConfirmationTriggerClick, true);
  }

  disconnect() {
    // Save checkbox state so it survives a component re-render (status add/remove
    // via turbo-stream or frame navigation). turbo:before-frame-render is not
    // fired for turbo-stream replacements, so disconnect() is the reliable hook.
    if (this.hasCheckboxChangesValue) {
      this.pushState(STATUS_STATE_KEY, this.captureState());
    }

    document.removeEventListener('click', this.onConfirmationTriggerClick, true);
    this.element.removeEventListener('submit', this.onFormSubmit);
    this.element.removeEventListener('change', this.onCheckboxChange);
  }

  private onFormSubmit = () => {
    this.popState(STATUS_STATE_KEY);
    this.popState(PRISTINE_STATE_KEY);
    this.initialCheckboxState = this.captureState();
    this.hasCheckboxChangesValue = false;
    this.hasStatusChangesValue = false;
  };

  private get formKey():string {
    const typeId = this.formValue('type_id');
    const roleIds = this.formValues('role_ids[]').sort().join(',');
    return `${typeId}-${roleIds}`;
  }

  private formValue(name:string):string {
    return this.element.querySelector<HTMLInputElement>(`input[name="${name}"]`)!.value;
  }

  private formValues(name:string):string[] {
    return Array.from(
      this.element.querySelectorAll<HTMLInputElement>(`input[name="${name}"]`),
    ).map((el) => el.value);
  }

  private pushState(key:string, state:CheckboxesState) {
    const savedState:SavedState = { formKey: this.formKey, checkboxes: state };
    sessionStorage.setItem(key, JSON.stringify(savedState));
  }

  private popState(key:string):CheckboxesState | null {
    const raw = sessionStorage.getItem(key);
    sessionStorage.removeItem(key);
    if (!raw) return null;

    const savedState = JSON.parse(raw) as SavedState;
    if (savedState.formKey !== this.formKey) return null;

    return savedState.checkboxes;
  }

  //
  // Hook "Unsaved changes" dialog to triggers to prevent data loss.
  // Asks for confirmation and proceed to requested event.
  //

  private onConfirmationTriggerClick = (event:Event) => {
    const target = (event.target as HTMLElement).closest<HTMLElement>(`[${CONFIRMATION_TRIGGER_ATTR}]`);
    if (!target) return;

    this.confirmWithDialog(event, target);
  };

  private confirmWithDialog = (event:Event, target:HTMLElement) => {
    if (!this.isDirtyValue) return;

    if (!target.dataset.confirmed) {
      event.preventDefault();
      event.stopImmediatePropagation();

      this.confirmThenResubmit(target, event);
    }
    else {
      // Reset confirmation status for next time
      delete target.dataset.confirmed;
      // Reset dirtiness status for next time
      this.hasCheckboxChangesValue = false;
      this.hasStatusChangesValue = false;
      // Let default behaviour behave…
    }
  };

  private openConfirmationDialog(onIgnore:() => void, onSave:() => void) {
    this.ignoreButtonTarget.addEventListener('click', onIgnore);
    this.saveButtonTarget.addEventListener('click', onSave);
    this.confirmationDialogTarget.addEventListener('close', () => {
      this.ignoreButtonTarget.removeEventListener('click', onIgnore);
      this.saveButtonTarget.removeEventListener('click', onSave);
    });
    this.confirmationDialogTarget.showModal();
  }

  private confirmThenResubmit = (target:HTMLElement, event:Event) => {
    this.openConfirmationDialog(
      this.onIgnoreChanges(target, event),
      this.onSaveChanges(target, event),
    );
  };

  private onIgnoreChanges = (originalTarget:HTMLElement, originalEvent:Event) => {
    return () => {
      const turboFrame = this.element.closest('turbo-frame') as HTMLElement;

      // Clear any saved status state so it is not re-applied after the reload.
      sessionStorage.removeItem(STATUS_STATE_KEY);

      const src = turboFrame.getAttribute('src') ?? '';
      const url = new URL(src);
      // Reload only with original params
      const params = new URLSearchParams();
      url.searchParams.getAll('role_ids[]').forEach((id) => params.append('role_ids[]', id));
      url.search = params.toString();
      turboFrame.setAttribute('src', url.toString());

      this.hasCheckboxChangesValue = false;
      this.hasStatusChangesValue = false;

      this.closeAndProceed(originalTarget, originalEvent);
    };
  };

  private onSaveChanges = (originalTarget:HTMLElement, originalEvent:Event) => {
    return () => {
      this.element.requestSubmit();

      this.closeAndProceed(originalTarget, originalEvent);
    };
  };

  private closeAndProceed = (originalTarget:HTMLElement, originalEvent:Event) => {
    this.confirmationDialogTarget.close();

    // Delay to allow the flash message from the form submission to appear.
    setTimeout(() => {
      if (originalEvent.type === 'click') {
        // originalTarget may be detached by the time this fires (e.g. the
        // EditComponent was replaced by a turbo-stream). Look for a live
        // element with the same href before falling back to the original.
        const liveTarget = document.querySelector<HTMLElement>(
          `[href="${originalTarget.getAttribute('href')}"][${CONFIRMATION_TRIGGER_ATTR}]`
        ) ?? originalTarget;
        liveTarget.dataset.confirmed = 'true';
        liveTarget.click();
      }
      else {
        originalTarget.dataset.confirmed = 'true';
        const forwardedEvent = new Event(originalEvent.type, { bubbles: true });
        originalTarget.dispatchEvent(forwardedEvent);
      }
    }, 1000);
  };

  //
  // Foundation for state management: save, apply and track dirtiness.
  //

  private hasCheckboxChangesValueChanged(hasChanges:boolean) {
    this.isDirtyValue = hasChanges || this.hasStatusChangesValue;
  }

  private hasStatusChangesValueChanged(hasChanges:boolean) {
    this.isDirtyValue = hasChanges || this.hasCheckboxChangesValue;
  }

  private isDirtyValueChanged(hasChanges:boolean) {
    window.OpenProject.pageState = hasChanges ? 'edited' : 'pristine';
  }

  private onCheckboxChange = (event:Event) => {
    this.removeIndeterminateMarker(event.target as HTMLInputElement);
    this.recomputeDirtyFlag();
  };

  private recomputeDirtyFlag() {
    const current = this.captureState();
    const hasChanges = Object.keys(current).some((key) => current[key] !== this.initialCheckboxState[key]);

    this.hasCheckboxChangesValue = hasChanges;
  }

  private removeIndeterminateMarker(checkbox:HTMLInputElement):void {
    const { oldStatus, newStatus } = checkbox.dataset;
    this.element.querySelector<HTMLInputElement>(
      `input[name="indeterminate_status[${oldStatus}][${newStatus}]"]`,
    )?.remove();
  }

  private captureState():Record<string, boolean> {
    const checkboxes:Record<string, boolean> = {};
    this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((cb) => {
      checkboxes[`${cb.dataset.oldStatus}:${cb.dataset.newStatus}:${cb.value}`] = cb.checked;
    });
    return checkboxes;
  }

  private applyState(checkboxes:Record<string, boolean>, defaultValue?:boolean):void {
    this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((cb) => {
      const key = `${cb.dataset.oldStatus}:${cb.dataset.newStatus}:${cb.value}`;

      cb.checked = checkboxes[key] ?? defaultValue ?? true;
    });
  }

  private initIndeterminateCheckboxes():void {
    this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"][data-indeterminate="true"]').forEach((cb) => {
      cb.indeterminate = true;
    });
  }

  //
  // Trigger navigation with dirty-state confirmation.
  //

  navigateTo(url:string) {
    if (this.isDirtyValue) {
      this.confirmThenNavigate(url);
    } else {
      this.frameNavigateTo(url);
    }
  }

  private confirmThenNavigate(url:string) {
    this.openConfirmationDialog(
      () => {
        this.hasCheckboxChangesValue = false;
        this.hasStatusChangesValue = false;
        this.confirmationDialogTarget.close();
        setTimeout(() => { this.frameNavigateTo(url); }, 0);
      },
      () => {
        this.element.requestSubmit();
        this.confirmationDialogTarget.close();
        // Delay to allow the flash message from the form submission to appear.
        setTimeout(() => { this.frameNavigateTo(url); }, 1000);
      },
    );
  }

  // This keeps the url in the /tabs/:tab/edit format consistently,
  // rather than doing a Turbo.visit which changes the format.
  // It also keeps history usable, similar to data-turbo-action="advance".
  private frameNavigateTo(url:string) {
    const turboFrame = this.element.closest('turbo-frame') as HTMLElement | null;
    if (turboFrame) {
      turboFrame.setAttribute('src', url);
      history.pushState({}, '', url);
    } else {
      Turbo.visit(url);
    }
  }
}
