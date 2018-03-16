export interface OpContextMenuLocalsMap {
  items:OpContextMenuItem[];
  [key:string]:any;
};

export interface OpContextMenuEntry {
  disabled?:boolean;
  hidden?:boolean;
  icon?:string;
  href?:string;
  ariaLabel?:string;
  linkText:string;
  onClick:($event:JQueryEventObject) => boolean;
}

export interface OpContextMenuDivider {
  divider:true;
}

export type OpContextMenuItem = OpContextMenuEntry | OpContextMenuDivider;
