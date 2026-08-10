export interface WorkPackage {
  id:number;
  displayId:string;
  subject:string;
  description?:{ raw?:string; html?:string } | null;
  status?:string | null;
  assignee?:string | null;
  href?:string | null;
  lockVersion?:number | null;
  _links?:{
    self:{ href:string };
    status:{ title:string; href:string } | null;
    assignee:{ title:string; href:string } | null;
    type:{ title:string; href:string } | null;
    parent?:{ title:string; href:string } | null;
    project?:{ title:string; href:string } | null;
  } | null;
}

export interface WorkPackageCollection {
  _embedded:{
    elements:WorkPackage[];
  };
}

export interface StatusCollection {
  _embedded?:{
    elements?:{
      id:string;
      name:string;
      isClosed:boolean;
      color:string;
      _links:{
        self:{ href:string };
      };
    }[];
  };
}

export interface TypeCollection {
  _embedded?:{
    elements?:{
      id:string;
      name:string;
      color:string;
      _links:{
        self:{ href:string };
      };
    }[];
  };
}

export interface OpenProjectResponse {
  _embedded?:{
    elements?:{
      id:string;
      name:string;
      _links?:{ self:{ href:string } };
    }[];
  };
}

export interface HalLink {
  href:string | null;
  title?:string;
  method?:string;
  templated?:boolean;
}

export interface HalResource {
  id?:number | string;
  name?:string;
  subject?:string;
  value?:string;
  _links?:{ self?:HalLink };
}

export interface HalCollection<T> {
  total?:number;
  count?:number;
  _embedded?:{ elements?:T[] };
}

export interface SchemaProperty {
  type:string;
  name:string;
  required:boolean;
  hasDefault:boolean;
  writable:boolean;
  location?:string;
  placeholder?:string | null;
  minLength?:number | null;
  maxLength?:number | null;
  options?:Record<string, unknown> | null;
  _embedded?:{ allowedValues?:HalResource[] };
  _links?:{ allowedValues?:HalLink | HalLink[] };
}

export type WorkPackageSchema = Record<string, unknown>;

export interface WorkPackagePayload {
  _links?:Record<string, HalLink | HalLink[]>;
  [key:string]:unknown;
}

export interface WorkPackageForm {
  _embedded?:{
    payload?:WorkPackagePayload;
    schema?:WorkPackageSchema;
    validationErrors?:Record<string, { message?:string }>;
  };
}

export interface OpenProjectApiErrorEntry {
  message?:string;
  /*  The attribute is camelized, as in the schema.  */
  _embedded?:{ details?:{ attribute?:string } };
}

export interface OpenProjectApiErrorBody extends OpenProjectApiErrorEntry {
  _embedded?:{ details?:{ attribute?:string }; errors?:OpenProjectApiErrorEntry[] };
}

export type OpColorMode = 'light' | 'dark';
