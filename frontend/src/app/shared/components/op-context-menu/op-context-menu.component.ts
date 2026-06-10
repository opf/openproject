import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import {
  OpContextMenuItem,
  OpContextMenuLocalsMap,
  OpContextMenuLocalsToken,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';

@Component({
  templateUrl: './op-context-menu.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class OPContextMenuComponent {
  locals = inject<OpContextMenuLocalsMap>(OpContextMenuLocalsToken);

  public items:OpContextMenuItem[];

  public service:OPContextMenuService;

  constructor() {
    this.items = this.locals.items.filter((item) => !item?.hidden);
    this.service = this.locals.service;
  }

  public handleClick(item:OpContextMenuItem, event:MouseEvent) {
    if (item.disabled || item.divider) {
      return false;
    }

    if (item.onClick!(event)) {
      this.locals.service.close();
      event.preventDefault();
      event.stopPropagation();
      return false;
    }

    return true;
  }
}
