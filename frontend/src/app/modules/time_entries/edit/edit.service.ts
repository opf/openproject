import { Injectable, Injector } from "@angular/core";
import { OpModalService } from "core-app/modules/modal/modal.service";
import { HalResourceService } from "app/modules/hal/services/hal-resource.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { TimeEntryResource } from 'core-app/modules/hal/resources/time-entry-resource';
import { TimeEntryEditModal } from './edit.modal';
import { take } from 'rxjs/operators';
import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { ResourceChangeset } from "core-app/modules/fields/changeset/resource-changeset";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Injectable()
export class TimeEntryEditService {

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly apiV3Service:APIV3Service,
              readonly halResource:HalResourceService,
              protected halEditing:HalResourceEditingService,
              readonly i18n:I18nService) {
  }

  public edit(entry:TimeEntryResource) {
    return new Promise<{entry:TimeEntryResource, action:'update'|'destroy'}>((resolve, reject) => {
      this
        .createChangeset(entry)
        .then(changeset => {
          const modal = this.opModalService.show(TimeEntryEditModal, this.injector, { changeset: changeset });

          modal
            .closingEvent
            .pipe(take(1))
            .subscribe(() => {
              if (modal.destroyedEntry) {
                modal.destroyedEntry.delete().then(() => {
                  resolve({ entry: modal.destroyedEntry, action: 'destroy' });
                });
              } else if (modal.modifiedEntry) {
                resolve({ entry: modal.modifiedEntry, action: 'update' });
              } else {
                reject();
              }
            });
        });
    });
  }

  public createChangeset(entry:TimeEntryResource) {
    return this
      .apiV3Service
      .time_entries
      .id(entry)
      .form
      .post(entry)
      .toPromise()
      .then(form => {
        return this.halEditing.edit<TimeEntryResource, ResourceChangeset<TimeEntryResource>>(entry, form);
      });
  }
}
