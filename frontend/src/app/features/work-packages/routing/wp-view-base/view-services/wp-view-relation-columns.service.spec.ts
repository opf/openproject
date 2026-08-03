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

import { TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import {
  RelationsStateValue,
  WorkPackageRelationsService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { QueryColumn, queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageViewColumnsService } from './wp-view-columns.service';
import { WorkPackageViewRelationColumnsService } from './wp-view-relation-columns.service';

describe('WorkPackageViewRelationColumnsService', () => {
  let service:WorkPackageViewRelationColumnsService;

  const rootTypeHref = '/api/v3/types/1';
  const variantTypeHref = '/api/v3/types/2';
  const otherTypeHref = '/api/v3/types/3';

  // The work package a relation points to, as the table has it cached
  const targets:Record<string, { type:{ href:string } }> = {
    'of-root-type': { type: { href: rootTypeHref } },
    'of-variant-type': { type: { href: variantTypeHref } },
    'of-other-type': { type: { href: otherTypeHref } },
  };

  class ApiV3ServiceStub {
    work_packages = {
      cache: {
        state: (id:string) => ({ value: targets[id] }),
      },
    };
  }

  function relationTo(targetId:string) {
    return { denormalized: () => ({ targetId, relationType: 'relates' }) };
  }

  function columnFor(typeHrefs:string[]):QueryColumn {
    return {
      _type: queryColumnTypes.RELATION_TO_TYPE,
      id: 'relationsToType1',
      name: 'Relations to Bug',
      type: { href: typeHrefs[0], name: 'Bug' },
      types: typeHrefs.map((href) => ({ href })),
    } as unknown as QueryColumn;
  }

  const relations = {
    1: relationTo('of-root-type'),
    2: relationTo('of-variant-type'),
    3: relationTo('of-other-type'),
  };
  const relationsState = relations as unknown as RelationsStateValue;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        { provide: ApiV3Service, useClass: ApiV3ServiceStub },
        { provide: HalResourceService, useValue: {} },
        { provide: WorkPackageRelationsService, useValue: {} },
        { provide: WorkPackageViewColumnsService, useValue: {} },
        WorkPackageViewRelationColumnsService,
      ],
    }).compileComponents();

    service = TestBed.inject(WorkPackageViewRelationColumnsService);
  });

  describe('relationsForColumn', () => {
    const workPackage = { id: '42' } as unknown as WorkPackageResource;

    function relationsFor(typeHrefs:string[]) {
      return service.relationsForColumn(workPackage, relationsState, columnFor(typeHrefs));
    }

    it('counts relations to the type the column is named after', () => {
      expect(relationsFor([rootTypeHref])).toEqual([relations[1]]);
    });

    // A project runs a single member of a type family and its work packages carry that
    // member, while the column is named after the type users see.
    it('counts relations to a variant of that type', () => {
      expect(relationsFor([rootTypeHref, variantTypeHref]))
        .toEqual([relations[1], relations[2]]);
    });

    it('leaves relations to another type out', () => {
      expect(relationsFor([rootTypeHref, variantTypeHref])).not.toContain(relations[3]);
    });

    it('falls back to the single type when the column carries no family', () => {
      const column = { ...columnFor([rootTypeHref]), types: undefined } as unknown as QueryColumn;

      expect(service.relationsForColumn(workPackage, relationsState, column))
        .toEqual([relations[1]]);
    });
  });
});
