import {Component, ElementRef, Inject, ChangeDetectorRef, ViewChild} from "@angular/core";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {EditFormComponent} from "core-app/modules/fields/edit/edit-form/edit-form.component";
import { untilComponentDestroyed } from 'ng2-rx-componentdestroyed';

@Component({
  templateUrl: './create.modal.html',
  styleUrls: ['../edit/edit.modal.sass'],
  providers: [
    HalResourceEditingService
  ]
})
export class TimeEntryCreateModal extends OpModalComponent {

  @ViewChild('editForm', { static: true }) editForm:EditFormComponent;

  text = {
    title: this.i18n.t('js.time_entry.edit'),
    attributes: {
      comment: this.i18n.t('js.time_entry.comment'),
      hours: this.i18n.t('js.time_entry.hours'),
      activity: this.i18n.t('js.time_entry.activity'),
      workPackage: this.i18n.t('js.time_entry.work_package'),
      spentOn: this.i18n.t('js.time_entry.spent_on'),
    },
    wpRequired: this.i18n.t('js.time_entry.work_package_required'),
    create: this.i18n.t('js.label_create'),
    close: this.i18n.t('js.button_close')
  };

  public closeOnEscape = false;
  public closeOnOutsideClick = false;
  public customFields:{key:string, label:string}[] = [];
  public workPackageSelected:boolean = false;

  public createdEntry:TimeEntryResource;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly i18n:I18nService,
              readonly halEditing:HalResourceEditingService) {
    super(locals, cdRef, elementRef);

    halEditing
      .temporaryEditResource(this.entry)
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(changeset => {
        if (changeset && changeset.workPackage) {
          this.workPackageSelected = true;
        }
      });
  }

  public get entry() {
    return this.locals.entry;
  }

  public createEntry() {
    this.editForm.save()
      .then(() => {
        this.service.close();
      });
  }

  public setModifiedEntry($event:{savedResource:HalResource, isInital:boolean}) {
    this.createdEntry = $event.savedResource as TimeEntryResource;
  }

  ngOnInit() {
    super.ngOnInit();
    this.setCustomFields(this.entry.schema);
  }

  private setCustomFields(schema:SchemaResource) {
    Object.entries(schema).forEach(([key, keySchema]) => {
      if (key.match(/customField\d+/)) {
        this.customFields.push({key: key, label: keySchema.name });
      }
    });
  }
}
