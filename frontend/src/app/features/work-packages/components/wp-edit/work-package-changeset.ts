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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageSchemaProxy } from 'core-app/features/hal/schemas/work-package-schema-proxy';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

export class WorkPackageChangeset extends ResourceChangeset<WorkPackageResource> {
  public setValue(key:string, val:any) {
    super.setValue(key, val);

    if (key === 'project' || key === 'type') {
      this.updateForm();
    }

    // Emit event to notify Stimulus controller in activities tab in order to update the activities list
    // TODO: emit event when change is persisted
    // currently the event might be fired too early as it only reflects the client side change
    document.dispatchEvent(
      new CustomEvent('work-package-updated'),
    );
  }

  protected applyChanges(payload:any):any {
    // Explicitly delete the description if it was not set by the user.
    // if it was set by the user, #applyChanges will set it again.
    // Otherwise, the backend will set it for us.
    delete payload.description;

    // Explicitly not send the subject, if the subject was not editable.
    // In this case a generated template is rendered in the subject and
    // must not get submitted.
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    if (!this.schema.isAttributeEditable('subject')) {
      delete (payload as { subject?:string }).subject;
    }

    // Explicitly exclude the version collections if they are empty
    if (isNewResource(this.pristineResource)) {
      const links = (payload as { _links?:Record<string, unknown> })._links;

      if (links) {
        ['targetVersions', 'observedInVersions'].forEach((attribute) => {
          const value = links[attribute];

          if (!Array.isArray(value) || value.length === 0) {
            delete links[attribute];
          }
        });
      }
    }

    return super.applyChanges(payload);
  }

  protected setNewDefaultFor(key:string, val:unknown) {
    // Special handling for taking over the description and
    // the subject to the pristine resource.
    if (key === 'description' && isNewResource(this.pristineResource)) {
      this.pristineResource.description = val;
      return;
    }

    if (key === 'subject' && isNewResource(this.pristineResource)) {
      this.pristineResource.subject = val as string;
      return;
    }

    super.setNewDefaultFor(key, val);
  }

  /**
   * Get the best schema currently available, either the default resource schema (must exist).
   * If loaded, return the form schema, which provides better information on writable status
   * and contains available values.
   */
  public get schema():SchemaResource {
    if (this.form$.hasValue()) {
      return WorkPackageSchemaProxy.create(super.schema, this.projectedResource);
    }
    return super.schema;
  }
}
