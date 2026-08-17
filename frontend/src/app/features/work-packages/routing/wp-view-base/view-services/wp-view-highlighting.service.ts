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

import { isEqual } from 'lodash-es';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Injectable, inject } from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { QuerySchemaResource } from 'core-app/features/hal/resources/query-schema-resource';
import {
  WorkPackageViewHighlight,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-table-highlight';
import { WorkPackageQueryStateService } from './wp-view-base.service';

@Injectable()
export class WorkPackageViewHighlightingService extends WorkPackageQueryStateService<WorkPackageViewHighlight> {
  readonly states = inject(States);
  readonly Banners = inject(BannersService);

  initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource) {
    super.initialize(query, results, schema);
  }

  /**
   * Decides whether we want to inline highlight the given field name.
   *
   * @param name A display field name such as 'status', 'priority'.
   */
  public shouldHighlightInline(name:string):boolean {
    // 1. Are we in inline mode or unable to render?
    if (!this.isInline) {
      return false;
    }

    // 2. Is selected attributes === undefined or empty Array?
    if (this.current.selectedAttributes?.length === 0) {
      return true;
    }

    // 3. Is name in selected attributes ?
    return this.current.selectedAttributes?.some((attr:HalResource) => attr.id === name) ?? false;
  }

  public get current():WorkPackageViewHighlight {
    const value = this.lastUpdatedState.getValueOr({ mode: 'inline' } as WorkPackageViewHighlight); // eslint-disable-line @typescript-eslint/no-unnecessary-type-assertion
    return this.filteredValue(value);
  }

  public get isInline() {
    return this.current.mode === 'inline';
  }

  public get isDisabled() {
    return this.current.mode === 'none';
  }

  public update(value:WorkPackageViewHighlight) {
    super.update(this.filteredValue(value));
  }

  public valueFromQuery(query:QueryResource):WorkPackageViewHighlight {
    const highlight = { mode: query.highlightingMode || 'inline', selectedAttributes: query.highlightedAttributes };
    return this.filteredValue(highlight);
  }

  public hasChanged(query:QueryResource) {
    return query.highlightingMode !== this.current.mode
      || !isEqual(query.highlightedAttributes, this.current.selectedAttributes);
  }

  public applyToQuery(query:QueryResource):boolean {
    const { current } = this;
    query.highlightingMode = current.mode;

    query.highlightedAttributes = current.selectedAttributes;

    return false;
  }

  private filteredValue(value:WorkPackageViewHighlight):WorkPackageViewHighlight {
    if (!value.selectedAttributes?.length) {
      value.selectedAttributes = undefined;
    }

    return value;
  }
}
