export interface SizeOption {
  key:string;
  label:string;
  description?:string;
  pick:() => void;
}

export interface SizeGroup {
  label:string;
  options:SizeOption[];
}

export interface OpenLink {
  href:string;
  label:string;
  ariaLabel:string;
}
