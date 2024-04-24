import { InjectionToken } from '@angular/core';

export const OpContextMenuLocalsToken = new InjectionToken<any>('CONTEXT_MENU_LOCALS');

export interface OpContextMenuItem {
  disabled?:boolean;
  hidden?:boolean;
  icon?:string;
  href?:string;
  class?:string;
  ariaLabel?:string;
  linkText?:string;
  title?:string;
  divider?:boolean;
  onClick?:($event:JQuery.TriggeredEvent|MouseEvent) => boolean;
}

export interface OpContextMenuLocalsMap {
  items:OpContextMenuItem[];
  showAnchorRight?:boolean;
  contextMenuId?:string;
  label?:string;
  /* eslint-disable @typescript-eslint/no-explicit-any */
  [key:string]:any;
}
