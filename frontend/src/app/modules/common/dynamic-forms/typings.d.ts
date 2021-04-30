import { FormlyFieldConfig, FormlyTemplateOptions } from "@ngx-formly/core";
import { FormGroup } from "@angular/forms";

export interface IOPDynamicFormSettings {
  fields:IOPFormlyFieldSettings[];
  model:IOPFormModel;
  form:FormGroup;
}

export interface IOPFormlyFieldSettings extends FormlyFieldConfig {
  key?:string;
  type?:OPInputType;
  templateOptions?:IOPFormlyTemplateOptions;
}

export interface IOPFormlyTemplateOptions extends FormlyTemplateOptions {
  isFieldGroup?:boolean;
  collapsibleFieldGroups?:boolean;
  collapsibleFieldGroupsCollapsed?:boolean;
}

type OPInputType = 'formattableInput'|'selectInput'|'textInput'|'integerInput'|
  'booleanInput'| 'dateInput' | 'formly-group';

export interface IOPDynamicInputTypeSettings {
  config:IOPFormlyFieldSettings,
  useForFields:OPFieldType[];
}



