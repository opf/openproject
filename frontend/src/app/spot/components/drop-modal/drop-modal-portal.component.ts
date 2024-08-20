import {
  AfterViewChecked,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  OnInit,
} from '@angular/core';
import { SpotDropModalTeleportationService, TeleportInstance } from './drop-modal-teleportation.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';


@Component({
  selector: 'opce-spot-drop-modal-portal',
  template: '<ng-container *ngTemplateOutlet="template"></ng-container>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotDropModalPortalComponent extends UntilDestroyedMixin implements OnInit, AfterViewChecked {
  @HostBinding('class.spot-drop-modal-portal') className = true;

  template:TeleportInstance|null = null;

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly template$:SpotDropModalTeleportationService,
    readonly elementRef:ElementRef<HTMLElement>,
  ) {
    super();
  }

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
      });
  }

  ngAfterViewChecked():void {
    this.template$.hasRendered$.next(!!this.elementRef.nativeElement.children.length);
  }
}
