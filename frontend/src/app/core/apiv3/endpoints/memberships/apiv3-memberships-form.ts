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

import { ApiV3FormResource } from 'core-app/core/apiv3/forms/apiv3-form-resource';
import { MembershipResourceEmbedded } from 'core-app/features/hal/resources/membership-resource';

export class ApiV3MembershipsForm extends ApiV3FormResource {
  /**
   * We need to override the grid widget extraction
   * to pass the correct payload to the API.
   *
   * @param resource
   * @param schema
   */
  public static extractPayload(resource:MembershipResourceEmbedded):Object {
    return {
      _links: {
        project: { href: resource.project.href },
        principal: { href: resource.principal.href },
        roles: resource.roles.map((role) => ({ href: role.href })),
      },
      _meta: {
        notificationMessage: {
          raw: resource.notificationMessage.raw,
        },
      },
    };
  }

  /**
   * Extract payload for the form from the request and optional schema.
   *
   * @param request
   * @param schema
   */
  public extractPayload(request:MembershipResourceEmbedded) {
    return ApiV3MembershipsForm.extractPayload(request);
  }
}
