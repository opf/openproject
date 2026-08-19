export interface IHalOptionalTitledLink {
  href:string;
  title?:string;
}

export interface IHalResourceLink {
  href:string;
  title:string;
}

export interface IHalResourceLinks {
  self:IHalResourceLink;
}

export interface IHalMethodResourceLink extends IHalResourceLink {
  method:string;
}

export type FormattableFormat = 'markdown'|'custom';

export interface IFormattable {
  format:FormattableFormat;
  raw:string;
  html:string;
}
