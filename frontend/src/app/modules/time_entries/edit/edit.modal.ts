import {Component, ElementRef, Inject, ChangeDetectorRef, ChangeDetectionStrategy, ViewChild} from "@angular/core";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {TimeEntryFormComponent} from "core-app/modules/time_entries/form/form.component";

@Component({
  templateUrl: './edit.modal.html',
  styleUrls: ['./edit.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService
  ]
})
export class TimeEntryEditModal extends OpModalComponent {

  @ViewChild('editForm', { static: true }) editForm:TimeEntryFormComponent;

  text = {
    title: this.i18n.t('js.time_entry.label'),
    save: this.i18n.t('js.button_save'),
    delete: this.i18n.t('js.button_delete'),
    cancel: this.i18n.t('js.button_cancel'),
    close: this.i18n.t('js.button_close')
  };

  public closeOnEscape = false;
  public closeOnOutsideClick = false;

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

  public saveEntry() {
    this.editForm.save()
      .then(() => {
        this.service.close();
      });
  }

  public get updateAllowed() {
    return !!this.entry.update;
  }

  public get deleteAllowed() {
    return !!this.entry.delete;
  }

  public destroy() {
    this.destroyedEntry = this.entry;
    this.service.close();
  }
}
