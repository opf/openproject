import { FormlyFieldConfig } from "@ngx-formly/core";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { FormGroup } from "@angular/forms";
import { HalLinkSource } from "core-app/modules/hal/hal-link/hal-link";

export interface IOPDynamicFormSettings {
  fields: IOPFormlyFieldConfig[];
  model: IOPFormModel;
  form: FormGroup;
}

export interface IOPFormSettings {
  _type?: "Form";
  _embedded: {
    payload: IOPFormModel;
    schema: IOPFormSchema;
    validationErrors?: {
      [key: string]: unknown;
    };
  };
  _links?: {
    self: IOPApiCall;
    validate: IOPApiCall;
    commit: IOPApiCall;
    previewMarkup?: IOPApiCall;
  };
}

export interface IOPFormlyFieldConfig extends FormlyFieldConfig {
  key?: string;
  type?: OPInputType;
}

type OPFieldType = 'String' | 'Integer' | 'Boolean' | 'Date' | 'DateTime' | 'Formattable' |
  'Priority' | 'Status' | 'Type' | 'User' | 'Version' | 'TimeEntriesActivity' | 'Category' |
  'CustomOption' | 'Project' | 'ProjectStatus';

type OPInputType = 'formattableInput' | 'selectInput' | 'textInput' | 'integerInput' |
  'booleanInput' | 'dateInput';

export interface IOPFormModel {
  [key: string]: string | number | Object | HalLinkSource | null | undefined;
  _links?: {
    [key: string]: IOPFieldModel | IOPFieldModel[] | null;
  };
}

export interface IOPFieldModel extends Partial<HalSource>{
  name?: string;
}

export interface IOPFormSchema {
  _type?: "Schema";
  _dependencies?: unknown[];
  _attributeGroups?: IOPAttributeGroup[];
  lockVersion?: IOPFieldSchema;
  [fieldKey: string]: IOPFieldSchema | any;
  _links?: {
    baseSchema?: {
      href: string;
    };
  };
}

export interface IOPFieldSchema {
  type: OPFieldType;
  writable: boolean;
  allowedValues?: any;
  required?: boolean;
  hasDefault: boolean;
  name?: string;
  attributeGroup?: string;
  options: {
    [key: string]: any;
  };
  _embedded?: {
    allowedValues?: IOPApiCall | IOPAllowedValue[];
  };
  _links?: {
    allowedValues?: IOPApiCall;
  };
}

export interface IOPFieldSchemaWithKey extends IOPFieldSchema {
  key: string;
}

export interface IOPAttributeGroup {
  _type:
    | "WorkPackageFormAttributeGroup"
    | "WorkPackageFormChildrenQueryGroup"
    | "WorkPackageFormRelationQueryGroup"
    | unknown;
  name: string;
  attributes: string[];
}

export interface IOPAllowedValue {
  id: string;
  name: string;
  [key: string]: unknown;
  _links: {
    self: HalSource;
    [key: string]: HalSource;
  };
}

export interface IOPApiCall {
  href: string;
  method?: string;
}

export interface IOPFormError {
  errorIdentifier:string;
  message:string;
  _type:string;
  _embedded: IOPFormErrorDetails | IOPFormErrors;
}

export interface IOPFormErrorDetails {
  details: {
    attribute: string;
  }
}

export interface IOPFormErrors {
  errors: IOPFormError[];
}

export interface IOPDynamicInputTypeConfig {
  config: IOPFormlyFieldConfig,
  useForFields: OPFieldType[];
}



