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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { escape } from 'lodash-es';
import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { rowGroupClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { groupByProperty, groupName } from './grouped-rows-helpers';
import { ProjectPhaseDisplayField } from 'core-app/shared/components/fields/display/field-types/project-phase-display-field.module';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

export function groupClassNameFor(group:GroupObject) {
  return `group-${group.identifier}`;
}

export class GroupHeaderBuilder {
  @LazyInject() public I18n:I18nService;

  @LazyInject() public timezoneService:TimezoneService;

  @LazyInject() public querySpace:IsolatedQuerySpace;

  public text:{ collapse:string, expand:string };

  constructor(public readonly injector:Injector) {
    this.text = {
      collapse: this.I18n.t('js.label_collapse'),
      expand: this.I18n.t('js.label_expand'),
    };
  }

  public buildGroupRow(group:GroupObject, colspan:number) {
    const row = document.createElement('tr');
    let togglerIconClass;
    let text;

    if (group.collapsed) {
      text = this.text.expand;
      togglerIconClass = 'icon-plus';
    } else {
      text = this.text.collapse;
      togglerIconClass = 'icon-minus2';
    }

    const leadingIcon = this.leadingIcon(group);
    const groupTitle = escape(this.groupTitle(group));

    row.classList.add(rowGroupClassName, groupClassNameFor(group));
    row.id = `wp-table-rowgroup-${group.index}`;
    row.dataset.groupIndex = (group.index).toString();
    row.dataset.groupIdentifier = group.identifier;
    row.innerHTML = `
      <td colspan="${colspan}" class="-no-highlighting">
        <div class="expander icon-context ${togglerIconClass}">
          <span class="sr-only">${escape(text)}</span>
        </div>
        <div class="group--value" data-test-selector="op-group--value">
          ${leadingIcon ? leadingIcon.outerHTML : ''}
          ${groupTitle}
          <span class="count">
            (${group.count})
          </span>
        </div>
      </td>
    `;

    return row;
  }

  private groupTitle(group:GroupObject):string {
    const name = groupName(group) as unknown;

    if (group.value !== null && typeof name === 'string' && this.groupedPropertyType(group) === 'DateTime') {
      return this.timezoneService.formattedDatetime(name);
    }

    return name as string;
  }

  /**
   * Returns the schema type of the attribute the results are grouped by, e.g. `DateTime`
   * for a datetime custom field. Looked up in the schemas embedded in the results, as a
   * custom field might not be active in all of them.
   */
  private groupedPropertyType(group:GroupObject):string|undefined {
    const property = groupByProperty(group);
    const schemas = this.querySpace.results.value?.schemas?.elements ?? [];

    for (const schema of schemas) {
      const fieldSchema = schema[property] as IFieldSchema|undefined;
      if (fieldSchema?.type) {
        return fieldSchema.type;
      }
    }

    return undefined;
  }

  /**
   * Returns a leading icon to be rendered in front of the group, if applicable. Will use the hrefs of the group
   * to determine whether there is a known icon for this type or not.
   * @param group the group object to check for a leading icon.
   * @private
   */
  private leadingIcon(group:GroupObject) {
    // will also match project phase definitions
    const groupLink = group.href.find(
      (item) =>item.href?.includes('api/v3/project_phase')
    );

    if (groupLink) {
      const definitionId = idFromLink(groupLink.href);
      return ProjectPhaseDisplayField.phaseIconById(definitionId, false);
    }

    return null;
  }
}
