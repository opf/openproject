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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';
import { vi, type Mock } from 'vitest';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalEvent, HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WikisTabComponent } from 'core-app/features/plugins/linked/openproject-wikis/wikis-tab/wikis-tab.component';

const TAB_PATH = '/projects/1/work_packages/42/wikis/tab';
const REFRESH_URL = `${TAB_PATH}/inline_page_links`;

describe('WikisTabComponent', () => {
  let component:WikisTabComponent;
  let fixture:ComponentFixture<WikisTabComponent>;
  let events$:Subject<HalEvent[]>;
  let request:Mock;

  const workPackage = { id: '42', project: { id: '1' } } as WorkPackageResource;
  const descriptionEdit = {
    id: '42',
    eventType: 'updated',
    resourceType: 'WorkPackage',
    commit: { changes: { description: {} } },
  } as unknown as HalEvent;

  beforeEach(async () => {
    events$ = new Subject<HalEvent[]>();
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });

    await TestBed
      .configureTestingModule({
        declarations: [WikisTabComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: PathHelperService, useValue: { projectWorkPackagePath: () => '/projects/1/work_packages/42' } },
          { provide: HalEventsService, useValue: { aggregated$: () => events$.asObservable() } },
          { provide: TurboRequestsService, useValue: { request } },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WikisTabComponent);
    component = fixture.componentInstance;
    component.workPackage = workPackage;

    fixture.detectChanges();
  });

  it('points the tab frame at the wikis tab', () => {
    expect(component.turboFrameSrc).toEqual(TAB_PATH);
  });

  it('refreshes only the mentioned pages when a description edit is persisted', () => {
    events$.next([descriptionEdit]);

    expect(request).toHaveBeenCalledTimes(1);
    expect(request.mock.calls[0][0]).toEqual(REFRESH_URL);
  });

  it('asks for a turbo stream, so that the section is swapped in place', () => {
    events$.next([descriptionEdit]);

    expect(request.mock.calls[0][1]).toMatchObject({
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    });
  });

  it('ignores edits that did not touch the description', () => {
    events$.next([{ ...descriptionEdit, commit: { changes: { subject: {} } } } as unknown as HalEvent]);

    expect(request).not.toHaveBeenCalled();
  });

  it('ignores edits of other work packages', () => {
    events$.next([{ ...descriptionEdit, id: '43' } as HalEvent]);

    expect(request).not.toHaveBeenCalled();
  });

  it('refreshes on updates pushed without a commit, which do not name their changed attributes', () => {
    events$.next([{ id: '42', eventType: 'updated', resourceType: 'WorkPackage' } as HalEvent]);

    expect(request).toHaveBeenCalledTimes(1);
  });

  it('stops refreshing once the tab is closed', () => {
    fixture.destroy();

    events$.next([descriptionEdit]);

    expect(request).not.toHaveBeenCalled();
  });
});
