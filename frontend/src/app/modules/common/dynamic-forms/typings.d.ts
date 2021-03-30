import { FormlyFieldConfig } from "@ngx-formly/core";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";
import { FormGroup } from "@angular/forms";

export interface IDynamicForm {
  formlyFields: IOPFormlyFieldConfig[];
  model: { [key: string]: any };
  form: FormGroup;
}

export interface IOPForm {
  _type: "Form";
  _embedded: {
    payload: IFormModel;
    schema: IOPFormSchema;
    validationErrors: {
      [key: string]: unknown;
    };
  };
  _links: {
    self: IApiCall;
    validate: IApiCall;
    previewMarkup: IApiCall;
    commit: IApiCall;
  };
}

export interface IOPFormlyFieldConfig extends FormlyFieldConfig {
  key?: string;
}

export interface IFormModel {
  lockVersion?: number;
  [key: string]: string | number | Object;
  _links?: {
    [key: string]: HalSource; // Customfields has []?
  };
}

export interface IOPFormSchema {
  _type: "Schema";
  _dependencies: unknown[];
  _attributeGroups?: IAttributeGroup[];
  lockVersion: IFieldSchema;
  // TODO: type this properly
  [key: string]: IFieldSchema | any;
  _links: {
    baseSchema: {
      href: string;
    };
  };
}

export interface IFieldSchema {
  type: string;
  writable: boolean;
  allowedValues?: any;
  required?: boolean;
  hasDefault: boolean;
  name?: string;
  attributeGroup?: string;
  options: {
    [key: string]: unknown;
  };
  _embedded?: {
    allowedValues?: IApiCall | IAllowedValue[];
  };
  _links?: {
    allowedValues?: IApiCall;
  };
}

export interface IFieldSchemaWithKey extends IFieldSchema {
  key: string;
}

export interface IAttributeGroup {
  _type:
    | "WorkPackageFormAttributeGroup"
    | "WorkPackageFormChildrenQueryGroup"
    | "WorkPackageFormRelationQueryGroup"
    | unknown;
  name: string;
  attributes: string[];
}

// TODO: Type this properly
export interface IAllowedValue {
  id: string;
  name: string;
  [key: string]: unknown;
  _links: {
    self: HalSource;
    [key: string]: HalSource;
  };
}

export interface IApiCall {
  href: string;
  method?: string;
}

export interface IFieldTypeMap {
  [key:string]: FormlyFieldConfig;
}

export interface IFormError {
  errorIdentifier:string;
  message:string;
  _type:string;
  _embedded: IFormErrorDetails | IFormErrors;
}

export interface IFormErrorDetails {
  details: {
    attribute: string;
  }
}

export interface IFormErrors {
  errors: IFormError[];
}



