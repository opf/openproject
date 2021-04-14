import { FormlyFieldConfig } from "@ngx-formly/core";
import { FormGroup } from "@angular/forms";

export interface IOPDynamicFormSettings {
  fields: IOPFormlyFieldConfig[];
  model: IOPFormModel;
  form: FormGroup;
}

export interface IOPFormlyFieldConfig extends FormlyFieldConfig {
  key?: string;
  type?: OPInputType;
}

type OPInputType = 'formattableInput' | 'selectInput' | 'textInput' | 'integerInput' |
  'booleanInput' | 'dateInput';

export interface IOPDynamicInputTypeConfig {
  config: IOPFormlyFieldConfig,
  useForFields: OPFieldType[];
}



