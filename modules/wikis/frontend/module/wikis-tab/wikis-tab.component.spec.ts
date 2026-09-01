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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WikisTabComponent } from 'core-app/features/plugins/linked/openproject-wikis/wikis-tab/wikis-tab.component';

describe('WikisTabComponent', () => {
  let component:WikisTabComponent;
  let fixture:ComponentFixture<WikisTabComponent>;
  let events$:Subject<HalEvent[]>;
  let reload:Mock;

  const workPackage = { id: '42', project: { id: '1' } } as WorkPackageResource;
  const descriptionEdit = {
    id: '42',
    eventType: 'updated',
    resourceType: 'WorkPackage',
    commit: { changes: { description: {} } },
  } as unknown as HalEvent;

  beforeEach(async () => {
    events$ = new Subject<HalEvent[]>();

    await TestBed
      .configureTestingModule({
        declarations: [WikisTabComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
          { provide: PathHelperService, useValue: { projectWorkPackagePath: () => '/projects/1/work_packages/42' } },
          { provide: HalEventsService, useValue: { aggregated$: () => events$.asObservable() } },
        ],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WikisTabComponent);
    component = fixture.componentInstance;
    component.workPackage = workPackage;

    fixture.detectChanges();

    // `turbo-frame` is an unknown element here, so it has no `reload` of its own.
    reload = vi.fn();
    (component.frameElement.nativeElement as unknown as { reload:Mock }).reload = reload;
  });

  it('points the frame at the wikis tab', () => {
    expect(component.turboFrameSrc).toEqual('/projects/1/work_packages/42/wikis/tab');
  });

  it('reloads the tab when a description edit is persisted', () => {
    events$.next([descriptionEdit]);

    expect(reload).toHaveBeenCalledTimes(1);
  });

  it('ignores edits that did not touch the description', () => {
    events$.next([{ ...descriptionEdit, commit: { changes: { subject: {} } } } as unknown as HalEvent]);

    expect(reload).not.toHaveBeenCalled();
  });

  it('ignores edits of other work packages', () => {
    events$.next([{ ...descriptionEdit, id: '43' } as HalEvent]);

    expect(reload).not.toHaveBeenCalled();
  });

  it('ignores updates pushed without a commit, which cannot have changed the description', () => {
    events$.next([{ id: '42', eventType: 'updated', resourceType: 'WorkPackage' } as HalEvent]);

    expect(reload).not.toHaveBeenCalled();
  });

  it('stops reloading once the tab is closed', () => {
    fixture.destroy();

    events$.next([descriptionEdit]);

    expect(reload).not.toHaveBeenCalled();
  });
});
