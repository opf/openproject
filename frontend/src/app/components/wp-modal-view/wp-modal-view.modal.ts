import {Component, ElementRef, Inject, ChangeDetectorRef, OnInit} from "@angular/core";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageResource} from "app/modules/hal/resources/work-package-resource";

@Component({
  templateUrl: './wp-modal-view.modal.html'
})
export class WpModalViewComponent extends OpModalComponent implements OnInit {
  public closeOnOutsideClick = false;
  public workPackage:WorkPackageResource;

  text = { close_popup: this.i18n.t('js.button_close') };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly i18n:I18nService) {

    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
    this.workPackage = this.locals.workPackage;
  }
}
