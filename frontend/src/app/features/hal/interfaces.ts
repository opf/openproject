export interface HalSourceLink { href?:string|null, title?:string }

export type HalSourceLinks = Record<string, HalSourceLink>;

export interface HalSource {
  [key:string]:unknown,
  _links:HalSourceLinks
}

export interface IOPFieldSchema {
  type:string;
  writable:boolean;
  allowedValues?:unknown;
  required?:boolean;
  hasDefault:boolean;
  name?:string;
  minLength?:number,
  maxLength?:number,
  attributeGroup?:string;
  location?:'_meta'|'_links'|undefined;
  options:Record<string, unknown>;
  _embedded?:{
    allowedValues?:IOPApiCall|IOPAllowedValue[];
  };
  _links?:{
    allowedValues?:IOPApiCall;
  };
}

interface IOPApiCall {
  href:string;
  method?:string;
}

interface IOPApiOption {
  href:string|null;
  title?:string;
}

interface IOPAllowedValue {
  id?:string;
  name:string;

  [key:string]:unknown;

  _links?:{
    self:HalSourceLink|IOPApiOption;
    [key:string]:HalSourceLink;
  };
}
