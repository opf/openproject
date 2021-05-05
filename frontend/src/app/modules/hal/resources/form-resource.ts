//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { HalResource } from 'core-app/modules/hal/resources/hal-resource';

import { SchemaResource } from 'core-app/modules/hal/resources/schema-resource';
import {
  ErrorResource,
  v3ErrorIdentifierMultipleErrors
} from 'core-app/modules/hal/resources/error-resource';

export interface FormResourceLinks<T = HalResource> {
  commit(payload:any):Promise<T>;
}

export interface FormResourceEmbedded {
  schema:SchemaResource;
  validationErrors:{ [attribute:string]:ErrorResource };
}

export class FormResource<T = HalResource> extends HalResource {
  public schema:SchemaResource;
  public validationErrors:{ [attribute:string]:ErrorResource };

  public getErrors():ErrorResource|null {
    const errors = _.values(this.validationErrors);
    const count = errors.length;

    if (count === 0) {
      return null;
    }

    let resource;
    if (count === 1) {
      resource = new ErrorResource(this.injector, errors[0], true, this.halInitializer, 'Error');
    } else {
      resource = new ErrorResource(this.injector, {}, true, this.halInitializer, 'Error');
      resource.errorIdentifier = v3ErrorIdentifierMultipleErrors;
      resource.errors = errors;
    }
    resource.isValidationError = true;
    return resource;
  }
}

export interface FormResource extends FormResourceEmbedded, FormResourceLinks {}
