//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GlobalSearchService} from "core-app/modules/global_search/services/global-search.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {async, TestBed} from "@angular/core/testing";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {States} from "core-components/states.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageViewHierarchyIdentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service";
import SpyObj = jasmine.SpyObj;
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {WorkPackageDmService} from "core-app/modules/hal/dm-services/work-package-dm.service";

describe('WorkPackageViewIndentation service', function() {
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

  class WorkPackageCacheServiceStub {
    require(wpId:string) {
      return Promise.resolve(states.workPackages.get(wpId).value);
    }
  }

  beforeEach(async(() => {
    parentServiceSpy = jasmine.createSpyObj(
      'WorkPackageRelationHierarchyService',
      ['changeParent']
    );

    parentServiceSpy.changeParent.and.returnValue(Promise.resolve());

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        WorkPackageCacheService,
        { provide: WorkPackageCacheService, useClass: WorkPackageCacheServiceStub },
        { provide: WorkPackageViewHierarchiesService, useClass: HierarchyServiceStub },
        { provide: WorkPackageRelationsHierarchyService, useValue: parentServiceSpy  },
        WorkPackageViewHierarchyIdentationService
      ]
    })
    .compileComponents()
    .then(() => {
      service = TestBed.get(WorkPackageViewHierarchyIdentationService);
      querySpace = TestBed.get(IsolatedQuerySpace);
      hierarchyServiceStub = TestBed.get(WorkPackageViewHierarchiesService);
      states = TestBed.get(States);
    });
  }));

  describe('canIndent', () => {
    it('Cannot indent without changeParent link', () => {
      let workPackage:any = { id: '1234' };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Cannot indent when is first index', () => {
      querySpace.rendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo' };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can indent as second when it has no ancestors', () => {
      querySpace.rendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      expect(service.canIndent(workPackage)).toBeTruthy();
    });

    it('Cannot indent when possible but hierarchy disabled', () => {
      querySpace.rendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      spyOnProperty(hierarchyServiceStub, 'isEnabled', 'get')
        .and.returnValue(false);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can not indent with a predecessor that is an ancestor already', () => {
      querySpace.rendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['2345'] };
      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can indent with a predecessor that is NOT an ancestor already', () => {
      querySpace.rendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['2345'] };
      expect(service.canIndent(workPackage)).toBeTruthy();
    });
  });

  describe('canOutdent', () => {
    it('Cannot outdent without changeParent link', () => {
      let workPackage:any = { id: '1234' };
      expect(service.canOutdent(workPackage)).toBeFalsy();
    });

    it('Cannot outdent with changeParent link but disabled', () => {
      let workPackage:any = { id: '1234', changeParent: () => 'foo', parent: { id: '2345' } };

      spyOnProperty(hierarchyServiceStub, 'isEnabled', 'get')
        .and.returnValue(false);

      expect(service.canOutdent(workPackage)).toBeFalsy();
    });

    it('can outdent with changeParent link', () => {
      let workPackage:any = { id: '1234', changeParent: () => 'foo', parent: { id: '2345' } };

      expect(service.canOutdent(workPackage)).toBeTruthy();
    });
  });

  describe('indent', () => {
    it('Can indent with a predecessor that is NOT an ancestor already', (done) => {
      querySpace.rendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      let predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: [] };

      states.workPackages.get('2345').putValue(predecessor);

      service.indent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345');
        done();
      });
    });

    it('Can indent with a predecessor that shares an ancestor chain', (done) => {
      querySpace.rendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      let predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: ['5555'] };

      states.workPackages.get('2345').putValue(predecessor);

      service.indent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '5555');
        done();
      });
    });

    it('Can indent with a predecessor that shares an ancestor chain', (done) => {
      querySpace.rendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' }
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['5555'] };
      let predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: ['5555'] };

      states.workPackages.get('2345').putValue(predecessor);

      service.indent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345');
        done();
      });
    });
  });

  describe('outdent', () => {
    it('will outdent to the previous last ancestorId', (done) => {
      querySpace.rendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', parent: '5555', ancestorIds: ['2345', '5555'] };

      service.outdent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345');
        done();
      });
    });

    it('will outdent to null in case of ancestorIds.length < 2', (done) => {
      querySpace.rendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      let workPackage:any = { id: '1234', changeParent: () => 'foo', parent: '2345', ancestorIds: ['2345'] };

      service.outdent(workPackage).then(() => {
        expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, null);
        done();
      });
    });
  });
});
