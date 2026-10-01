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

import { ApiV3FormResource } from 'core-app/core/apiv3/forms/apiv3-form-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { Observable } from 'rxjs';
import { HalSource } from 'core-app/features/hal/interfaces';

export class ApiV3WorkPackageForm extends ApiV3FormResource {
  /**
   * Returns a promise to post `/api/v3/work_packages/form` with only the type part of the
   * provided payload being sent to the backend.
   *
   * @param payload: The payload to be sent to the backend
   * @returns A work package form resource prefilled with the provided payload.
   */
  public forTypePayload(payload:HalSource):Observable<FormResource> {
    const typePayload = payload._links.type ? { _links: { type: payload._links.type } } : { _links: {} };

    return this.post(payload);
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form` where the
   * payload sent to the backend has been provided.
   *
   * @param payload: The payload to be sent to the backend
   * @returns A work package form resource prefilled with the provided payload.
   */
  public forPayload(payload:Partial<HalSource>):Observable<FormResource> {
    return this.post(payload);
  }
}
