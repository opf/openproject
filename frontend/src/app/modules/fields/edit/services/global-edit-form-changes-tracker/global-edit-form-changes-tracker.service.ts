import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class GlobalEditFormChangesTrackerService {
  private formsWithModelChanges = new Map();

  public get hasModelChanges() {
    return this.formsWithModelChanges.size !== 0;
  }

  public addToFormsWithModelChanges(form:any) {
    this.formsWithModelChanges.set(form, true);

    window.OpenProject.editFormsContainModelChanges = true;
  }

  public removeFromFormsWithModelChanges(form:any) {
    this.formsWithModelChanges.delete(form);

    if (!this.hasModelChanges) {
      window.OpenProject.editFormsContainModelChanges = false;
    }
  }
}
