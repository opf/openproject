import { Injectable, inject } from '@angular/core';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Injectable({
  providedIn: 'root',
})
export class GlobalEditFormChangesTrackerService {
  private i18nService = inject(I18nService);

  private activeForms = new Map<EditFormComponent, boolean>();
  private abortController = new AbortController();
  private visitApproved = false;

  get thereAreFormsWithUnsavedChanges() {
    return Array
      .from(this.activeForms.keys())
      .some((form) => (
        form.editing
        && !form.change.inFlight
        && (isNewResource(form.resource) || !form.change.isEmpty())
      ));
  }

  constructor() {
    const { signal } = this.abortController;

    window.OpenProject.editFormsContainUnsavedChanges = () => this.thereAreFormsWithUnsavedChanges;

    // turbo:visit fires after a visit starts (canceled visits never
    // reach it) and carries the visit action.  Restoration visits
    // have action "restore"; link clicks have "advance"/"replace".
    document.addEventListener('turbo:visit', (event) => {
      const { action } = (event as CustomEvent<{ action:string }>).detail;
      this.visitApproved = action !== 'restore';
    }, { signal });

    // Block Turbo restoration renders that would clobber Angular's
    // DOM while an edit form is active.  For restoration visits
    // visitApproved is false, so the guard fires.
    document.addEventListener('turbo:before-render', (event) => {
      if (!this.visitApproved && this.thereAreFormsWithUnsavedChanges) {
        event.preventDefault();
      }
    }, { signal });

    // Show a data loss warning when the user closes the tab or
    // navigates away from the Angular app entirely.
    window.addEventListener('beforeunload', (event) => {
      if (!window.OpenProject.pageWasSubmitted && this.thereAreFormsWithUnsavedChanges) {
        const message = this.i18nService.t<string>('js.work_packages.confirm_edit_cancel');

        event.preventDefault();
        event.returnValue = message;
      }
    }, { signal });
  }

  public addToActiveForms(form:EditFormComponent) {
    this.activeForms.set(form, true);
  }

  public removeFromActiveForms(form:EditFormComponent) {
    this.activeForms.delete(form);
  }
}
