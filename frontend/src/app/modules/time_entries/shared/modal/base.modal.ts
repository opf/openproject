import { ElementRef, Inject, ChangeDetectorRef, ViewChild, Directive, Injector } from "@angular/core";
import { OpModalComponent } from "core-app/modules/modal/modal.component";
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { OpModalLocalsMap } from "core-app/modules/modal/modal.types";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { TimeEntryFormComponent } from "core-app/modules/time_entries/form/form.component";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { InjectField } from 'core-app/helpers/angular/inject-field.decorator';
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Directive()
export abstract class TimeEntryBaseModal extends OpModalComponent {
  @ViewChild('editForm', { static: true }) editForm:TimeEntryFormComponent;

  public text:{ [key:string]:string } = {
    title: this.i18n.t('js.time_entry.title'),
    cancel: this.i18n.t('js.button_cancel'),
    close: this.i18n.t('js.button_close'),
    delete: this.i18n.t('js.button_delete'),
    areYouSure: this.i18n.t('js.text_are_you_sure'),
  };

  public closeOnEscape = false;
  public closeOnOutsideClick = false;
  public formInFlight:boolean;

  @InjectField() apiV3Service:APIV3Service;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly i18n:I18nService,
              readonly injector:Injector) {
    super(locals, cdRef, elementRef);
  }

  public abstract setModifiedEntry($event:{savedResource:HalResource, isInital:boolean}):void;

  public get changeset() {
    return this.locals.changeset;
  }

  public get entry() {
    return this.changeset.projectedResource;
  }

  public get showWorkPackageField() {
    return this.locals.showWorkPackageField !== undefined ? this.locals.showWorkPackageField : true;
  }

  public saveEntry() {
    this.formInFlight = true;

    this.editForm.save()
      .then(() => this.reloadWorkPackageAndClose())
      .catch(() => {
        this.formInFlight = false;
        this.cdRef.detectChanges();
      });
  }

  public get saveText() {
    return this.i18n.t('js.button_save');
  }

  public get saveAllowed() {
    return true;
  }

  public get deleteAllowed() {
    return true;
  }

  protected reloadWorkPackageAndClose() {
    // reload workPackage
    if (this.entry.workPackage) {
      this
        .apiV3Service
        .work_packages
        .id(this.entry.workPackage)
        .refresh();
    }
    this.service.close();
    this.formInFlight = false;
    this.cdRef.detectChanges();
  }
}
