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

import { Injectable } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Observable, of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { BoardListsService } from 'core-app/features/boards/board/board-list/board-lists.service';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

@Injectable()
class VersionActionService extends BoardActionService {
  filterName = 'version';

  protected require(id:string):Promise<HalResource> {
    return Promise.reject(new Error(`Unexpected load of ${id}`));
  }

  protected loadValues():Observable<HalResource[]> {
    return of([]);
  }
}

describe('BoardActionService', () => {
  let service:BoardActionService;

  function queryFilteredBy(id:string, ...values:unknown[]) {
    return { filters: [{ id, values }] } as unknown as QueryResource;
  }

  function versionResource() {
    const version = Object.create(HalResource.prototype) as HalResource;
    version.$source = { id: 3, _links: { self: { href: '/api/v3/versions/3' } } };
    version.$links = { self: { $link: { href: '/api/v3/versions/3' } } } as unknown as HalResource['$links'];

    return version;
  }

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        VersionActionService,
        { provide: BoardListsService, useValue: {} },
        { provide: I18nService, useValue: {} },
        { provide: HalResourceService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
      ],
    });

    service = TestBed.inject(VersionActionService);
  });

  describe('getActionValueId', () => {
    it('returns nothing without the action filter', () => {
      expect(service.getActionValueId(queryFilteredBy('status', '1'))).toBeUndefined();
    });

    it('returns nothing when the action filter has no value', () => {
      expect(service.getActionValueId(queryFilteredBy('version'))).toBeUndefined();
    });

    it('returns the id of a resource', () => {
      expect(service.getActionValueId(queryFilteredBy('version', versionResource()))).toBe('3');
    });

    it('returns the href of a resource when asked for it', () => {
      expect(service.getActionValueId(queryFilteredBy('version', versionResource()), true)).toBe('/api/v3/versions/3');
    });

    it('returns a plain id as a string', () => {
      expect(service.getActionValueId(queryFilteredBy('version', '5'))).toBe('5');
      expect(service.getActionValueId(queryFilteredBy('version', 5))).toBe('5');
    });

    it('returns the id of a reference', () => {
      expect(service.getActionValueId(queryFilteredBy('version', { id: 5 }))).toBe('5');
    });

    it('derives the id from the href of a reference that has no id', () => {
      expect(service.getActionValueId(queryFilteredBy('version', { href: '/api/v3/versions/7' }))).toBe('7');
    });

    it('returns the href of a reference when asked for it', () => {
      expect(service.getActionValueId(queryFilteredBy('version', { href: '/api/v3/versions/7' }), true))
        .toBe('/api/v3/versions/7');
    });
  });
});
