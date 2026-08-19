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

import { from, Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

export function renderHierarchyItem(item:HalResource, multiple = false):Observable<HTMLSpanElement> {
  const customFieldItemLinks = item.$links as { branch:() => HalResource[] };
  return from(customFieldItemLinks.branch())
    .pipe(
      map((ancestors:CollectionResource) => spansFromAncestors(ancestors)),
      map((spans) => {
        const span = document.createElement('span');
        span.classList.add('path');
        if (multiple) {
          span.classList.add('-multiline');
        }
        spans.forEach((s) => span.appendChild(s));
        return span;
      }),
    );
}

function spansFromAncestors(ancestors:CollectionResource):HTMLSpanElement[] {
  const spans:HTMLSpanElement[] = [];

  ancestors.elements
    .filter((el) => !!el.label)
    .forEach((el, idx, all) => {
      const span = document.createElement('span');
      span.textContent = el.label as string;
      spans.push(span);

      if (idx < all.length - 1) {
        const separator = document.createElement('span');
        separator.textContent = '/';
        spans.push(separator);
      } else if (el.short !== null) {
        const short = document.createElement('span');
        short.textContent = `(${el.short})`;
        short.className = 'color-fg-subtle';
        spans.push(short);
      } else if (el.weight !== null) {
        const weight = document.createElement('span');
        weight.textContent = `(${el.formattedWeight})`;
        weight.className = 'color-fg-subtle';
        spans.push(weight);
      }
    });

  return spans;
}
