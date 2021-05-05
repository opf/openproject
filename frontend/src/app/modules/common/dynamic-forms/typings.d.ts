import { FormlyFieldConfig, FormlyTemplateOptions } from "@ngx-formly/core";
import { FormGroup } from "@angular/forms";

export interface IOPDynamicFormSettings {
  fields:IOPFormlyFieldSettings[];
  model:IOPFormModel;
}

export interface IOPFormlyFieldSettings extends FormlyFieldConfig {
  key?:string;
  type?:OPInputType;
  templateOptions?:IOPFormlyTemplateOptions;
}

export interface IOPFormlyTemplateOptions extends FormlyTemplateOptions {
  property?: string;
  label?: string;
  hasDefault?: boolean;
  isFieldGroup?:boolean;
  collapsibleFieldGroups?:boolean;
  collapsibleFieldGroupsCollapsed?:boolean;
  helpTextAttributeScope?:string;
}

type OPInputType = 'formattableInput'|'selectInput'|'textInput'|'integerInput'|
  'booleanInput'| 'dateInput' | 'formly-group';

export interface IOPDynamicInputTypeSettings {
  config:IOPFormlyFieldSettings,
  useForFields:OPFieldType[];
}



