import {Component, ChangeDetectionStrategy} from "@angular/core";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {TimeEntryBaseModal} from "core-app/modules/time_entries/shared/modal/base.modal";

@Component({
  templateUrl: '../shared/modal/base.modal.html',
  styleUrls: ['../shared/modal/base.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService
  ]
})
export class TimeEntryEditModal extends TimeEntryBaseModal {
  public modifiedEntry:TimeEntryResource;
  public destroyedEntry:TimeEntryResource;

  public setModifiedEntry($event:{savedResource:HalResource, isInital:boolean}) {
    this.modifiedEntry = $event.savedResource as TimeEntryResource;
  }

  public get saveAllowed() {
    return !!this.entry.update;
  }

  public get deleteAllowed() {
    return !!this.entry.delete;
  }

  public destroy() {
    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.destroyedEntry = this.entry;
    this.service.close();
  }
}
