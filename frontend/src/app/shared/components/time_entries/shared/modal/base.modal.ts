import {
  ChangeDetectorRef,
  Directive,
  ElementRef,
  Inject,
  Injector,
  OnInit,
  ViewChild,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimeEntryFormComponent } from 'core-app/shared/components/time_entries/form/form.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';

@Directive()
export abstract class TimeEntryBaseModal extends OpModalComponent implements OnInit {
  @ViewChild('editForm', { static: true }) editForm:TimeEntryFormComponent;

  public text:{ [key:string]:string } = {
    title: this.i18n.t('js.time_entry.title'),
    cancel: this.i18n.t('js.button_cancel'),
    close: this.i18n.t('js.button_close'),
    save: this.i18n.t('js.button_save'),
    delete: this.i18n.t('js.button_delete'),
    areYouSure: this.i18n.t('js.text_are_you_sure'),
  };

  public formInFlight:boolean;

  public changeset:ResourceChangeset<TimeEntryResource>;

  @InjectField() apiV3Service:ApiV3Service;

  constructor(readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly i18n:I18nService,
    readonly injector:Injector) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
    this.changeset = this.locals.changeset as ResourceChangeset<TimeEntryResource>;
  }

  public abstract setModifiedEntry($event:{ savedResource:HalResource, isInital:boolean }):void;

  public get entry():TimeEntryResource {
    return this.changeset.projectedResource;
  }

  public get showWorkPackageField():boolean {
    return this.locals.showWorkPackageField !== false;
  }

  public get showUserField():boolean {
    return this.locals.showUserField !== false;
  }

  public saveEntry():void {
    this.formInFlight = true;

    this.editForm.save()
      .then(() => this.reloadWorkPackageAndClose())
      .catch(() => {
        this.formInFlight = false;
        this.cdRef.detectChanges();
      });
  }

  public get saveAllowed():boolean {
    return true;
  }

  public get deleteAllowed():boolean {
    return true;
  }

  protected reloadWorkPackageAndClose():void {
    this.service.close();
    this.formInFlight = false;
    // reload workPackage
    if (this.entry.workPackage) {
      void this
        .apiV3Service
        .work_packages
        .id(this.entry.workPackage)
        .refresh();
    }

    this.cdRef.detectChanges();
  }
}
