/**
 * A CDK portal implementation to wrap display fields in non-angular contexts.
 */
import {ApplicationRef, ComponentFactoryResolver, Injectable, Injector} from "@angular/core";
import {ComponentPortal, DomPortalOutlet} from "@angular/cdk/portal";
import {UserFieldPortalComponent} from "core-app/modules/fields/display/display-portal/display-user-field-portal/user-field-portal.component";
import {createLocalInjector} from "core-app/modules/fields/display/display-portal/display-user-field-portal/user-field-portal.injector";
import {UserResource} from "core-app/modules/hal/resources/user-resource";

@Injectable()
export class UserFieldPortalService {

  constructor(private readonly appRef:ApplicationRef,
              private readonly componentFactoryResolver:ComponentFactoryResolver,
              private readonly injector:Injector) {

  }

  public create(container:HTMLElement, users:UserResource[], multiLines:boolean = false) {
    // Create the portal outlet
    const outlet = new DomPortalOutlet(
      container,
      this.componentFactoryResolver,
      this.appRef,
      this.injector
    );

    // Create an injector that contains injectable reference to the user
    const localInjector = createLocalInjector(this.injector, users, multiLines);

    // Create a portal for the display field
    const portal = new ComponentPortal(UserFieldPortalComponent, null, localInjector);

    // Attach the portal to the outlet
    setTimeout(() => outlet.attachComponentPortal(portal));

    return outlet;
  }
}


