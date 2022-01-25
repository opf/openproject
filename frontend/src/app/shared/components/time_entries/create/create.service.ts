import { Injectable, Injector } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { take } from 'rxjs/operators';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { Moment } from 'moment';
import { TimeEntryCreateModalComponent } from 'core-app/shared/components/time_entries/create/create.modal';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';

@Injectable()
export class TimeEntryCreateService {
  constructor(readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly halResource:HalResourceService,
    readonly apiV3Service:ApiV3Service,
    readonly schemaCache:SchemaCacheService,
    protected halEditing:HalResourceEditingService,
    readonly i18n:I18nService) {
  }

  public create(date:Moment, wp?:WorkPackageResource, showWorkPackageField = true) {
    return new Promise<{ entry:TimeEntryResource, action:'create' }>((resolve, reject) => {
      this
        .createNewTimeEntry(date, wp)
        .then((changeset) => {
          const modal = this.opModalService.show(TimeEntryCreateModalComponent, this.injector, { changeset, showWorkPackageField });

          modal
            .closingEvent
            .pipe(take(1))
            .subscribe(() => {
              if (modal.createdEntry) {
                resolve({ entry: modal.createdEntry, action: 'create' });
              } else {
                reject();
              }
            });
        });
    });
  }

  public createNewTimeEntry(date:Moment, wp?:WorkPackageResource) {
    const payload:any = {
      spentOn: date.format('YYYY-MM-DD'),
    };

    if (wp) {
      payload._links = {
        workPackage: {
          href: wp.href,
        },
      };
    }

    return this
      .apiV3Service
      .time_entries
      .form
      .post(payload)
      .toPromise()
      .then((form) => this.fromCreateForm(form));
  }

  public fromCreateForm(form:FormResource):ResourceChangeset {
    const entry = this.initializeNewResource(form);

    return this.halEditing.edit<TimeEntryResource, ResourceChangeset<TimeEntryResource>>(entry, form);
  }

  private initializeNewResource(form:FormResource) {
    const entry = this.halResource.createHalResourceOfType<TimeEntryResource>('TimeEntry', form.payload.$plain());

    entry.$links.schema = { href: 'new' };

    entry._type = 'TimeEntry';
    entry.id = 'new';
    entry.hours = 'PT1H';

    // Set update link to form
    entry.update = entry.$links.update = form.$links.self;
    // Use POST /work_packages for saving link
    entry.updateImmediately = entry.$links.updateImmediately = (payload:{}) => this
      .apiV3Service
      .time_entries
      .post(payload)
      .toPromise();

    entry.state.putValue(entry);
    // We need to provide the schema to the cache so that it is available in the html form to e.g. determine
    // the editability.
    // It would be better if the edit field could simply rely on the changeset if it exists.
    this.schemaCache.update(entry, form.schema);

    return entry;
  }
}
