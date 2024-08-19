import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  OnInit,
  ViewChild,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';

@Component({
  templateUrl: './wp-share.modal.html',
  styleUrls: ['./wp-share.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageShareModalComponent extends OpModalComponent implements OnInit {
  @ViewChild('frameElement') frameElement:ElementRef<HTMLIFrameElement>|undefined;

  // Hide close button so it's not duplicated in primer (WP#51699)
  showCloseButton = false;

  private workPackage:WorkPackageResource;
  public frameSrc:string;

  text = {
    title: this.I18n.t('js.work_packages.sharing.title'),
    button_close: this.I18n.t('js.button_close'),
  };

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly elementRef:ElementRef<HTMLElement>,
    readonly pathHelper:PathHelperService,
    readonly actions$:ActionsService,
  ) {
    super(locals, cdRef, elementRef);

    this.workPackage = this.locals.workPackage as WorkPackageResource;
    this.frameSrc = this.pathHelper.workPackageSharePath(this.workPackage.id as string);
  }

  ngOnInit() {
    super.ngOnInit();
  }

  onClose():boolean {
    this.actions$.dispatch(shareModalUpdated({ workPackageId: this.workPackage.id as string }));

    return super.onClose();
  }
}
