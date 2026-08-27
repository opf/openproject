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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';

import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { rowGroupClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { locatePredecessorBySelector } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-row-helpers';
import { groupIdentifier } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

export class GroupByDragActionService extends TableDragActionService {
  @LazyInject() wpTableGroupBy:WorkPackageViewGroupByService;

  @LazyInject() halEditing:HalResourceEditingService;

  @LazyInject() halEvents:HalEventsService;

  @LazyInject() halNotification:HalResourceNotificationService;

  @LazyInject() schemaCache:SchemaCacheService;

  public get applies() {
    return this.wpTableGroupBy.isEnabled;
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    const attribute = this.groupedAttribute;
    return attribute !== null && this.schemaCache.of(workPackage).isAttributeEditable(attribute);
  }

  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    const changeset = this.halEditing.changeFor(workPackage);
    const groupedValue = this.getValueForGroup(workPackage, el);

    changeset.projectedResource[this.groupedAttribute!] = groupedValue;
    return this.halEditing
      .save(changeset)
      .then((saved) => this.halEvents.push(saved.resource, { eventType: 'updated' }))
      .catch((e) => this.halNotification.handleRawError(e, workPackage));
  }

  private getValueForGroup(workPackage:WorkPackageResource, el:HTMLElement):unknown {
    const groupHeader = locatePredecessorBySelector(el, `.${rowGroupClassName}`)!;
    const match = this.groups.find((group) => groupIdentifier(group) === groupHeader.dataset.groupIdentifier);

    if (!match) {
      return null;
    }

    if (match._links?.valueLink) {
      const links = match._links.valueLink;
      const schema = this.schemaCache.state(workPackage).value;
      const fieldSchema = schema && this.schemaCache.proxied(workPackage, schema).ofProperty(this.groupedAttribute!);

      if (fieldSchema?.type?.startsWith('[]')) {
        return links;
      }

      // Unwrap single links to properly use them
      return links.length === 1 ? links[0] : links;
    }
    return match.value;
  }

  /**
   * Get the attribute we're grouping by
   */
  private get groupedAttribute():string|null {
    const { current } = this.wpTableGroupBy;
    return current ? current.id : null;
  }

  /**
   * Returns the reference to the last table.groups state value
   */
  public get groups() {
    return this.querySpace.groups.value || [];
  }
}
