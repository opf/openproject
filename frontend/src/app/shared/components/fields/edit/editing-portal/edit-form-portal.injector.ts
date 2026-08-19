import { Injector } from '@angular/core';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';

/**
 * Creates an injector for the edit field portal to pass data into.
 *
 * @returns {Injector}
 */
export function createLocalInjector(
  injector:Injector,
  change:ResourceChangeset,
  fieldHandler:EditFieldHandler,
  schema:IFieldSchema,
):Injector {
  return Injector.create({
    providers: [
      { provide: OpEditingPortalChangesetToken, useValue: change },
      { provide: OpEditingPortalHandlerToken, useValue: fieldHandler },
      { provide: OpEditingPortalSchemaToken, useValue: schema },
    ],
    parent: injector,
  });
}
