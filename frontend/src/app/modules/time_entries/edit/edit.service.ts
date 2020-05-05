import {Injectable, Injector} from "@angular/core";
import {OpModalService} from "app/components/op-modals/op-modal.service";
import {HalResourceService} from "app/modules/hal/services/hal-resource.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import { TimeEntryResource } from 'core-app/modules/hal/resources/time-entry-resource';
import { TimeEntryEditModal } from './edit.modal';
import { take } from 'rxjs/operators';
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";

@Injectable()
export class TimeEntryEditService {

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly halResource:HalResourceService,
              readonly i18n:I18nService) {
  }

  public edit(entry:TimeEntryResource) {
    return new Promise<{entry:TimeEntryResource, action:'update'|'destroy'}>((resolve, reject) => {
      const modal = this.opModalService.show(TimeEntryEditModal, this.injector, { entry: entry });

      modal
        .closingEvent
        .pipe(take(1))
        .subscribe(() => {
          if (modal.destroyedEntry) {
            modal.destroyedEntry.delete().then(() => {
              resolve({entry: modal.destroyedEntry, action: 'destroy'});
            });
          } else if (modal.modifiedEntry) {
            resolve({ entry: modal.modifiedEntry, action: 'update' });
          } else {
            reject();
          }
        });
    });
  }
}
