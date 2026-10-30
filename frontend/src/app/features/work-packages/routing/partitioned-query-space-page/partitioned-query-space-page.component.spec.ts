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

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { BoardPartitionedPageComponent } from 'core-app/features/boards/board/board-partitioned-page/board-partitioned-page.component';
import { WorkPackagesCalendarPageComponent } from 'core-app/features/calendar/wp-calendar-page/wp-calendar-page.component';
import { TeamPlannerPageComponent } from 'core-app/features/team-planner/team-planner/page/team-planner-page.component';
import { IFCViewerPageComponent } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-viewer-page.component';
import { WorkPackageViewPageComponent } from '../wp-view-page/wp-view-page.component';

describe('partitioned page breadcrumb producers', () => {
  const pathHelperService = new PathHelperService();
  const currentProject:{ identifier:string; name:string|null } = { identifier: 'demo', name: 'Demo' };
  const context = {
    pathHelperService,
    currentProject,
    selectedTitle: 'Selected',
    I18n: { t: (key:string) => key },
  };

  it.each([
    [() => BoardPartitionedPageComponent.prototype.breadcrumbItems.call(context), '/boards'],
    [() => WorkPackagesCalendarPageComponent.prototype.breadcrumbItems.call(context), '/calendars'],
    [() => TeamPlannerPageComponent.prototype.breadcrumbItems.call(context), '/team_planners'],
    [() => IFCViewerPageComponent.prototype.breadcrumbItems.call(context), '/bcf'],
  ] as const)('preserves the project and module routes (%s)', (producer, suffix) => {
    const items = producer();

    expect(items[0]).toEqual({ href: pathHelperService.projectPath('demo'), text: 'Demo' });
    expect(items[1]).toMatchObject({ href: `${pathHelperService.projectPath('demo')}${suffix}` });
    expect(items[2]).toBe('Selected');
  });

  it('retains route entries when the project label has not loaded', () => {
    const items = BoardPartitionedPageComponent.prototype.breadcrumbItems.call({
      ...context, currentProject: { identifier: 'demo', name: null },
    });

    expect(items[0]).toEqual({ href: pathHelperService.projectPath('demo'), text: null });
    expect(items).toHaveLength(3);
  });

  it.each([false, true])('retains the work-package module route for Gantt (%s)', (isGantt) => {
    const page = {
      ...context,
      isGantt,
      breadcrumbModuleEntry: () => WorkPackageViewPageComponent.prototype.breadcrumbModuleEntry.call({ ...context, isGantt }),
    };
    const items = WorkPackageViewPageComponent.prototype.breadcrumbItems.call(page);

    expect(items[0]).toEqual({ href: pathHelperService.projectPath('demo'), text: 'Demo' });
    expect(items[1]).toMatchObject({
      href: isGantt ? pathHelperService.ganttChartsPath('demo') : pathHelperService.workPackagesPath('demo'),
    });
    expect(items[2]).toBe('Selected');
  });
});
