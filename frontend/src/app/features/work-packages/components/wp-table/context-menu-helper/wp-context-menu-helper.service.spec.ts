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

import { TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageViewHierarchyIdentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { WorkPackageContextMenuHelperService } from './wp-context-menu-helper.service';

describe('WorkPackageContextMenuHelperService', () => {
  const pathHelper = {
    workPackagesBulkEditPath: () => '',
    workPackagesBulkMovePath: () => '',
    workPackagesBulkDuplicatePath: () => '',
    workPackagesBulkDeletePath: () => '',
    workPackageShortPath: (id:string, { format }:{ format?:string } = {}) => (format ? `/wp/${id}.${format}` : `/wp/${id}`),
  } as unknown as PathHelperService;

  const workPackage = {
    displayId: 'SP-1',
    id: 14,
    atom: { href: '/work_packages/14.atom' },
  } as unknown as WorkPackageResource;

  let service:WorkPackageContextMenuHelperService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        WorkPackageContextMenuHelperService,
        { provide: PathHelperService, useValue: pathHelper },
        { provide: HookService, useValue: {} },
        { provide: UrlParamsHelperService, useValue: {} },
        { provide: WorkPackageViewDisplayRepresentationService, useValue: {} },
        { provide: WorkPackageViewTimelineService, useValue: {} },
        { provide: WorkPackageViewHierarchyIdentationService, useValue: {} },
      ],
    });
    service = TestBed.inject(WorkPackageContextMenuHelperService);
  });

  it('resolves view_markdown to the short path with the md format', () => {
    expect(service.linkForAction(workPackage, { key: 'view_markdown', link: 'markdown' })).toBe('/wp/SP-1.md');
  });

  it('resolves other actions to the HAL link href', () => {
    expect(service.linkForAction(workPackage, { key: 'export-atom', link: 'atom' })).toBe('/work_packages/14.atom');
  });
});
