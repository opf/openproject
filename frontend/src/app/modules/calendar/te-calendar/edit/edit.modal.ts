import {Component, ElementRef, Inject, ChangeDetectorRef} from "@angular/core";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";

@Component({
  templateUrl: './edit.modal.html',
  styleUrls: ['./edit.modal.sass'],
  providers: [
    HalResourceEditingService
  ]
})
export class TimeEntryEditModal extends OpModalComponent {

  text = {
    title: this.i18n.t('js.time_entry.edit'),
    attributes: {
      comment: this.i18n.t('js.time_entry.comment'),
      hours: this.i18n.t('js.time_entry.hours'),
      activity: this.i18n.t('js.time_entry.activity'),
      workPackage: this.i18n.t('js.time_entry.work_package'),
      spentOn: this.i18n.t('js.time_entry.spent_on'),
    },
    close: this.i18n.t('js.button_close'),
    delete: this.i18n.t('js.button_delete')
  };

  public closeOnEscape = false;
  public closeOnOutsideClick = false;
  public customFields:{key:string, label:string}[] = [];

  public modifiedEntry:TimeEntryResource;
  public destroyedEntry:TimeEntryResource;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly i18n:I18nService) {
    super(locals, cdRef, elementRef);
  }

  public get entry() {
    return this.locals.entry;
  }

  public setModifiedEntry($event:{savedResource:HalResource, isInital:boolean}) {
    this.modifiedEntry = $event.savedResource as TimeEntryResource;
  }

  public get deleteAllowed() {
    return !!this.entry.delete;
  }

  public destroy() {
    this.destroyedEntry = this.entry;
    this.service.close();
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
