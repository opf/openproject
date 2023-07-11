import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { TimeEntryBaseModal } from 'core-app/shared/components/time_entries/shared/modal/base.modal';

@Component({
  templateUrl: '../shared/modal/base.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TimeEntryEditModalComponent extends TimeEntryBaseModal implements OnInit {
  public modifiedEntry:TimeEntryResource;

  public destroyedEntry:TimeEntryResource;

  ngOnInit() {
    super.ngOnInit();
  }

  public setModifiedEntry($event:{ savedResource:HalResource, isInital:boolean }) {
    this.modifiedEntry = $event.savedResource as TimeEntryResource;
    this.reloadWorkPackageAndClose();
  }

  public get saveAllowed() {
    return !!this.entry.update;
  }

  public get deleteAllowed() {
    return !!this.entry.delete;
  }

  public destroy() {
    // eslint-disable-next-line no-alert
    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.destroyedEntry = this.entry;
    this.service.close();
  }
}
