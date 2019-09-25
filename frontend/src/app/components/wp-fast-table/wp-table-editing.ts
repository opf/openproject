import {Injector} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {TableRowEditContext} from '../wp-edit-form/table-row-edit-context';

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {WorkPackageTable} from 'core-components/wp-fast-table/wp-fast-table';
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {EditForm} from "core-app/modules/fields/edit/edit-form/edit-form";

export class WorkPackageTableEditingContext {

  public halEditing:HalResourceEditingService = this.injector.get(HalResourceEditingService);

  constructor(readonly table:WorkPackageTable,
              readonly injector:Injector) {
  }

  public forms:{ [wpId:string]:EditForm } = {};

  public reset() {
    _.each(this.forms, (form) => form.destroy());
    this.forms = {};
  }

  public change(workPackageId:string):WorkPackageChangeset | undefined {
    return this.halEditing.state(workPackageId).value;
  }

  public stopEditing(workPackageId:string) {
    this.halEditing.stopEditing(workPackageId);

    const existing = this.forms[workPackageId];
    if (existing) {
      existing.destroy();
      delete this.forms[workPackageId];
    }
  }

  public startEditing(workPackage:WorkPackageResource, classIdentifier:string):EditForm {
    const wpId = workPackage.id!;
    const existing = this.forms[wpId];
    if (existing) {
      return existing;
    }

    // Get any existing edit state for this work package
    const editContext = new TableRowEditContext(this.table, this.injector, wpId, classIdentifier);
    return this.forms[wpId] = EditForm.createInContext(this.injector, editContext, workPackage, false);
  }
}

