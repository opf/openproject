import {
  Directive,
  OnDestroy,
  OnInit,
  TemplateRef,
} from "@angular/core";
import { SpotDropModalTeleportationService } from "./drop-modal-teleportation.service";

@Directive({
  selector: 'ng-template[spotDropModalTeleport]'
})
export class SpotDropModalTeleportDirective implements OnInit, OnDestroy {
  constructor(
    private teleportationService: SpotDropModalTeleportationService,
    private template: TemplateRef<any>,
  ) { }

  ngOnInit() {
    // Teleports the template to the new target portal
    setTimeout(() => {
      this.teleportationService.activate(this.template);
    });
  }

  ngOnDestroy() {
    // Clears the portal on destroy whenever the target is defined
    this.teleportationService.clear();
  }
}
