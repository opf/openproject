/**
 * A CDK portal implementation to wrap wp-edit-fields in non-angular contexts.
 */
import {WorkPackageEditFieldHandler} from "core-components/wp-edit-form/work-package-edit-field-handler";
import {WorkPackageEditForm} from "core-components/wp-edit-form/work-package-edit-form";
import {ApplicationRef, ComponentFactoryResolver, Injectable, Injector} from "@angular/core";
import {ComponentPortal, DomPortalOutlet, PortalInjector} from "@angular/cdk/portal";
import {EditFieldLocals, OpEditingPortalLocalsToken} from "core-app/modules/fields/edit/edit-field.component";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {EditFormPortalComponent} from "core-app/modules/fields/edit/editing-portal/edit-form-portal.component";

@Injectable()
export class WorkPackageEditingPortalService {

  constructor(private readonly injector:Injector,
              private readonly appRef:ApplicationRef,
              private readonly componentFactoryResolver:ComponentFactoryResolver) {

  }

  public create(container:JQuery,
                form:WorkPackageEditForm,
                field:EditField,
                fieldName:string,
                errors:string[]):WorkPackageEditFieldHandler {

    // Create the portal outlet
    const outlet = this.createDomOutlet(container[0]);

    // Create a field handler for the newly active field
    const fieldHandler = new WorkPackageEditFieldHandler(
      this.injector,
      form,
      fieldName,
      field,
      container,
      () => outlet.detach(), // Don't call .dispose() on the outlet, it destroys the DOM element
      errors
    );

    // Create a portal for the edit-form/field
    const portal = new ComponentPortal(EditFormPortalComponent, null, this.createLocalInjector(fieldHandler, field));

    // Clear the container
    container.empty();

    // Attach the portal to the outlet
    outlet.attachComponentPortal(portal);

    return fieldHandler;
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


  /**
   * Creates an injector for the edit field portal to pass data into.
   *
   * @param data
   * @returns {PortalInjector}
   */
  private createLocalInjector(fieldHandler:WorkPackageEditFieldHandler, field:EditField) {
    const injectorTokens = new WeakMap();
    injectorTokens.set(OpEditingPortalLocalsToken, {
      handler: fieldHandler,
      field: field,
      fieldName: field.name
    } as EditFieldLocals);

    return new PortalInjector(this.injector, injectorTokens);
  }
}


