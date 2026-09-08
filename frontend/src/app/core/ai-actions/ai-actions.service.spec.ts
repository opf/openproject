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

import { TestBed } from '@angular/core/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { AiActionsService } from 'core-app/core/ai-actions/ai-actions.service';

const halCollection = (elements:unknown[]) => ({
  _type: 'Collection',
  total: elements.length,
  count: elements.length,
  _embedded: { elements },
});

const halAction = (id:number, label:string, position:number) => ({
  _type: 'AITextTransformAction',
  id,
  label,
  position,
  injectsTypeTemplate: false,
  _links: { self: { href: `/api/v3/ai_text_transform_actions/${id}`, title: label } },
});

const existingWorkPackage = {
  id: '123',
  _type: 'WorkPackage',
  $links: {
    type: { href: '/api/v3/types/45' },
    project: { href: '/api/v3/projects/7' },
  },
};

const newWorkPackage = { ...existingWorkPackage, id: 'new' };

describe('AiActionsService', () => {
  let service:AiActionsService;
  let httpMock:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AiActionsService,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(AiActionsService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('lists the actions of an existing work package ordered by position', async () => {
    const promise = service.actionsFor(existingWorkPackage, 'description');

    const request = httpMock.expectOne('/api/v3/work_packages/123/ai_text_transform_actions');
    expect(request.request.method).toBe('GET');
    request.flush(halCollection([
      halAction(2, 'Summarize', 2),
      halAction(1, 'Fix grammar', 1),
    ]));

    const actions = await promise;
    expect(actions.map((action) => action.label)).toEqual(['Fix grammar', 'Summarize']);
    expect(actions[0]).toEqual({
      id: 1, label: 'Fix grammar', position: 1, injectsTypeTemplate: false,
    });
  });

  it('lists the actions of a new work package through its project and type', async () => {
    const promise = service.actionsFor(newWorkPackage, 'description');

    const request = httpMock.expectOne('/api/v3/projects/7/ai_text_transform_actions?typeId=45');
    request.flush(halCollection([halAction(3, 'Sort into template', 1)]));

    const actions = await promise;
    expect(actions.map((action) => action.id)).toEqual([3]);
  });

  it('resolves to no actions for a new work package without project or type', async () => {
    const actions = await service.actionsFor({ id: 'new', _type: 'WorkPackage', $links: {} }, 'description');

    expect(actions).toEqual([]);
    httpMock.expectNone(() => true);
  });

  it('resolves to no actions outside the work package description', async () => {
    const forComment = await service.actionsFor(existingWorkPackage, 'comment');
    const forOtherResource = await service.actionsFor({ id: '5', _type: 'Meeting' }, 'description');
    const forNoResource = await service.actionsFor(undefined, 'description');

    expect([forComment, forOtherResource, forNoResource]).toEqual([[], [], []]);
    httpMock.expectNone(() => true);
  });

  it('resolves to no actions when the request fails', async () => {
    const promise = service.actionsFor(existingWorkPackage, 'description');

    httpMock
      .expectOne('/api/v3/work_packages/123/ai_text_transform_actions')
      .flush({ message: 'nope' }, { status: 403, statusText: 'Forbidden' });

    expect(await promise).toEqual([]);
  });
});
