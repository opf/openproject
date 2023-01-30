import {
  AfterViewChecked,
  Component,
} from '@angular/core';
import { SpotDropModalTeleportationService } from './drop-modal-teleportation.service';

export const spotDropModalPortalComponentSelector = 'spot-drop-modal-portal';

@Component({
  selector: spotDropModalPortalComponentSelector,
  template: '<ng-container *ngTemplateOutlet="template$ | async"></ng-container>',
})
export class SpotDropModalPortalComponent implements AfterViewChecked {
  constructor(
    readonly template$: SpotDropModalTeleportationService,
  ) { }

  ngAfterViewChecked(): void {
    this.template$.hasRendered$.next();
  }
}
