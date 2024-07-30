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

/* jshint expr: true */

import { TestBed, waitForAsync } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageViewHierarchyIdentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { of } from 'rxjs';
import SpyObj = jasmine.SpyObj;

describe('WorkPackageViewIndentation service', () => {
  let service:WorkPackageViewHierarchyIdentationService;
  let states:States;
  let querySpace:IsolatedQuerySpace;
  let parentServiceSpy:SpyObj<any>;
  let hierarchyServiceStub:any;

  class HierarchyServiceStub {
    get isEnabled() {
      return true;
    }
  }

  class ApiV3serviceStub {
    work_packages = {
      id: (wpId:string) => ({
        get: () => of(states.workPackages.get(wpId).value),
      }),
    };
  }

  beforeEach(waitForAsync(() => {
    parentServiceSpy = jasmine.createSpyObj(
      'WorkPackageRelationHierarchyService',
      ['changeParent'],
    );

    parentServiceSpy.changeParent.and.returnValue(Promise.resolve());

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        { provide: WorkPackageViewDisplayRepresentationService, useValue: { isList: true } },
        { provide: ApiV3Service, useClass: ApiV3serviceStub },
        { provide: WorkPackageViewHierarchiesService, useClass: HierarchyServiceStub },
        { provide: WorkPackageRelationsHierarchyService, useValue: parentServiceSpy },
        WorkPackageViewHierarchyIdentationService,
      ],
    })
      .compileComponents()
      .then(() => {
        service = TestBed.inject(WorkPackageViewHierarchyIdentationService);
        querySpace = TestBed.inject(IsolatedQuerySpace);
        hierarchyServiceStub = TestBed.inject(WorkPackageViewHierarchiesService);
        states = TestBed.inject(States);
      });
  }));

  describe('canIndent', () => {
    it('Cannot indent without changeParent link', () => {
      const workPackage:any = { id: '1234' };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Cannot indent when is first index', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo' };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can indent as second when it has no ancestors', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      expect(service.canIndent(workPackage)).toBeTruthy();
    });

    it('Cannot indent when possible but hierarchy disabled', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      spyOnProperty(hierarchyServiceStub, 'isEnabled', 'get')
        .and.returnValue(false);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can not indent with a predecessor that is an ancestor already', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['2345'] };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can indent with a predecessor that is NOT an ancestor already', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['2345'] };
      expect(service.canIndent(workPackage)).toBeTruthy();
    });
  });

  describe('canOutdent', () => {
    it('Cannot outdent without changeParent link', () => {
      const workPackage:any = { id: '1234' };
      expect(service.canOutdent(workPackage)).toBeFalsy();
    });

    it('Cannot outdent with changeParent link but disabled', () => {
      const workPackage:any = { id: '1234', changeParent: () => 'foo', parent: { id: '2345' } };

      spyOnProperty(hierarchyServiceStub, 'isEnabled', 'get')
        .and.returnValue(false);

      expect(service.canOutdent(workPackage)).toBeFalsy();
    });

    it('can outdent with changeParent link', () => {
      const workPackage:any = { id: '1234', changeParent: () => 'foo', parent: { id: '2345' } };

      expect(service.canOutdent(workPackage)).toBeTruthy();
    });
  });

  describe('indent', () => {
    it('Can indent with a predecessor that is NOT an ancestor already', (done) => {
      querySpace.tableRendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      const predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: [] };

      states.workPackages.get('2345').putValue(predecessor);

      service.indent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345');
        done();
      });
    });

    it('Can indent with a predecessor that shares an ancestor chain', (done) => {
      querySpace.tableRendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      const predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: ['5555'] };

      states.workPackages.get('2345').putValue(predecessor);

      service.indent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '5555');
        done();
      });
    });

    it('Can indent with a predecessor that shares an ancestor chain', (done) => {
      querySpace.tableRendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['5555'] };
      const predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: ['5555'] };

      states.workPackages.get('2345').putValue(predecessor);

      service.indent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345');
        done();
      });
    });
  });

  describe('outdent', () => {
    it('will outdent to the previous last ancestorId', (done) => {
      querySpace.tableRendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = {
        id: '1234', changeParent: () => 'foo', parent: '5555', ancestorIds: ['2345', '5555'],
      };

      service.outdent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345');
        done();
      });
    });

    it('will outdent to null in case of ancestorIds.length < 2', (done) => {
      querySpace.tableRendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = {
        id: '1234', changeParent: () => 'foo', parent: '2345', ancestorIds: ['2345'],
      };

      service.outdent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, null);
        done();
      });
    });
  });
});
