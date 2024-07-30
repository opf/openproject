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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HttpErrorResponse } from '@angular/common/http';

export const v3ErrorIdentifierQueryInvalid = 'urn:openproject-org:api:v3:errors:InvalidQuery';
export const v3ErrorIdentifierMultipleErrors = 'urn:openproject-org:api:v3:errors:MultipleErrors';
export const v3ErrorIdentifierOutboundRequestForbidden = 'urn:openproject-org:api:v3:errors:OutboundRequest:Forbidden';
export const v3ErrorIdentifierMissingEnterpriseToken = 'urn:openproject-org:api:v3:errors:MissingEnterpriseToken';

export interface IHalErrorBase {
  _type:string;
  message:string;
  errorIdentifier:string;
}

export function isHalError(err:unknown):err is IHalErrorBase {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-return
  const hasOwn = (key:string):boolean => Object.prototype.hasOwnProperty.call(err, key);
  return !!err && hasOwn('_type') && hasOwn('message') && hasOwn('errorIdentifier');
}

export interface IHalSingleError extends IHalErrorBase {
  _embedded:{
    details:{
      attribute:string;
    }
  }
}

export interface IHalMultipleError extends IHalErrorBase {
  _embedded:{
    errors:IHalSingleError[];
  }
}

export class ErrorResource extends HalResource {
  public errors:any[];

  public message:string;

  public details:any;

  public errorIdentifier:string;

  /** We may get a reference to the underlying http error */
  public httpError?:HttpErrorResponse;

  public isValidationError = false;

  /**
   * Override toString to ensure the resource can
   * be printed nicely on console and in errors
   */
  public toString():string {
    return `[ErrorResource ${this.message}]`;
  }

  public get errorMessages():string[] {
    if (this.isMultiErrorMessage()) {
      return this.errors.map((error) => error.message);
    }

    return [this.message];
  }

  public isMultiErrorMessage():boolean {
    return this.errorIdentifier === v3ErrorIdentifierMultipleErrors;
  }

  public getInvolvedAttributes():string[] {
    let columns = [];

    if (this.details) {
      columns = [{ details: this.details }];
    } else if (this.errors) {
      columns = this.errors;
    }

    return _.flatten(columns.map((resource:ErrorResource) => {
      if (resource.errorIdentifier === v3ErrorIdentifierMultipleErrors) {
        return this.extractMultiError(resource)[0];
      }
      return resource.details.attribute;
    }));
  }

  public getMessagesPerAttribute():{ [attribute:string]:string[] } {
    const perAttribute:any = {};

    if (this.details) {
      perAttribute[this.details.attribute] = [this.message];
    } else {
      _.forEach(this.errors, (error:any) => {
        if (error.errorIdentifier === v3ErrorIdentifierMultipleErrors) {
          const [attribute, messages] = this.extractMultiError(error);
          const current = perAttribute[attribute] || [];
          perAttribute[attribute] = current.concat(messages);
        } else if (perAttribute[error.details.attribute]) {
          perAttribute[error.details.attribute].push(error.message);
        } else {
          perAttribute[error.details.attribute] = [error.message];
        }
      });
    }

    return perAttribute;
  }

  protected extractMultiError(resource:ErrorResource):[string, string[]] {
    const { attribute } = resource.errors[0].details;
    const messages = resource.errors.map((el:ErrorResource) => el.message);

    return [attribute, messages];
  }
}
