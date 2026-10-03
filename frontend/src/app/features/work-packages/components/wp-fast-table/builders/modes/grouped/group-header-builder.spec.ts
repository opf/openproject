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

import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { GroupHeaderBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/group-header-builder';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

describe('GroupHeaderBuilder', () => {
  let builder:GroupHeaderBuilder;
  let groupedType:string|null;

  function group(value:unknown):GroupObject {
    return {
      value,
      count: 2,
      index: 0,
      identifier: 'customField1-x',
      sums: {},
      href: [],
      _links: { valueLink: [], groupBy: { href: '/api/v3/queries/group_bys/customField1' } },
    };
  }

  function title(value:unknown):string {
    const row = builder.buildGroupRow(group(value), 3);

    const valueElement = row.querySelector('.group--value')!;
    valueElement.querySelector('.count')!.remove();

    return valueElement.textContent.trim();
  }

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        {
          provide: IsolatedQuerySpace,
          useValue: {
            results: {
              get value() {
                // The custom field is not active in the first schema, so it has to look further.
                const schemas = [
                  { subject: { type: 'String' } },
                  { customField1: groupedType ? { type: groupedType } : undefined },
                ];

                return { schemas: { elements: schemas } };
              },
            },
          },
        },
        {
          provide: ConfigurationService,
          useValue: {
            isTimezoneSet: () => true,
            timezone: () => 'Europe/Brussels',
            dateFormatPresent: () => true,
            dateFormat: () => 'YYYY-MM-DD',
            timeFormatPresent: () => true,
            timeFormat: () => 'HH:mm',
          },
        },
      ],
    });

    groupedType = null;
    builder = new GroupHeaderBuilder(TestBed.inject(Injector));
  });

  describe('when grouped by a datetime custom field', () => {
    beforeEach(() => {
      groupedType = 'DateTime';
    });

    it('shows the UTC value in the user time zone', () => {
      expect(title('2026-10-01T12:30:00.000Z')).toEqual('2026-10-01 14:30');
    });

    it('shows a dash for groups without a value', () => {
      expect(title(null)).toEqual('-');
    });
  });

  describe('when grouped by a string custom field', () => {
    beforeEach(() => {
      groupedType = 'String';
    });

    it('keeps a value looking like a UTC datetime as it is', () => {
      expect(title('2026-10-01T12:30:00.000Z')).toEqual('2026-10-01T12:30:00.000Z');
    });

    it('keeps other values as they are', () => {
      expect(title('2026-10-01')).toEqual('2026-10-01');
      expect(title('High')).toEqual('High');
    });
  });

  describe('when the type of the grouped attribute is unknown', () => {
    it('keeps the value as it is', () => {
      expect(title('2026-10-01T12:30:00.000Z')).toEqual('2026-10-01T12:30:00.000Z');
    });

    it('shows a dash for groups without a value', () => {
      expect(title(null)).toEqual('-');
    });
  });

  it('escapes the value', () => {
    const row = builder.buildGroupRow(group('<b>bold</b>'), 3);

    expect(row.querySelector('b')).toBeNull();
  });
});
