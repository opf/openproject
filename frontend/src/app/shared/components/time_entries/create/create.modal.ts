import { ChangeDetectionStrategy, Component } from '@angular/core';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { TimeEntryBaseModal } from '../shared/modal/base.modal';

@Component({
  templateUrl: '../shared/modal/base.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    HalResourceEditingService,
  ],
})
export class TimeEntryCreateModalComponent extends TimeEntryBaseModal {
  public createdEntry:TimeEntryResource;

  public get deleteAllowed() {
    return false;
  }

  public setModifiedEntry($event:{ savedResource:HalResource, isInital:boolean }) {
    this.createdEntry = $event.savedResource as TimeEntryResource;
    this.reloadWorkPackageAndClose();
  }
}
