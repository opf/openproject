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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { formatWorkPackageId } from 'core-app/shared/helpers/work-package-id-pattern';

export class WorkPackageDisplayField extends DisplayField {
  public text = {
    none: this.I18n.t('js.filter.noneElement'),
  };

  public get value() {
    return this.resource[this.name];
  }

  public get title() {
    if (this.isEmpty()) {
      return this.text.none;
    }
    return this.value.name;
  }

  public get wpId() {
    if (this.isEmpty()) {
      return null;
    }

    if (this.value.$loaded) {
      return this.value.id;
    }

    return this.value.href.match(/(\d+)$/)[0];
  }

  /**
   * Returns the identifier for URL routing.
   * Reads `displayId` from the linked resource whether or not it is fully
   * loaded — the API now includes `displayId` on HAL link objects (e.g.
   * the parent link), so `WorkPackageResource#displayId` resolves
   * correctly from `$source._links.self.displayId` even for stubs.
   */
  public get wpRoutingId():string {
    const linkedWp = this.value as WorkPackageResource | undefined;
    if (linkedWp) {
      return linkedWp.displayId;
    }
    return (this.wpId as string | null) ?? '';
  }

  /**
   * Returns the work package ID formatted for display.
   * Classic mode: `#123` (hash-prefixed), Semantic mode: `PROJ-42` (no prefix).
   *
   * Delegates to `WorkPackageResource#formattedId` for both loaded and
   * unloaded stubs. The API includes `displayId` on HAL link objects so
   * `formattedId` resolves the semantic identifier without a fetch.
   */
  public get wpFormattedId():string {
    const linkedWp = this.value as WorkPackageResource | undefined;
    if (linkedWp) {
      return linkedWp.formattedId;
    }

    const id = this.wpId as string | number | null;
    if (!id) return '';

    return formatWorkPackageId(String(id));
  }

  public get valueString() {
    // cannot display the type name easily here as it may not be loaded
    return `${this.wpFormattedId} ${this.title}`;
  }

  public isEmpty():boolean {
    return !this.value;
  }

  public get unknownAttribute():boolean {
    return false;
  }
}
