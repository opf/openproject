import { Injectable } from '@angular/core';
import { EditFormComponent } from "core-app/modules/fields/edit/edit-form/edit-form.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

@Injectable({
  providedIn: 'root'
})
export class GlobalEditFormChangesTrackerService {
  private activeForms = new Map<EditFormComponent, boolean>();

  get thereAreFormsWithUnsavedChanges () {
    return Array.from(this.activeForms.keys()).some(form => {
      return !form.change.isEmpty();
    });
  }

  constructor(
    private i18nService:I18nService,
  ) {
    // Global beforeunload hook to show a data loss warn
    // when the user clicks on a link out of the Angular app
    window.addEventListener('beforeunload', (event) => {
      if (this.thereAreFormsWithUnsavedChanges) {
        event.preventDefault();
        event.returnValue = this.i18nService.t('js.work_packages.confirm_edit_cancel');
      }
    });
  }

  public addToActiveForms(form:EditFormComponent) {
    this.activeForms.set(form, true);
  }

  public removeFromActiveForms(form:EditFormComponent) {
    this.activeForms.delete(form);
  }
}
