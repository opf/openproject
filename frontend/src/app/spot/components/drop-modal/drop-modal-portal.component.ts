import {
  AfterViewChecked,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
} from '@angular/core';
import { SpotDropModalTeleportationService } from './drop-modal-teleportation.service';

export const spotDropModalPortalComponentSelector = 'spot-drop-modal-portal';

@Component({
  selector: spotDropModalPortalComponentSelector,
  template: '<ng-container *ngTemplateOutlet="template$ | async"></ng-container>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotDropModalPortalComponent implements AfterViewChecked {

  constructor(
    readonly template$:SpotDropModalTeleportationService,
    readonly elementRef:ElementRef,
  ) { }

  ngAfterViewChecked(): void {
    this.template$.hasRendered$.next(!!this.elementRef.nativeElement.children.length);
  }
}
