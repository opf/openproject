import {Injector} from "@angular/core";
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken
} from "core-app/modules/fields/edit/edit-field.component";
import {PortalInjector} from "@angular/cdk/portal";
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {WorkPackageChange} from "core-components/wp-edit/work-package-change";

/**
 * Creates an injector for the edit field portal to pass data into.
 *
 * @returns {PortalInjector}
 */
export function createLocalInjector(injector:Injector, change:WorkPackageChange, fieldHandler:EditFieldHandler, schema:IFieldSchema):Injector {
  const injectorTokens = new WeakMap();

  injectorTokens.set(OpEditingPortalChangesetToken, change);
  injectorTokens.set(OpEditingPortalHandlerToken, fieldHandler);
  injectorTokens.set(OpEditingPortalSchemaToken, schema);

  return new PortalInjector(injector, injectorTokens);
}
