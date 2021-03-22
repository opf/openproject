import { FormlyFieldConfig } from "@ngx-formly/core";

export interface IDynamicForm {
  fields: IOPFormlyFieldConfig[];
  model: { [key: string]: any };
}

export interface IOPForm {
  _type: "Form";
  _embedded: {
    payload: IFormPayload;
    schema: IFormSchema;
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

export interface IFormPayload {
  lockVersion?: number;
  [key: string]: string | number | Object;
  _links?: {
    [key: string]: IResource; // Customfields has []?
  };
}

export interface IFormSchema {
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

export interface IResource {
  href: string;
  title?: string;
}

// TODO: Type this properly
export interface IAllowedValue {
  id: string;
  name: string;
  [key: string]: unknown;
  _links: {
    self: IResource;
    [key: string]: IResource;
  };
}

export interface IApiCall {
  href: string;
  method?: string;
}

export interface IFormModelChanges {
  [key: string]: unknown;
  _links?: {
    [key: string]: IResource;
  };
}

export interface IFieldTypeMap {
  [key:string]: FormlyFieldConfig;
}
