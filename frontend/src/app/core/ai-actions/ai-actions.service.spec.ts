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

import { vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { AiActionsService } from 'core-app/core/ai-actions/ai-actions.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

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

const fixGrammar = { id: 1, label: 'Fix grammar', position: 1, injectsTypeTemplate: false };
const makeConcise = { id: 2, label: 'Make concise', position: 2, injectsTypeTemplate: false };

describe('AiActionsService', () => {
  let service:AiActionsService;
  let httpMock:HttpTestingController;
  let activeFeatureFlags:string[];

  beforeEach(() => {
    activeFeatureFlags = ['aiTextTransformActions'];
    TestBed.configureTestingModule({
      providers: [
        AiActionsService,
        { provide: ConfigurationService, useValue: { get activeFeatureFlags() { return activeFeatureFlags; } } },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(AiActionsService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  describe('actionsFor', () => {
    it('resolves to no actions without requesting any while the feature flag is off', async () => {
      activeFeatureFlags = [];

      expect(await service.actionsFor(existingWorkPackage, 'description')).toEqual([]);
      expect(await service.actionsFor(undefined, undefined)).toEqual([]);
      httpMock.expectNone(() => true);
    });

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
      expect(actions[0]).toEqual(fixGrammar);
    });

    it('lists the actions of a new work package through its project and type', async () => {
      const promise = service.actionsFor(newWorkPackage, 'description');

      httpMock
        .expectOne('/api/v3/projects/7/ai_text_transform_actions?typeId=45')
        .flush(halCollection([halAction(3, 'Sort into template', 1)]));

      expect((await promise).map((action) => action.id)).toEqual([3]);
    });

    it('resolves to no actions for a new work package without project or type', async () => {
      const actions = await service.actionsFor({ id: 'new', _type: 'WorkPackage', $links: {} }, 'description');

      expect(actions).toEqual([]);
      httpMock.expectNone(() => true);
    });

    it.each([
      ['a work package comment', existingWorkPackage, 'journal[notes]'],
      ['another resource', { id: '5', _type: 'Meeting' }, 'description'],
      ['an editor without resource', undefined, 'content'],
      ['an editor without field', existingWorkPackage, undefined],
    ])('lists the actions offered everywhere for %s', async (_, resource, field) => {
      const promise = service.actionsFor(resource, field);

      httpMock
        .expectOne('/api/v3/ai_text_transform_actions')
        .flush(halCollection([halAction(2, 'Summarize', 2), halAction(1, 'Fix grammar', 1)]));

      expect((await promise).map((action) => action.id)).toEqual([1, 2]);
    });

    it('resolves to no actions when the request fails', async () => {
      const promise = service.actionsFor(existingWorkPackage, 'description');

      httpMock
        .expectOne('/api/v3/work_packages/123/ai_text_transform_actions')
        .flush({ message: 'nope' }, { status: 403, statusText: 'Forbidden' });

      expect(await promise).toEqual([]);
    });

    it('resolves to no actions when the request for the actions offered everywhere fails', async () => {
      const promise = service.actionsFor(undefined, undefined);

      httpMock
        .expectOne('/api/v3/ai_text_transform_actions')
        .flush({ message: 'nope' }, { status: 401, statusText: 'Unauthorized' });

      expect(await promise).toEqual([]);
    });
  });

  describe('defaultAction', () => {
    const storageKey = 'openproject.ai_actions.last_action_id';

    beforeEach(() => window.localStorage.removeItem(storageKey));
    afterEach(() => {
      vi.restoreAllMocks();
      window.localStorage.removeItem(storageKey);
    });

    it('is the first action while none was run yet', () => {
      expect(service.defaultAction([fixGrammar, makeConcise])).toBe(fixGrammar);
    });

    it('is the action that was run last', async () => {
      await service.run(makeConcise);

      expect(service.defaultAction([fixGrammar, makeConcise])).toBe(makeConcise);
      expect(window.localStorage.getItem(storageKey)).toBe('2');
    });

    it('remembers the last action across page loads', () => {
      window.localStorage.setItem(storageKey, '2');

      expect(service.defaultAction([fixGrammar, makeConcise])).toBe(makeConcise);
    });

    it('falls back to the first action when the last one is not offered', () => {
      window.localStorage.setItem(storageKey, '99');

      expect(service.defaultAction([fixGrammar, makeConcise])).toBe(fixGrammar);
    });

    it('is the first action when the browser storage is unavailable', () => {
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => { throw new Error('blocked'); });

      expect(service.defaultAction([fixGrammar, makeConcise])).toBe(fixGrammar);
    });
  });
});
