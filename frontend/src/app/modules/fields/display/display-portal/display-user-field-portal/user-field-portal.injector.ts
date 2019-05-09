import {InjectionToken, Injector} from "@angular/core";
import {PortalInjector} from "@angular/cdk/portal";
import {UserResource} from "core-app/modules/hal/resources/user-resource";

/**
 * Creates an injector for the user display field portal to pass data into.
 *
 * @returns {PortalInjector}
 */

export const OpDisplayPortalUserToken = new InjectionToken('wp-display-portal--user');

export function createLocalInjector(injector:Injector, user:UserResource):Injector {
  const injectorTokens = new WeakMap();
  injectorTokens.set(OpDisplayPortalUserToken, user);

  return new PortalInjector(injector, injectorTokens);
}
