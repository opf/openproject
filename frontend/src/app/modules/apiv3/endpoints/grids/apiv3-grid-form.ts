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

import { APIv3FormResource } from "core-app/modules/apiv3/forms/apiv3-form-resource";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { HalPayloadHelper } from "core-app/modules/hal/schemas/hal-payload.helper";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";

export class Apiv3GridForm extends APIv3FormResource {

  /**
   * We need to override the grid widget extraction
   * to pass the correct payload to the API.
   *
   * @param resource
   * @param schema
   */
  public static extractPayload(resource:HalResource|Object, schema:SchemaResource|null = null):Object {
    if (resource instanceof HalResource && schema) {
      const grid = resource as HalResource;
      const payload = HalPayloadHelper.extractPayloadFromSchema(grid, schema);

      // The widget only states the type of the widget resource but does not explain
      // the widget itself. We therefore have to do that by hand.
      if (payload.widgets) {
        payload.widgets = grid.widgets.map((widget:GridWidgetResource) => {
          return {
            id: widget.id,
            startRow: widget.startRow,
            endRow: widget.endRow,
            startColumn: widget.startColumn,
            endColumn: widget.endColumn,
            identifier: widget.identifier,
            options: widget.options
          };
        });
      }

      return payload;
    }

    return resource || {};
  }

  /**
   * Extract payload for the form from the request and optional schema.
   *
   * @param request
   * @param schema
   */
  public extractPayload(request:HalResource|Object, schema:SchemaResource|null = null) {
    return Apiv3GridForm.extractPayload(request, schema);
  }

}
