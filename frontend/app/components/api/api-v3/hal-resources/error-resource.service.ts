//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {HalResource} from './hal-resource.service';
import {opApiModule} from "../../../../angular-modules";

export class ErrorResource extends HalResource {
  public errors:any[];
  public message:string;
  public details:any;
  public errorIdentifier:string;

  public get errorMessages():string[] {
    if (this.isMultiErrorMessage()) {
      return this.errors.map(error => error.message);
    }

    return [this.message];
  }

  public isMultiErrorMessage() {
    return this.errorIdentifier === 'urn:openproject-org:api:v3:errors:MultipleErrors';
  }

  public getInvolvedAttributes():string[] {
    var columns = [];

    if (this.details) {
      columns = [{ details: this.details }]
    }
    else if (this.errors) {
      columns = this.errors;
    }

    return columns.map(field => field.details.attribute);
  }

  public getMessagesPerAttribute():{ [attribute:string]: string[] } {
    let perAttribute = {};

    if (this.details) {
      perAttribute[this.details.attribute] = [this.message];
    }
    else {
      _.forEach(this.errors, error => {
        if (perAttribute[error.details.attribute]) {
          perAttribute[error.details.attribute].push(error.message);
        }
        else {
          perAttribute[error.details.attribute] = [error.message];
        }
      });
    }

    return perAttribute;
  }
}

function errorResourceService() {
  return ErrorResource;
}

opApiModule.factory('ErrorResource', errorResourceService);
