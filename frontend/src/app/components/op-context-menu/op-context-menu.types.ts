import {InjectionToken} from "@angular/core";

export const OpContextMenuLocalsToken = new InjectionToken<any>('CONTEXT_MENU_LOCALS');

export interface OpContextMenuLocalsMap {
  items:OpContextMenuItem[];
  contextMenuId?:string;
  [key:string]:any;
};

export interface OpContextMenuItem {
  disabled?:boolean;
  hidden?:boolean;
  icon?:string;
  href?:string;
  class?:string;
  ariaLabel?:string;
  linkText?:string;
  divider?:boolean;
  onClick?:($event:JQuery.TriggeredEvent) => boolean;
}
