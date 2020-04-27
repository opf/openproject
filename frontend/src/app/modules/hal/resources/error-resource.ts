//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {HttpErrorResponse} from "@angular/common/http";

export const v3ErrorIdentifierQueryInvalid = 'urn:openproject-org:api:v3:errors:InvalidQuery';
export const v3ErrorIdentifierMultipleErrors = 'urn:openproject-org:api:v3:errors:MultipleErrors';

export class ErrorResource extends HalResource {
  public errors:any[];
  public message:string;
  public details:any;
  public errorIdentifier:string;

  /** We may get a reference to the underlying http error */
  public httpError?:HttpErrorResponse;

  public isValidationError:boolean = false;

  /**
   * Override toString to ensure the resource can
   * be printed nicely on console and in errors
   */
  public toString() {
    return `[ErrorResource ${this.message}]`;
  }

  public get errorMessages():string[] {
    if (this.isMultiErrorMessage()) {
      return this.errors.map(error => error.message);
    }

    return [this.message];
  }

  public isMultiErrorMessage() {
    return this.errorIdentifier === v3ErrorIdentifierMultipleErrors;
  }

  public getInvolvedAttributes():string[] {
    var columns = [];

    if (this.details) {
      columns = [{ details: this.details }];
    }
    else if (this.errors) {
      columns = this.errors;
    }

    return _.flatten(columns.map((resource:ErrorResource) => {
      if (resource.errorIdentifier === v3ErrorIdentifierMultipleErrors) {
        return this.extractMultiError(resource)[0];
      } else {
        return resource.details.attribute;
      }
    }));
  }

  public getMessagesPerAttribute():{ [attribute:string]:string[] } {
    let perAttribute:any = {};

    if (this.details) {
      perAttribute[this.details.attribute] = [this.message];
    }
    else {
      _.forEach(this.errors, (error:any) => {
        if (error.errorIdentifier === v3ErrorIdentifierMultipleErrors) {
          const [attribute, messages] = this.extractMultiError(error);
          let current = perAttribute[attribute] || [];
          perAttribute[attribute] = current.concat(messages);
        } else if (perAttribute[error.details.attribute]) {
          perAttribute[error.details.attribute].push(error.message);
        }
        else {
          perAttribute[error.details.attribute] = [error.message];
        }
      });
    }

    return perAttribute;
  }

  protected extractMultiError(resource:ErrorResource):[string, string[]] {
    let attribute = resource.errors[0].details.attribute;
    let messages = resource.errors.map((el:ErrorResource) => el.message);

    return [attribute, messages];
  }
}
