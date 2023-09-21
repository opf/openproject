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

@Component({
  templateUrl: './wp-share.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageShareModalComponent extends OpModalComponent implements OnInit {
  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
  }
}
