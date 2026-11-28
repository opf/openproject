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

import { Component, input } from '@angular/core';
import { JsonPipe } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { WorkPackageEmbeddedTableEntryComponent } from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-table-entry.component';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-embedded-table',
  template: `
    <span class="query-props">{{ queryProps() | json }}</span>
    <span class="configuration">{{ configuration() | json }}</span>
    <span class="loading">{{ initialLoadingIndicator() }}</span>
  `,
  imports: [JsonPipe],
})
class EmbeddedTableStubComponent {
  readonly queryProps = input<unknown>();
  readonly configuration = input<unknown>();
  readonly initialLoadingIndicator = input<unknown>();
}

function rendered(element:HTMLElement, selector:string):unknown {
  return JSON.parse(element.querySelector(selector)?.textContent ?? 'null');
}

describe('WorkPackageEmbeddedTableEntryComponent as a custom element', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [WorkPackageEmbeddedTableEntryComponent],
      imports: [EmbeddedTableStubComponent],
    }).compileComponents();
  });

  it('passes the parsed attributes to the table', async () => {
    const custom = await defineTestCustomElement(WorkPackageEmbeddedTableEntryComponent, {
      'query-props': '{"columns[]":["id","subject"],"showHierarchies":false}',
      configuration: '{"projectContext":false,"actionsColumnEnabled":false}',
      'initial-loading-indicator': 'false',
    });

    expect(rendered(custom.element, '.query-props')).toEqual({ 'columns[]': ['id', 'subject'], showHierarchies: false });
    expect(rendered(custom.element, '.configuration')).toEqual({ projectContext: false, actionsColumnEnabled: false });
    expect(rendered(custom.element, '.loading')).toBe(false);
  });

  it('falls back to empty props and configuration and shows the loading indicator', async () => {
    const custom = await defineTestCustomElement(WorkPackageEmbeddedTableEntryComponent, {});

    expect(rendered(custom.element, '.query-props')).toEqual({});
    expect(rendered(custom.element, '.configuration')).toEqual({});
    expect(rendered(custom.element, '.loading')).toBe(true);
  });

  it('passes changed query props to the table', async () => {
    const custom = await defineTestCustomElement(WorkPackageEmbeddedTableEntryComponent, { 'query-props': '{"page":1}' });

    await custom.set('query-props', '{"page":2}');

    expect(rendered(custom.element, '.query-props')).toEqual({ page: 2 });
  });
});
