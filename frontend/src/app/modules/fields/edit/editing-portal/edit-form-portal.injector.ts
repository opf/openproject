import {Injector} from "@angular/core";
import {
  OpEditingPortalFieldToken,
  OpEditingPortalHandlerToken
} from "core-app/modules/fields/edit/edit-field.component";
import {PortalInjector} from "@angular/cdk/portal";
import {IEditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler.interface";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";

/**
 * Creates an injector for the edit field portal to pass data into.
 *
 * @returns {PortalInjector}
 */
export function createLocalInjector(injector:Injector, fieldHandler:IEditFieldHandler, field:EditField):Injector {
  const injectorTokens = new WeakMap();

  injectorTokens.set(OpEditingPortalHandlerToken, fieldHandler);
  injectorTokens.set(OpEditingPortalFieldToken, field);

  return new PortalInjector(injector, injectorTokens);
}
