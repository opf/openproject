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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import {
  SingleOrMultiSelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/single-or-multi-select-edit-field.component';

/**
 * Edit field for the category collection attribute of work packages.
 *
 * The attribute always reads and writes a collection, but the schema restricts it
 * to a single value (options.multiple) as long as the multiple categories setting
 * is inactive. In that mode the field mimics the single select field it stands in
 * for: an explicit "-" option, no save/cancel controls, saving right on selection.
 *
 * Unlike versions, categories are never shared across projects and cannot be
 * created from within the field, so there is neither grouping nor a create option.
 */
@Component({
  templateUrl: './categories-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CategoriesEditFieldComponent extends SingleOrMultiSelectEditFieldComponent {
}
