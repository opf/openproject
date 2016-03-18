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

function errorResource(HalResource:typeof op.HalResource, NotificationsService:any) {
  class ErrorResource extends HalResource {
    public errors:any[];
    public message:string;
    public details:any;
    public errorIdentifier:string;

    public get errorMessages():string[] {
      if (this.isMultiErrorMessage()) {
        return this.errors.map(error => error.message);
      } else {
        return [this.message];
      }
    }

    public isMultiErrorMessage() {
      return this.errorIdentifier === 'urn:openproject-org:api:v3:errors:MultipleErrors';
    }

    public showErrorNotification() {
      var messages = this.errorMessages;
      if (messages.length > 1) {
        NotificationsService.addError('', messages);
      } else {
        NotificationsService.addError(messages[0]);
      }
    }

    public getInvolvedColumns():string[] {
      var columns = this.details ? [{ details: this.details }] : this.errors;
      return columns.map(field => field.details.attribute);
    }
  }

  return ErrorResource;
}

angular
  .module('openproject.api')
  .factory('ErrorResource', errorResource);
