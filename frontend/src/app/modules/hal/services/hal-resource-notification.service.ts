// -- copyright
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
// ++

import {ErrorResource} from 'core-app/modules/hal/resources/error-resource';
import {StateService} from '@uirouter/core';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {Injectable, Injector} from '@angular/core';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HttpErrorResponse} from "@angular/common/http";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

@Injectable()
export class HalResourceNotificationService {

  @InjectField() protected I18n:I18nService;
  @InjectField() protected $state:StateService;
  @InjectField() protected halResourceService:HalResourceService;
  @InjectField() protected NotificationsService:NotificationsService;
  @InjectField() protected loadingIndicator:LoadingIndicatorService;

  constructor(public injector:Injector) {
  }

  public showSave(resource:HalResource, isCreate:boolean = false) {
    let message:any = {
      message: this.I18n.t('js.notice_successful_' + (isCreate ? 'create' : 'update')),
    };

    this.NotificationsService.addSuccess(message);
  }

  /**
   * Handle any kind of error response:
   * - HAL ErrorResources
   * - Angular HttpErrorResponses
   * - Older .data error responses
   * - String error messages
   *
   * @param response
   * @param resource
   */
  public handleRawError(response:unknown, resource?:HalResource) {
    console.error("Handling error message %O for work package %O", response, resource);

    // Some transformation may already have returned the error as a HAL resource,
    // which we will forward to handleErrorResponse
    if (response instanceof ErrorResource) {
      return this.handleErrorResponse(response, resource);
    }

    const errorBody = this.retrieveError(response);

    if (errorBody instanceof HalResource) {
      return this.handleErrorResponse(errorBody, resource);
    }

    if (typeof (response) === 'string') {
      this.NotificationsService.addError(response);
      return;
    }

    this.showGeneralError(errorBody || response);
  }

  /**
   * Retrieve an error message string from the given unknown response.
   * @param response
   */
  public retrieveErrorMessage(response:unknown):string {
    const error = this.retrieveError(response);

    if (error instanceof ErrorResource) {
      return error.message;
    }

    if (typeof (error) === 'string') {
      return error;
    }

    return this.I18n.t('js.error.internal');
  }

  public retrieveError(response:unknown):ErrorResource|unknown {
    // we try to detect what we got, this may either be an HttpErrorResponse,
    // some older XHR response object or a string
    let errorBody:any = response;

    // Angular http response have an error body attribute
    if (response instanceof HttpErrorResponse) {
      errorBody = response.message || response.error;
    }

    // Some older response may have a data attribute
    if (_.get(response, 'data._type') === 'Error') {
      errorBody = (response as any).data;
    }

    if (errorBody && errorBody._type === 'Error') {
      return this.halResourceService.createHalResourceOfClass(ErrorResource, errorBody);
    }

    return errorBody;
  }

  protected handleErrorResponse(errorResource:any, resource?:HalResource) {
    if (!(errorResource instanceof ErrorResource)) {
      return this.showGeneralError(errorResource);
    }

    if (resource) {
      return this.showError(errorResource, resource);
    }

    this.showApiErrorMessages(errorResource);
  }

  public showError(errorResource:any, resource:HalResource) {
    this.showCustomError(errorResource, resource) || this.showApiErrorMessages(errorResource);
  }

  public showGeneralError(message?:unknown) {
    let error = this.I18n.t('js.error.internal');

    if (typeof (message) === 'string' || _.has(message, 'toString')) {
      error += ' ' + (message as any).toString();
    }

    this.NotificationsService.addError(error);
  }

  public showEditingBlockedError(attribute:string) {
    this.NotificationsService.addError(this.I18n.t(
      'js.hal.error.edit_prohibited',
      {attribute: attribute}
    ));
  }

  protected showCustomError(errorResource:any, resource:HalResource) {

    if (errorResource.errorIdentifier === 'urn:openproject-org:api:v3:errors:PropertyFormatError') {

      let attributeName = resource.schema[errorResource.details.attribute].name;
      let attributeType = resource.schema[errorResource.details.attribute].type.toLowerCase();
      let i18nString = 'js.hal.error.format.' + attributeType;

      if (this.I18n.lookup(i18nString) === undefined) {
        return false;
      }

      this.NotificationsService.addError(this.I18n.t(i18nString,
        {attribute: attributeName}));

      return true;
    }
    return false;
  }

  protected showApiErrorMessages(errorResource:any) {
    let messages = errorResource.errorMessages;

    if (messages.length > 1) {
      this.NotificationsService.addError('', messages);
    } else {
      this.NotificationsService.addError(messages[0]);
    }

    return true;
  }
}
