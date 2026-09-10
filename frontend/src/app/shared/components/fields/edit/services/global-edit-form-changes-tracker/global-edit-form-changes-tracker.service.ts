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

  /**
   * Broader than thereAreFormsWithUnsavedChanges: true whenever a field is active
   * (form.editing), even if no value has actually been changed yet. Matches the
   * uiRouter $transitions.onBefore hook's condition that used to guard split-view
   * switches - merely activating a field (e.g. opening a dropdown) is enough to warn
   * on navigating away, unlike the stricter check used for the native beforeunload
   * prompt.
   */
  get thereAreFormsBeingEdited() {
    return Array
      .from(this.activeForms.keys())
      .some((form) => form.editing && !form.change.inFlight);
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

    // Block Turbo restoration renders that would clobber Angular's DOM while an
    // edit form is active. For restoration visits visitApproved is false, so the
    // guard fires. This is also the only place we can warn about unsaved changes
    // for a back/forward navigation: turbo:before-visit (used by
    // beforeunload.controller.ts) is never dispatched for popstate-driven
    // restorations - the browser has already moved through history by the time
    // popstate fires, so Turbo skips straight to starting the visit.
    document.addEventListener('turbo:before-render', (event) => {
      if (this.visitApproved || !this.thereAreFormsWithUnsavedChanges) {
        return;
      }

      if (window.confirm(this.i18nService.t<string>('js.work_packages.confirm_edit_cancel'))) {
        return;
      }

      event.preventDefault();
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
