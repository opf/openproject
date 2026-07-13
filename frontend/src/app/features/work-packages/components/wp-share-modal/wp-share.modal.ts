import { ChangeDetectionStrategy, Component, ElementRef, OnInit, ViewChild, inject } from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { type FrameElement } from '@hotwired/turbo';

@Component({
  templateUrl: './wp-share.modal.html',
  styleUrls: ['./wp-share.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageShareModalComponent extends OpModalComponent implements OnInit {
  readonly I18n = inject(I18nService);
  readonly pathHelper = inject(PathHelperService);
  readonly actions$ = inject(ActionsService);

  @ViewChild('frameElement') frameElement:ElementRef<FrameElement>|undefined;

  // Hide close button so it's not duplicated in primer (WP#51699)
  showCloseButton = false;

  private workPackage:WorkPackageResource;
  public frameSrc:string;

  text = {
    title: this.I18n.t('js.work_packages.sharing.title'),
    button_close: this.I18n.t('js.button_close'),
  };

  constructor() {
    super();

    this.workPackage = this.locals.workPackage as WorkPackageResource;
    this.frameSrc = this.pathHelper.workPackageSharePath(this.workPackage.id!);
  }

  ngOnInit() {
    super.ngOnInit();
  }

  onClose():boolean {
    this.actions$.dispatch(shareModalUpdated({ workPackageId: this.workPackage.id! }));

    return super.onClose();
  }
}
