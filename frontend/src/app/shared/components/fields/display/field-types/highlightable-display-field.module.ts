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

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export class HighlightableDisplayField extends DisplayField {
  /** Optionally test if we can inject highlighting service */
  @InjectField(WorkPackageViewHighlightingService, null) viewHighlighting:WorkPackageViewHighlightingService;

  // DisplayFieldRenderer.attributeName returns the 'date' name for the
  // 'dueDate' field because it is its schema.mappedName (that allows to display
  // the correct input type). In the query.highlightedAttributes (used to decide
  // if a field is highlighted) the attribute has the name 'dueDate', so we need
  // to return the original name to get it highlighted.
  get highlightName() {
    if (this.name === 'date') {
      return 'dueDate';
    }
    return this.name;
  }

  public get shouldHighlight() {
    if (this.context.options.colorize === false) {
      return false;
    }

    const shouldHighlight = !!this.viewHighlighting && this.viewHighlighting.shouldHighlightInline(this.highlightName);

    return this.context.container !== 'table' || shouldHighlight;
  }
}
