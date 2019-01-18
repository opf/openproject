import {ApplicationRef, ComponentFactoryResolver, ComponentRef, Injector} from "@angular/core";
import {TableState} from "core-components/wp-table/table-state/table-state";
import {ComponentPortal, ComponentType, DomPortalOutlet} from "@angular/cdk/portal";
import {take} from "rxjs/operators";

export class PortalBuilder<T> {
  private readonly appRef:ApplicationRef = this.injector.get(ApplicationRef);
  private readonly componentFactoryResolver:ComponentFactoryResolver = this.injector.get(ComponentFactoryResolver);
  private tableState:TableState = this.injector.get(TableState);

  constructor(private readonly injector:Injector) {
  }

  /**
   * Renders an angular CDK drag component into the column
   */
  protected attachWithPortal(element:HTMLElement, component:ComponentType<T>):Promise<ComponentRef<T>> {
    // Create the portal outlet
    const outlet = this.createDomOutlet(element);

    // Create a portal for the edit-form/field
    const portal = new ComponentPortal(component, null, this.injector);

    // Destroy the outlet appropriately
    this.tableState.stopAllSubscriptions
      .pipe(take(1))
      .subscribe(() => {
        portal.detach();
        outlet.dispose();
      });

    // Attach the portal to the outlet
    return new Promise<ComponentRef<T>>(resolve => {
      // Wrap in timeout to ensure running outside ngInit
      setTimeout(() => resolve(outlet.attachComponentPortal(portal)));
    });
  }

  /**
   * Creates a dom outlet for attaching the portal.
   *
   * @param {HTMLElement} hostElement The element where the portal will be attached into
   * @returns {DomPortalOutlet}
   */
  private createDomOutlet(hostElement:HTMLElement) {
    return new DomPortalOutlet(
      hostElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector
    );
  }
}
