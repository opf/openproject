import {
  Injectable,
  Injector,
} from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { take } from 'rxjs/operators';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { TimeEntryEditModalComponent } from './edit.modal';
import { TimeEntryChangeset } from 'core-app/features/work-packages/helpers/time-entries/time-entry-changeset';
import * as moment from 'moment';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { TimeEntryService } from 'core-app/shared/components/time_entries/services/time_entry.service';

export interface TimeEntryModalOptions {
  showWorkPackageField?:boolean;
  showUserField?:boolean;
}

@Injectable()
export class TimeEntryEditService {
  constructor(
    readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
    readonly halResource:HalResourceService,
    readonly schemaCache:SchemaCacheService,
    readonly timezoneService:TimezoneService,
    readonly timeEntry:TimeEntryService,
    protected halEditing:HalResourceEditingService,
    readonly i18n:I18nService,
    ) {
  }

  public edit(
    entry:TimeEntryResource,
    options:TimeEntryModalOptions = {},
  ):Promise<{ entry:TimeEntryResource, action:'update'|'destroy' }> {
    return new Promise<{ entry:TimeEntryResource, action:'update'|'destroy' }>((resolve, reject) => {
      void this
        .createChangeset(entry)
        .then((changeset) => this.opModalService.show(
          TimeEntryEditModalComponent,
          this.injector,
          { ...options, changeset },
        ).subscribe((modal) => modal
          .closingEvent
          .pipe(take(1))
          .subscribe(() => {
            if (modal.destroyedEntry) {
              // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
              void modal.destroyedEntry.delete().then(() => {
                resolve({ entry: modal.destroyedEntry, action: 'destroy' });
              });
            } else if (modal.modifiedEntry) {
              resolve({ entry: modal.modifiedEntry, action: 'update' });
            } else {
              resolve({ entry: modal.entry, action: 'unchanged' });
            }
          })));
    });
  }


  public async stopTimerAndEdit(activeTimer:TimeEntryResource):Promise<unknown> {
    await this.schemaCache.ensureLoaded(activeTimer);

    const change = new TimeEntryChangeset(activeTimer);
    const hours = moment().diff(moment(activeTimer.createdAt as string), 'hours', true);
    const formatted = this.timezoneService.toISODuration(hours, 'hours');
    change.setValue('hours', formatted);
    change.setValue('ongoing', false);

    // eslint-disable-next-line consistent-return
    return this
      .halEditing
      .save(change)
      .then((commit) => {
        this.timeEntry.activeTimer$.next(null);
        return this.edit(commit.resource as TimeEntryResource);
      });
  }


  public createChangeset(entry:TimeEntryResource):Promise<ResourceChangeset<TimeEntryResource>> {
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
