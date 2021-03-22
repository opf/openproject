import { Injectable } from "@angular/core";
import { mergeFormModels } from "../utils/utils";
import { DynamicFormService } from "./dynamic-form.service";

@Injectable({ providedIn: "root" })
export class DynamicFormsHubService {
  readonly forms = new Map();
  private _unsavedChanges = new Map();

  constructor() {}

  registerForm(formService: DynamicFormService) {
    // Only one unsaved/new form reference is allowed
    const formId = formService.formId || "new";

    this.forms.set(formId, formService);
  }

  unregisterForm(formService: DynamicFormService) {
    const formId = formService.formId || "new";
    const formChanges = formService.formModelChanges;

    // TODO: We should save the changes only if the user has
    // not discarded them
    if (formChanges) {
      const mergeFormModelChanges = mergeFormModels(
        this._unsavedChanges.get(formId),
        formChanges
      );

      this._unsavedChanges.set(formId, mergeFormModelChanges);
    }

    this.forms.delete(formId);
  }

  // Keep a copy of the unsaved changes between reloads of the form
  // This is because changing the wp form to full view implies a
  // route change (the form is destroyed and rebuilt)
  getBackUpFormChanges(formId = "new") {
    return this._unsavedChanges.get(formId);
  }
}
