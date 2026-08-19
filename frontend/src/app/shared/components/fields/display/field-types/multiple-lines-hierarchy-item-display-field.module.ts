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

import { combineLatest, from, Observable } from 'rxjs';
import { switchMap } from 'rxjs/operators';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import {
  ResourcesDisplayField,
} from 'core-app/shared/components/fields/display/field-types/resources-display-field.module';
import { renderHierarchyItem } from 'core-app/shared/components/fields/display/field-types/render-hierarchy-item';

export class MultipleLinesHierarchyItemDisplayField extends ResourcesDisplayField {
  public render(element:HTMLElement, _displayText:string) {
    const items = this.attribute as HalResource[];
    if (items.length === 0) {
      this.renderEmpty(element);
      return;
    }

    element.innerHTML = '';
    element.classList.add('hierarchy-items');
    this.branches(items).subscribe((elements) => {
      elements.forEach((el) => {
        element.appendChild(el);
      });
    });
  }

  public get valueString():string {
    return this.stringValue.join(', ');
  }

  private branches(items:HalResource[]):Observable<HTMLSpanElement[]> {
    return combineLatest(items.map((value:HalResource) => {
      const itemLink = value.$link as HalLink;

      return from(itemLink.$fetch())
        .pipe(
          switchMap((resource:HalResource) => renderHierarchyItem(resource, true)),
        );
    }));
  }
}
