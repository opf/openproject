import { FormlyFieldConfig } from "@ngx-formly/core";
import { FormGroup } from "@angular/forms";

export interface IOPDynamicFormSettings {
  fields: IOPFormlyFieldSettings[];
  model: IOPFormModel;
  form: FormGroup;
}

export interface IOPFormlyFieldSettings extends FormlyFieldConfig {
  key?: string;
  type?: OPInputType;
}

type OPInputType = 'formattableInput' | 'selectInput' | 'textInput' | 'integerInput' |
  'booleanInput' | 'dateInput';

export interface IOPDynamicInputTypeSettings {
  config: IOPFormlyFieldSettings,
  useForFields: OPFieldType[];
}



