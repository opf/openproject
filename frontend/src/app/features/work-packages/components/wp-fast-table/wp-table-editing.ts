import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';

export class WorkPackageTableEditingContext {
  @LazyInject() public halEditing:HalResourceEditingService;

  constructor(readonly table:WorkPackageTable,
    readonly injector:Injector) {
  }

  public forms:Record<string, TableEditForm> = {};

  public reset() {
    Object.values(this.forms).forEach((form) => form.destroy());
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
