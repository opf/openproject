import { Injectable, Injector } from "@angular/core";
import { OpModalService } from "app/components/op-modals/op-modal.service";
import { HalResourceService } from "app/modules/hal/services/hal-resource.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { TimeEntryResource } from 'core-app/modules/hal/resources/time-entry-resource';
import { take } from 'rxjs/operators';
import { FormResource } from "core-app/modules/hal/resources/form-resource";
import { TimeEntryDmService } from "core-app/modules/hal/dm-services/time-entry-dm.service";
import { ResourceChangeset } from "core-app/modules/fields/changeset/resource-changeset";
import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { Moment } from 'moment';
import { TimeEntryCreateModal } from "core-app/modules/time_entries/create/create.modal";
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';

@Injectable()
export class TimeEntryCreateService {

  constructor(readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly halResource:HalResourceService,
    readonly timeEntryDm:TimeEntryDmService,
    protected halEditing:HalResourceEditingService,
    readonly i18n:I18nService) {
  }

  public create(date:Moment, wp?:WorkPackageResource, showWorkPackageField:boolean = true) {
    return new Promise<{ entry:TimeEntryResource, action:'create' }>((resolve, reject) => {
      this
        .createNewTimeEntry(date, wp)
        .then(changeset => {
          const modal = this.opModalService.show(TimeEntryCreateModal, this.injector, { entry: changeset.pristineResource, showWorkPackageField: showWorkPackageField });

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
    let payload:any = {
      spentOn: date.format('YYYY-MM-DD')
    };

    if (wp) {
      payload['_links'] = {
        workPackage: {
          href: wp.href
        }
      };
    }

    return this.timeEntryDm.createForm(payload).then(form => {
      return this.fromCreateForm(form);
    });
  }

  public fromCreateForm(form:FormResource):ResourceChangeset {
    let entry = this.initializeNewResource(form);

    return this.halEditing.edit<TimeEntryResource, ResourceChangeset<TimeEntryResource>>(entry, form);
  }

  private initializeNewResource(form:FormResource) {
    let entry = this.halResource.createHalResourceOfType<TimeEntryResource>('TimeEntry', form.payload.$plain());

    entry.$links['schema'] = form.schema;
    entry.overriddenSchema = form.schema;

    entry['_type'] = 'TimeEntry';
    entry['id'] = 'new';
    entry['hours'] = 'PT1H';

    // Set update link to form
    entry['update'] = entry.$links['update'] = form.$links.self;
    // Use POST /work_packages for saving link
    entry['updateImmediately'] = entry.$links['updateImmediately'] = (payload:{}) => {
      return this.timeEntryDm.create(payload);
    };

    entry.state.putValue(entry);

    return entry;
  }
}
