import {FormControl, ValidationErrors} from "@angular/forms";
import {FormlyFieldConfig} from "@ngx-formly/core";
import {DynamicFormService} from "core-app/modules/common/dynamic-forms/services/dynamic-form.service";

export const backendValidator = {
  name: 'backend-validator',
  validation: (control: FormControl, field: FormlyFieldConfig, service:DynamicFormService): ValidationErrors | null => {
    const errorMessage = service.errors?.[field.key as string];

    if (errorMessage) {
      const {[field.key as string]:currentError, ...restOfErrors} = service.errors;
      // Remove the error when this FormControl model value changes
      // TODO: this depends on the form updateOn: 'change', is this guaranteed?
      service.errors = {...restOfErrors};

      return {[field.key as string]: { message: errorMessage}}
    } else {
      return null;
    }
  }
};