interface IOPFormSettings {
  _type?: "Form";
  _embedded: {
    payload: IOPFormModel;
    schema: IOPFormSchema;
    validationErrors?: IOPValidationErrors;
  };
  _links?: {
    self: IOPApiCall;
    validate: IOPApiCall;
    commit: IOPApiCall;
    previewMarkup?: IOPApiCall;
  };
}

interface IOPFormSchema {
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

interface IOPFormModel {
  [key: string]: string | number | Object | HalLinkSource | null | undefined;
  _links?: {
    [key: string]: IOPFieldModel | IOPFieldModel[] | null;
  };
}

interface IOPFieldSchema {
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

interface IOPFieldSchemaWithKey extends IOPFieldSchema {
  key: string;
}

interface IOPFieldModel extends Partial<HalSource>{
  name?: string;
}

type HalSource = {
  [key:string]:string|number|null|HalSourceLinks,
  _links:HalSourceLinks
};

interface IOPApiCall {
  href: string;
  method?: string;
}

interface IOPApiOption {
  href: string;
  title?: string;
}

interface IOPAttributeGroup {
  _type:
    | "WorkPackageFormAttributeGroup"
    | "WorkPackageFormChildrenQueryGroup"
    | "WorkPackageFormRelationQueryGroup"
    | unknown;
  name: string;
  attributes: string[];
}

interface IOPAllowedValue {
  id: string;
  name: string;
  [key: string]: unknown;
  _links: {
    self: HalSource | IOPApiOption;
    [key: string]: HalSource;
  };
}

type OPFieldType = 'String' | 'Integer' | 'Boolean' | 'Date' | 'DateTime' | 'Formattable' |
  'Priority' | 'Status' | 'Type' | 'User' | 'Version' | 'TimeEntriesActivity' | 'Category' |
  'CustomOption' | 'Project' | 'ProjectStatus' | 'Password';

interface IOPFormError {
  errorIdentifier:string;
  message:string;
  _type:string;
  _embedded: IOPFormErrorDetails;
}

interface IOPFormErrorResponse extends IOPFormError {
  _embedded: IOPFormErrorDetails | IOPFormErrors;
}

interface IOPFormErrorDetails {
  details: {
    attribute: string;
  }
}

interface IOPFormErrors {
  errors: IOPFormError[];
}

interface IOPValidationErrors {
  [key: string]: IOPFormError;
}




