import { Injectable } from '@angular/core';
import {EditFormComponent} from "core-app/modules/fields/edit/edit-form/edit-form.component";

@Injectable({
  providedIn: 'root'
})
export class GlobalEditFormChangesTrackerService {
  private formsWithModelChanges = new Map();

  public get hasModelChanges() {
    return this.formsWithModelChanges.size !== 0;
  }

  public addToFormsWithModelChanges(form:EditFormComponent) {
    this.formsWithModelChanges.set(form, true);

    window.OpenProject.editFormsContainModelChanges = true;
  }

  public removeFromFormsWithModelChanges(form:EditFormComponent) {
    this.formsWithModelChanges.delete(form);

    if (!this.hasModelChanges) {
      window.OpenProject.editFormsContainModelChanges = false;
    }
  }
}
