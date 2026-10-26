//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { insideGrid } from './handlers/state/keyboard/roving-tabindex';

export interface ActiveTableField {
  form:TableEditForm;
  handler:EditFieldHandler;
}

let nextTableEditorOwner = 0;

function tableEditorOwnerId():string {
  nextTableEditorOwner += 1;
  return `wp-table-${nextTableEditorOwner}`;
}

export class WorkPackageTableEditingContext {
  @LazyInject() public halEditing:HalResourceEditingService;

  constructor(readonly table:WorkPackageTable,
    readonly injector:Injector) {
  }

  public forms:Record<string, TableEditForm> = {};

  public readonly ownerId = tableEditorOwnerId();

  public activeTableFields():ActiveTableField[] {
    return Object.values(this.forms).flatMap((form) =>
      Object.values(form.activeFields).map((handler) => ({ form, handler })));
  }

  public activeGridFields():ActiveTableField[] {
    return this.activeTableFields().filter(({ handler }) => insideGrid(this.table.scrollContainer, handler.element ?? null));
  }

  public fieldOwning(node:Node|null):ActiveTableField|null {
    return this.activeTableFields().find(({ handler }) => handler.owns(node)) ?? null;
  }

  public gridFieldOwning(node:Node|null):ActiveTableField|null {
    return this.activeGridFields().find(({ handler }) => handler.owns(node)) ?? null;
  }

  public owns(node:Node|null):boolean {
    return this.fieldOwning(node) !== null;
  }

  public markOverlay(overlay:HTMLElement):void {
    overlay.dataset.wpTableEditor = this.ownerId;
    this.table.keyboardNavigation?.adoptOverlay(overlay);
  }

  public reset() {
    if (this.table.destroyed) {
      const forms = Object.values(this.forms);
      this.forms = {};
      forms.forEach((form) => runCleanup(() => form.destroy()));
      return;
    }

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
    const form = new TableEditForm(this.injector, this.table, wpId, classIdentifier);
    this.forms[wpId] = form;
    return form;
  }
}
