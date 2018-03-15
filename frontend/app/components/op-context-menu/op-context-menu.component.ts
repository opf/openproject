import {Component, Inject} from "@angular/core";
import {
  OpContextMenuLocalsMap,
  OpContextMenuLocalsToken, OPContextMenuService
} from "core-components/op-context-menu/op-context-menu.service";

export interface OpContextMenuEntry {
  disabled:boolean;
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


@Component({
  template: require('!!raw-loader!./op-context-menu.html')
})
export class OPContextMenuComponent {
  public items:OpContextMenuItem[];

  constructor(@Inject(OpContextMenuLocalsToken) public locals:OpContextMenuLocalsMap,
              readonly opContextMenuService:OPContextMenuService) {
    this.items = this.locals.items;
  }

  public handleClick(item:OpContextMenuEntry, $event:JQueryEventObject) {
    if (item.disabled) {
      return false;
    }

    if (item.onClick($event)) {
      this.opContextMenuService.close();
      return false;
    }

    return true;
  }
}
