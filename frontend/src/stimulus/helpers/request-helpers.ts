/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { FetchRequest, FetchResponse, Options } from '@rails/request.js';
import { hideElement, showElement } from 'core-app/shared/helpers/dom-helpers';
import invariant from 'tiny-invariant';

export function post(url:string|URL, options?:Options) {
  const request = new FetchRequest('post', url, options);
  return withLoadingIndicator(request.perform());
}

export function withLoadingIndicator(request:Promise<FetchResponse>) {
  const loadingIndicator = document.querySelector<HTMLElement>('#global-loading-indicator');
  invariant(loadingIndicator, 'Expected an Element with id global-loading-indicator to be present');
  showElement(loadingIndicator);

  return request.finally(() => {
    hideElement(loadingIndicator);
  });
}

export class FetchRequestError extends Error {
  constructor(public _errorCode:number, message = 'HTTP Error', options:ErrorOptions = {}) {
    super(message, options);
    this.name = 'FetchRequestError';
  }
}

export class ValidationError extends FetchRequestError {
  constructor(message:string, options:ErrorOptions = {}) {
    super(422, message, options);
    this.name = 'ValidationError';
  }
}
