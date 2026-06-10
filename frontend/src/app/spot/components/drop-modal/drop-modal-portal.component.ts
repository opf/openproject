import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, HostBinding, OnInit, inject } from '@angular/core';
import { SpotDropModalTeleportationService, TeleportInstance } from './drop-modal-teleportation.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  selector: 'opce-spot-drop-modal-portal',
  template: '<ng-container *ngTemplateOutlet="template" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class SpotDropModalPortalComponent extends UntilDestroyedMixin implements OnInit {
  readonly cdRef = inject(ChangeDetectorRef);
  readonly template$ = inject(SpotDropModalTeleportationService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  @HostBinding('class.spot-drop-modal-portal') className = true;

  template:TeleportInstance|null = null;

  ngOnInit() {
    this
      .template$
      .templateRef$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((templ) => {
        this.template = templ;
        this.cdRef.detectChanges();
        this.template$.hasRendered$.next(!!this.elementRef.nativeElement.children.length);
      });
  }
}
