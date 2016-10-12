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

import {WorkPackageTimelineService, RenderInfo} from "./wp-timeline.service";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import {asyncTest} from "../../../helpers/angular-rx-utils";
import WorkPackage = op.WorkPackage;

const expect = chai.expect;

describe.only('WorkPackageTimelineService', () => {
  let WorkPackageResource: any;
  let cacheService: WorkPackageCacheService;
  let timelineService: WorkPackageTimelineService;

  // open project module
  beforeEach(angular.mock.module('openproject'));

  // required service
  beforeEach(angular.mock.inject((_WorkPackageResource_,
                                  _wpCacheService_,
                                  _workPackageTimelineService_) => {

    WorkPackageResource = _WorkPackageResource_;
    cacheService = _wpCacheService_;
    timelineService = _workPackageTimelineService_;
  }));

  it('should use the earliest start date ', (done: any) => {

    const earlier = timelineService.viewParameters.dateDisplayStart.subtract(1, "day");
    const inOneMonth = moment().add(1, "month");

    const workPackage1: WorkPackage = new WorkPackageResource({_links: {self: ""}});
    workPackage1.id = 1;
    workPackage1.startDate = earlier.toString() as any;
    workPackage1.dueDate = inOneMonth.toString() as any;
    cacheService.updateWorkPackage(workPackage1 as any);

    timelineService.addWorkPackage("1")
      .subscribe(asyncTest(done, (renderInfo: RenderInfo) => {
        expect(renderInfo.viewParams.dateDisplayStart.isSame(earlier)).to.be.true;
      }));

    // const workPackage2 = new WorkPackageResource({_links: {self: ""}});
    // workPackage2.id = 2;


    // wpCacheService.updateWorkPackageList(dummyWorkPackages);
    //
    // let workPackage: WorkPackageResource;
    // wpCacheService.loadWorkPackage(1).observe(null).subscribe(wp => {
    //   workPackage = wp;
    // });
    // expect(workPackage.id).to.eq(1);
  });


  // it('should return/stream a work package every time it gets updated', () => {
  //   let loaded: WorkPackageResource & {dummy: string} = null;
  //   wpCacheService.loadWorkPackage(1).observe(null).subscribe((wp: any) => {
  //     loaded = wp;
  //   });
  //
  //   let workPackage: any = new WorkPackageResource({_links: {self: ""}});
  //   workPackage.id = 1;
  //   workPackage.dummy = "a";
  //
  //   wpCacheService.updateWorkPackageList([workPackage]);
  //   expect(loaded.id).to.eq(1);
  //   expect(loaded.dummy).to.eq("a");
  //
  //   workPackage = new WorkPackageResource({_links: {self: ""}});
  //   workPackage.id = 1;
  //   workPackage.dummy = "b";
  //
  //   wpCacheService.updateWorkPackageList([workPackage]);
  //   expect(loaded.id).to.eq(1);
  //   expect(loaded.dummy).to.eq("b");
  // });

});
