import {Injector} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {WorkPackageTable} from 'core-components/wp-fast-table/wp-fast-table';
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {EditForm} from "core-app/modules/fields/edit/edit-form/edit-form";
import {TableEditForm} from "core-components/wp-edit-form/table-edit-form";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class WorkPackageTableEditingContext {

  @InjectField() public halEditing:HalResourceEditingService;

  constructor(readonly table:WorkPackageTable,
              readonly injector:Injector) {
  }

  public forms:{ [wpId:string]:TableEditForm } = {};

  public reset() {
    _.each(this.forms, (form) => form.destroy());
    this.forms = {};
  }

  public change(workPackage:WorkPackageResource):WorkPackageChangeset|undefined {
    return this.halEditing.typedState<WorkPackageResource, WorkPackageChangeset>(workPackage).value;
  }

  // TODO
  public stopEditing(workPackage:WorkPackageResource) {
    this.halEditing.stopEditing(workPackage);

    const existing = this.forms[workPackage.id!];
    if (existing) {
      existing.destroy();
      delete this.forms[workPackage.id!];
    }
  }

  public startEditing(workPackage:WorkPackageResource, classIdentifier:string):EditForm {
    const wpId = workPackage.id!;
    const existing = this.forms[wpId];
    if (existing) {
      return existing;
    }

    // Get any existing edit state for this work package
    return this.forms[wpId] = new TableEditForm(this.injector, this.table, wpId, classIdentifier);
  }
}

