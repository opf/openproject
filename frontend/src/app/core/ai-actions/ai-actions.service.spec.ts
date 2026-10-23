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
import { AI_SELECTION_MARKER, AiActionsService } from 'core-app/core/ai-actions/ai-actions.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ModelWriter } from 'core-app/core/ai-actions/editor-content';
import {
  AI_TEXT_TRANSFORM_APPLIED_EVENT,
  AI_TEXT_TRANSFORM_APPLY_EVENT,
  AI_TEXT_TRANSFORM_CLOSED_EVENT,
  AiTextTransformAppliedDetail,
} from 'core-app/core/ai-actions/ai-text-transform-events';

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

class FakeEditor {
  content = '# Old text';

  selectedMarkdown = '';

  markers = new Map<string, string>();

  inserted:{ text:string, range:string }|null = null;

  data = {
    parse: (markdown:string) => markdown,
    stringify: () => this.selectedMarkdown,
  };

  model = {
    document: {
      getRoot: () => 'root',
      selection: {
        get isCollapsed() { return false; },
        getFirstRange: () => 'selection-range',
      },
    },
    markers: { get: (name:string) => (this.markers.has(name) ? { getRange: () => this.markers.get(name) } : null) },
    createRangeIn: (root:string) => `range-in-${root}`,
    getSelectedContent: () => 'selected-fragment',
    change: (callback:(writer:ModelWriter) => void) => callback({
      addMarker: (name:string, { range }:{ range:unknown }) => { this.markers.set(name, range as string); },
      removeMarker: (name:string) => { this.markers.delete(name); },
    }),
    insertContent: (text:string, range:string) => { this.inserted = { text, range }; },
  };

  getData():string { return this.content; }
}

const fixGrammar = { id: 1, label: 'Fix grammar', position: 1, injectsTypeTemplate: false };
const sortIntoTemplate = { id: 3, label: 'Sort into template', position: 3, injectsTypeTemplate: true };

describe('AiActionsService', () => {
  let service:AiActionsService;
  let httpMock:HttpTestingController;
  let editor:FakeEditor;
  let paneRequests:{ url:string, body:FormData }[];
  let applied:AiTextTransformAppliedDetail[];

  const onApplied = (event:Event) => { applied.push((event as CustomEvent<AiTextTransformAppliedDetail>).detail); };

  beforeEach(() => {
    paneRequests = [];
    applied = [];
    const turboRequestsStub = {
      request: (url:string, init:RequestInit) => {
        paneRequests.push({ url, body: init.body as FormData });
        return Promise.resolve({ html: '', headers: new Headers() });
      },
    };

    TestBed.configureTestingModule({
      providers: [
        AiActionsService,
        { provide: TurboRequestsService, useValue: turboRequestsStub },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(AiActionsService);
    httpMock = TestBed.inject(HttpTestingController);
    editor = new FakeEditor();
    window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, onApplied);
  });

  afterEach(() => {
    httpMock.verify();
    window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, onApplied);
  });

  const lastRequestId = () => paneRequests[paneRequests.length - 1].body.get('request_id') as string;

  const dispatch = (name:string, detail:unknown) => document.dispatchEvent(new CustomEvent(name, { detail }));

  describe('run', () => {
    it('requests the result pane for the whole description without a selection', async () => {
      await service.run(fixGrammar, editor, existingWorkPackage);

      const [{ url, body }] = paneRequests;
      expect(url).toBe('/ai/text_transform_panes');
      expect(body.get('action_id')).toBe('1');
      expect(body.get('scope')).toBe('document');
      expect(body.get('input')).toBe('# Old text');
      expect(body.get('work_package_id')).toBe('123');
      expect(body.get('request_id')).toMatch(/^[0-9a-f-]{36}$/);
    });

    it('sends only the selected text and marks its range', async () => {
      editor.selectedMarkdown = 'selected **text**';

      await service.run(fixGrammar, editor, existingWorkPackage);

      expect(paneRequests[0].body.get('scope')).toBe('selection');
      expect(paneRequests[0].body.get('input')).toBe('selected **text**');
      expect(editor.markers.get(AI_SELECTION_MARKER)).toBe('selection-range');
    });

    it('runs actions that inject the type template on the whole description', async () => {
      editor.selectedMarkdown = 'selected text';

      await service.run(sortIntoTemplate, editor, newWorkPackage);

      const { body } = paneRequests[0];
      expect(body.get('scope')).toBe('document');
      expect(body.get('project_id')).toBe('7');
      expect(body.get('type_id')).toBe('45');
      expect(editor.markers.size).toBe(0);
    });

    it('does nothing outside a work package', async () => {
      await service.run(fixGrammar, editor, { id: '5', _type: 'Meeting' });

      expect(paneRequests).toEqual([]);
    });
  });

  describe('applying the result', () => {
    it('replaces the whole description and reports success', async () => {
      await service.run(fixGrammar, editor, existingWorkPackage);

      dispatch(AI_TEXT_TRANSFORM_APPLY_EVENT, { requestId: lastRequestId(), scope: 'document', text: 'New text' });

      expect(editor.inserted).toEqual({ text: 'New text', range: 'range-in-root' });
      expect(applied).toEqual([{ requestId: lastRequestId(), ok: true }]);
    });

    it('replaces only the marked selection', async () => {
      editor.selectedMarkdown = 'old part';
      await service.run(fixGrammar, editor, existingWorkPackage);

      dispatch(AI_TEXT_TRANSFORM_APPLY_EVENT, { requestId: lastRequestId(), scope: 'selection', text: 'new part' });

      expect(editor.inserted).toEqual({ text: 'new part', range: 'selection-range' });
      expect(editor.markers.size).toBe(0);
    });

    it('reports a failure when the selection is gone', async () => {
      editor.selectedMarkdown = 'old part';
      await service.run(fixGrammar, editor, existingWorkPackage);
      editor.markers.clear();

      dispatch(AI_TEXT_TRANSFORM_APPLY_EVENT, { requestId: lastRequestId(), scope: 'selection', text: 'new part' });

      expect(editor.inserted).toBeNull();
      expect(applied).toEqual([{ requestId: lastRequestId(), ok: false }]);
    });

    it('ignores results for requests it did not start', async () => {
      await service.run(fixGrammar, editor, existingWorkPackage);

      dispatch(AI_TEXT_TRANSFORM_APPLY_EVENT, { requestId: crypto.randomUUID(), scope: 'document', text: 'Injected' });

      expect(editor.inserted).toBeNull();
      expect(applied).toEqual([]);
    });

    it('clears the selection marker when the pane closes', async () => {
      editor.selectedMarkdown = 'old part';
      await service.run(fixGrammar, editor, existingWorkPackage);

      dispatch(AI_TEXT_TRANSFORM_CLOSED_EVENT, { requestId: lastRequestId() });

      expect(editor.markers.size).toBe(0);
    });
  });

  describe('defaultAction', () => {
    const makeConcise = { id: 2, label: 'Make concise', position: 2, injectsTypeTemplate: false };
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
      await service.run(makeConcise, editor, existingWorkPackage);

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
    const forNoField = await service.actionsFor(existingWorkPackage, undefined);

    expect([forComment, forOtherResource, forNoResource, forNoField]).toEqual([[], [], [], []]);
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
