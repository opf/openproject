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

import { provideHttpClient } from '@angular/common/http';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { BooleanDisplayField } from 'core-app/shared/components/fields/display/field-types/boolean-display-field.module';
import { IntegerDisplayField } from 'core-app/shared/components/fields/display/field-types/integer-display-field.module';
import { LinkDisplayField } from 'core-app/shared/components/fields/display/field-types/link-display-field.module';
import { HighlightedResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/highlighted-resource-display-field.module';
import { TypeDisplayField } from 'core-app/shared/components/fields/display/field-types/type-display-field.module';
import { ResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/resource-display-field.module';

export type WideProfile = 'simple8'|'mixed10';

export function wideFixture(profile:WideProfile) {
  const columns = profile === 'simple8'
    ? ['id', 'subject', 'customField1', 'customField2', 'customField3', 'customField4', 'customField5', 'customField6']
    : ['id', 'subject', 'status', 'type', 'priority', 'project', 'customField1', 'customField5', 'customField6', 'customField7'];
  const types:Record<string, string> = {
    id: 'Integer', subject: 'String', status: 'Status', type: 'Type', priority: 'Priority', project: 'Project',
    customField1: 'String', customField2: 'String', customField3: 'String', customField4: 'String',
    customField5: 'Integer', customField6: 'Boolean', customField7: 'Link',
  };
  const properties = Object.fromEntries(columns.map((name) => [name, { type: types[name], name, writable: false, required: false }]));
  const schema = {
    ofProperty: (name:string) => properties[name],
    mappedName: (name:string) => name,
    availableAttributes: columns,
    isAttributeEditable: () => false,
  };
  let linked:Record<'status'|'type'|'priority'|'project', HalResource>;
  let highlightedAttributes:HalResource[] = [];
  const attributes = (index:number) => ({
    ...linked,
    customField1: `Team ${index % 5}`,
    customField2: `Region ${index % 3}`,
    customField3: `Category ${index % 7}`,
    customField4: `Release ${index % 4}`,
    customField5: index + 1,
    customField6: index % 2 === 0,
    customField7: `https://example.test/work/${index + 1}`,
  });

  return {
    columns,
    attributes,
    get highlightedAttributes() { return highlightedAttributes; },
    providers: [
      provideHttpClient(),
      { provide: HalResourceService, useClass: HalResourceService },
      { provide: SchemaCacheService, useValue: { state: () => ({ value: {} }), of: () => schema } },
    ],
    initialize(hal:HalResourceService) {
      const resource = (type:string, path:string, id:number, name:string) => hal.createHalResource({
        _type: type, id, name, _links: { self: { href: `/api/v3/${path}/${id}` } },
      });
      linked = {
        status: resource('Status', 'statuses', 1, 'Open'),
        type: resource('Type', 'types', 1, 'Task'),
        priority: resource('Priority', 'priorities', 2, 'Normal'),
        project: resource('Project', 'projects', 1, 'Benchmark project'),
      };
      highlightedAttributes = profile === 'mixed10' ? ['status', 'priority'].map((id) => hal.createHalResource({
        _type: 'QueryColumn', id, _links: { self: { href: `/api/v3/queries/columns/${id}` } },
      })) : [];
      if (Object.values(linked).some((value) => !(value instanceof HalResource))) throw new Error('Expected real HAL fixtures');
    },
    register(fields:DisplayFieldService) {
      fields.addFieldType(IntegerDisplayField, 'integer', ['Integer']);
      fields.addFieldType(BooleanDisplayField, 'boolean', ['Boolean']);
      fields.addFieldType(LinkDisplayField, 'link', ['Link']);
      fields.addFieldType(HighlightedResourceDisplayField, 'highlight', ['Status', 'Priority']);
      fields.addFieldType(TypeDisplayField, 'type', ['Type']);
      fields.addFieldType(ResourceDisplayField, 'resource', ['Project']);
    },
    assertRow(row:HTMLTableRowElement, index:number, subject:string) {
      if (row.cells.length !== columns.length) throw new Error(`Expected ${columns.length} cells, got ${row.cells.length}`);
      const values = attributes(index);
      const expected:Record<string, string> = {
        id: String(index + 1), subject, status: 'Open', type: 'Task', priority: 'Normal', project: 'Benchmark project',
        customField1: values.customField1, customField2: values.customField2, customField3: values.customField3,
        customField4: values.customField4, customField5: String(values.customField5),
        customField6: values.customField6 ? 'js.general_text_yes' : 'js.general_text_no', customField7: values.customField7,
      };
      columns.forEach((column, cellIndex) => {
        if (row.cells[cellIndex].textContent?.trim() !== expected[column]) {
          throw new Error(`Incorrect ${column} value: ${row.cells[cellIndex].textContent}`);
        }
      });
      if (profile === 'mixed10') {
        for (const [selector, treatment] of [
          ['.__hl_status_1', '__hl_dot'], ['.__hl_priority_2', '__hl_dot'], ['.__hl_type_1', '__hl_foreground'],
        ]) {
          if (!row.querySelector(selector)?.classList.contains(treatment)) throw new Error(`Missing ${selector} highlighting`);
        }
        if (!row.querySelector('.__hl_type_1')?.classList.contains('__hl_uppercase')) throw new Error('Missing type treatment');
        const link = row.querySelector<HTMLAnchorElement>('.customField7 a');
        if (link?.href !== values.customField7 || link.target !== '_blank') throw new Error('Missing specialized link field');
        if (!link.relList.contains('noopener') || !link.relList.contains('noreferrer')) {
          throw new Error('Missing link security attributes');
        }
      }
    },
  };
}
