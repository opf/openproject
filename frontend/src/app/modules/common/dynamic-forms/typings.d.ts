import { FormlyFieldConfig } from "@ngx-formly/core";

export interface IOPDynamicFormSettings {
  fields:IOPFormlyFieldSettings[];
  model:IOPFormModel;
}

export interface IOPFormlyFieldSettings extends FormlyFieldConfig {
  key?:string;
  type?:OPInputType;
  property?:string;
}

type OPInputType = 'formattableInput'|'selectInput'|'textInput'|'integerInput'|
  'booleanInput'|'dateInput';

export interface IOPDynamicInputTypeSettings {
  config:IOPFormlyFieldSettings,
  useForFields:OPFieldType[];
}



