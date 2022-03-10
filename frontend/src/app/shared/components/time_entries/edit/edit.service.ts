import { Injectable, Injector } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { take } from 'rxjs/operators';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { TimeEntryEditModalComponent } from './edit.modal';

@Injectable()
export class TimeEntryEditService {
  constructor(readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
    readonly halResource:HalResourceService,
    protected halEditing:HalResourceEditingService,
    readonly i18n:I18nService) {
  }

  public edit(entry:TimeEntryResource) {
    return new Promise<{ entry:TimeEntryResource, action:'update'|'destroy' }>((resolve, reject) => {
      this
        .createChangeset(entry)
        .then((changeset) => {
          const modal = this.opModalService.show(TimeEntryEditModalComponent, this.injector, { changeset });

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
      .then((form) => this.halEditing.edit<TimeEntryResource, ResourceChangeset<TimeEntryResource>>(entry, form));
  }
}
