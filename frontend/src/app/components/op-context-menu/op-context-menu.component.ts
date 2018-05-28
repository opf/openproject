import {Component, Inject} from "@angular/core";
import {OpContextMenuLocalsToken} from "core-app/angular4-transition-utils";
import {
  OpContextMenuEntry,
  OpContextMenuItem,
  OpContextMenuLocalsMap
} from "core-components/op-context-menu/op-context-menu.types";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";

@Component({
  templateUrl: './op-context-menu.html'
})
export class OPContextMenuComponent {
  public items:OpContextMenuItem[];
  public service:OPContextMenuService;

  constructor(@Inject(OpContextMenuLocalsToken) public locals:OpContextMenuLocalsMap) {
    this.items = this.locals.items;
    this.service = this.locals.service;
  }

  public handleClick(item:OpContextMenuEntry, $event:JQueryEventObject) {
    if (item.disabled) {
      return false;
    }

    if (item.onClick($event)) {
      this.locals.service.close();
      $event.preventDefault();
      $event.stopPropagation();
      return false;
    }

    return true;
  }
}
