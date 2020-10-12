import {ResourceChangeset} from "core-app/modules/fields/changeset/resource-changeset";
import { TimeEntryResource } from 'core-app/modules/hal/resources/time-entry-resource';

export class TimeEntryChangeset extends ResourceChangeset<TimeEntryResource> {

  public setValue(key:string, val:any) {
    super.setValue(key, val);

    // Update the form for fields that may alter the form itself
    if (key === 'workPackage') {
      this.updateForm();
    }
  }

  protected buildPayloadFromChanges() {
    let payload = super.buildPayloadFromChanges();

    // we ignore the project and instead rely completely on the work package.
    delete payload['_links']['project'];

    return payload;
  }
}
