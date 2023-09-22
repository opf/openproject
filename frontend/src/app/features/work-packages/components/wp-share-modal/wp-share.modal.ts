import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnInit,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  templateUrl: './wp-share.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageShareModalComponent extends OpModalComponent implements OnInit {
  private workPackage:WorkPackageResource;
  public frameSrc:string;

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {
    super(locals, cdRef, elementRef);

    this.workPackage = this.locals.workPackage as WorkPackageResource;
    // TODO: put into path helper
    this.frameSrc = `/work_packages/${this.workPackage.id as string}/shares`;
  }

  ngOnInit() {
    super.ngOnInit();
  }
}
