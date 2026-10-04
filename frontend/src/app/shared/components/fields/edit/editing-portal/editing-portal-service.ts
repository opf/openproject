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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/**
 * A CDK portal implementation to wrap edit-fields in non-angular contexts.
 */
import { ApplicationRef, DestroyRef, Injectable, Injector, inject } from '@angular/core';
import { ComponentPortal, DomPortalOutlet } from '@angular/cdk/portal';
import { EditFormPortalComponent } from 'core-app/shared/components/fields/edit/editing-portal/edit-form-portal.component';
import { createLocalInjector } from 'core-app/shared/components/fields/edit/editing-portal/edit-form-portal.injector';
import { take, takeUntil } from 'rxjs/operators';
import { lastValueFrom } from 'rxjs';
import { onDestroySafely, runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { EditActivationCancelled } from '../edit-form/edit-activation-cancelled';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { HalResourceEditFieldHandler } from 'core-app/shared/components/fields/edit/field-handler/hal-resource-edit-field-handler';

@Injectable({ providedIn: 'root' })
export class EditingPortalService {
  private readonly appRef = inject(ApplicationRef);
  private readonly pathHelper = inject(PathHelperService);


  public create(container:HTMLElement,
    injector:Injector,
    form:EditForm,
    schema:IFieldSchema,
    fieldName:string,
    errors:string[],
    destroyRef?:DestroyRef):Promise<EditFieldHandler> {
    if (destroyRef?.destroyed) return Promise.reject(new EditActivationCancelled());

    // Create the portal outlet
    const outlet = this.createDomOutlet(container, injector);

    // Create a field handler for the newly active field
    const fieldHandler = new HalResourceEditFieldHandler(
      injector,
      form,
      fieldName,
      schema,
      container,
      this.pathHelper,
      errors,
      destroyRef,
    );

    let released = false;
    let unregister:() => void = () => undefined;
    fieldHandler.onDestroy.pipe(take(1)).subscribe(() => {
      released = true;
      unregister();
      // Disposal detaches the component without destroying the cell itself.
      if (destroyRef?.destroyed) runCleanup(() => outlet.detach());
      else outlet.detach();
    });

    // Construction may synchronously retire the table owner.
    if (destroyRef?.destroyed) {
      fieldHandler.deactivate(false);
      return Promise.reject(new EditActivationCancelled());
    }
    if (destroyRef) unregister = onDestroySafely(destroyRef, () => fieldHandler.deactivate(false));

    // Create an injector that contains injectable reference to the edit field and handler
    const localInjector = createLocalInjector(injector, form.change, fieldHandler, schema);

    // Create a portal for the edit-form/field
    const portal = new ComponentPortal(EditFormPortalComponent, null, localInjector);

    if (released || destroyRef?.destroyed) {
      fieldHandler.deactivate(false);
      return Promise.reject(new EditActivationCancelled());
    }

    // Clear the container
    container.innerHTML = '';

    // Attach the portal to the outlet
    const ref = outlet.attachComponentPortal(portal);

    // Attachment may synchronously release the field before readiness can be observed.
    if (released || destroyRef?.destroyed) {
      fieldHandler.deactivate(false);
      runCleanup(() => outlet.detach());
      return Promise.reject(new EditActivationCancelled());
    }

    const ready = ref.instance.onEditFieldReady.pipe(take(1), takeUntil(fieldHandler.onDestroy));
    return lastValueFrom(ready, { defaultValue: undefined }).then(() => {
      if (released || destroyRef?.destroyed) throw new EditActivationCancelled();
      ref.changeDetectorRef.detectChanges(); // ensure error classes applied in zoneless mode
      return fieldHandler;
    });
  }

  /**
   * Creates a dom outlet for attaching the portal.
   *
   * @param {HTMLElement} hostElement The element where the portal will be attached into
   * @returns {DomPortalOutlet}
   */
  private createDomOutlet(hostElement:HTMLElement, injector:Injector) {
    return new DomPortalOutlet(
      hostElement,
      this.appRef,
      injector,
    );
  }
}
