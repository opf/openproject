import { AfterViewInit, Directive, ElementRef, inject } from '@angular/core';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import Mousetrap from 'mousetrap';
import { computePosition, ComputePositionReturn, flip, shift } from '@floating-ui/dom';

@Directive({
  selector: '[opContextMenuTrigger]',
  standalone: false,
})
export class OpContextMenuTrigger extends OpContextMenuHandler implements AfterViewInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly opContextMenu:OPContextMenuService;

  protected element:HTMLElement;

  protected items:OpContextMenuItem[] = [];

  constructor() {
    const opContextMenu = inject(OPContextMenuService);

    super(opContextMenu);

    this.opContextMenu = opContextMenu;
  }

  ngAfterViewInit():void {
    this.element = this.elementRef.nativeElement;

    // Open by clicking the element
    this.element.addEventListener('click', (evt) => {
      evt.preventDefault();

      // When clicking the same trigger twice, close the element instead.
      if (this.opContextMenu.isActive(this)) {
        this.opContextMenu.close();
      } else {
        this.open(evt);
      }
    });

    // Open with keyboard combination as well
    Mousetrap(this.element).bind('shift+alt+f10', (evt:any) => {
      this.open(evt);
    });
  }

  public computePosition(floating:HTMLElement, openerEvent:Event):Promise<ComputePositionReturn> {
    return computePosition(this.element, floating, {
      placement: this.placement,
      middleware: [
        flip(),
        shift({ padding: 10 }),
      ],
    });
  }
}
