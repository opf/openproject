import { Injector } from '@angular/core';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { PortalInjector } from '@angular/cdk/portal';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';

/**
 * Creates an injector for the edit field portal to pass data into.
 *
 * @returns {PortalInjector}
 */
export function createLocalInjector(
  injector:Injector,
  change:ResourceChangeset,
  fieldHandler:EditFieldHandler,
  schema:IFieldSchema,
):Injector {
  const injectorTokens = new WeakMap();

  injectorTokens.set(OpEditingPortalChangesetToken, change);
  injectorTokens.set(OpEditingPortalHandlerToken, fieldHandler);
  injectorTokens.set(OpEditingPortalSchemaToken, schema);

  return new PortalInjector(injector, injectorTokens);
}
