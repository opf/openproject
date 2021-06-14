import { Component, Inject } from "@angular/core";
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap, OpContextMenuLocalsToken
} from "core-components/op-context-menu/op-context-menu.types";
import { OPContextMenuService } from "core-components/op-context-menu/op-context-menu.service";

@Component({
  templateUrl: './op-context-menu.html'
})
export class OPContextMenuComponent {
  public items:OpContextMenuItem[];
  public service:OPContextMenuService;

  constructor(@Inject(OpContextMenuLocalsToken) public locals:OpContextMenuLocalsMap) {
    this.items = this.locals.items.filter(item => !item?.hidden);
    this.service = this.locals.service;
  }

  public handleClick(item:OpContextMenuItem, $event:JQuery.TriggeredEvent) {
    if (item.disabled || item.divider) {
      return false;
    }

    if (item.onClick!($event)) {
      this.locals.service.close();
      $event.preventDefault();
      $event.stopPropagation();
      return false;
    }

    return true;
  }
}
