// -- copyright
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
// ++

import {WorkPackageCacheService} from "./work-package-cache.service";
import {WorkPackageResource} from "../api/api-v3/hal-resources/work-package-resource.service";


describe('WorkPackageCacheService', () => {

  let wpCacheService: WorkPackageCacheService;
  let WorkPackageResource;
  let dummyWorkPackages: WorkPackageResource[] = [];

  beforeEach(angular.mock.module('openproject'));

  beforeEach(angular.mock.inject((_wpCacheService_, _WorkPackageResource_) => {
    wpCacheService = _wpCacheService_;
    WorkPackageResource = _WorkPackageResource_;

    // dummy 1
    const workPackage1 = new _WorkPackageResource_({_links: {self: ""}});
    workPackage1.id = 1;

    dummyWorkPackages = [workPackage1];
  }));

  it('should return a work package after the list has been initialized', () => {
    wpCacheService.updateWorkPackageList(dummyWorkPackages);

    let workPackage: WorkPackageResource;
    wpCacheService.loadWorkPackage(1).subscribe(wp => {
      workPackage = wp;
    });
    expect(workPackage.id).to.eq(1);
  });

  it('should return a work package once the list gets initialized', () => {
    let workPackage: WorkPackageResource = null;

    wpCacheService.loadWorkPackage(1).subscribe(wp => {
      workPackage = wp;
    });

    expect(workPackage).to.null;

    wpCacheService.updateWorkPackageList(dummyWorkPackages);

    expect(workPackage.id).to.eq(1);
  });

  it('should return/stream a work package every time it gets updated', () => {
    let loaded: WorkPackageResource & {dummy: string} = null;
    wpCacheService.loadWorkPackage(1).subscribe((wp: any) => {
      loaded = wp;
    });

    let workPackage: any = new WorkPackageResource({_links: {self: ""}});
    workPackage.id = 1;
    workPackage.dummy = "a";

    wpCacheService.updateWorkPackageList([workPackage]);
    expect(loaded.id).to.eq(1);
    expect(loaded.dummy).to.eq("a");

    workPackage = new WorkPackageResource({_links: {self: ""}});
    workPackage.id = 1;
    workPackage.dummy = "b";

    wpCacheService.updateWorkPackageList([workPackage]);
    expect(loaded.id).to.eq(1);
    expect(loaded.dummy).to.eq("b");
  });

});
