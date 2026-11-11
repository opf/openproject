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

import { vi, type Mock } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import {
  AI_TEXT_TRANSFORM_ACCEPTED_EVENT,
  AI_TEXT_TRANSFORM_APPLIED_EVENT,
  AI_TEXT_TRANSFORM_CLOSED_EVENT,
  AiActionsService,
  IAiActionsEditor,
} from 'core-app/core/ai-actions/ai-actions.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

const halCollection = (elements:unknown[]) => ({
  _type: 'Collection',
  total: elements.length,
  count: elements.length,
  _embedded: { elements },
});

const halAction = (id:number, label:string, position:number) => ({
  _type: 'AITextAction',
  id,
  label,
  position,
  injectsTypeTemplate: false,
  _links: { self: { href: `/api/v3/ai_text_actions/${id}`, title: label } },
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
const sortIntoTemplate = { id: 3, label: 'Sort into template', position: 3, injectsTypeTemplate: true };

interface IFakeMarker {
  name:string;
  getRange():unknown;
}

function fakeEmitter() {
  const listeners = new Map<string, Set<() => void>>();

  return {
    on: (name:string, callback:() => void) => {
      listeners.set(name, (listeners.get(name) ?? new Set()).add(callback));
    },
    off: (name:string, callback:() => void) => {
      listeners.get(name)?.delete(callback);
    },
    fire: (name:string) => listeners.get(name)?.forEach((callback) => callback()),
    count: () => [...listeners.values()].reduce((sum, callbacks) => sum + callbacks.size, 0),
  };
}

function fakeEditor(field?:string, data = 'Login page dont work.') {
  const root = { name: '$root' };
  const graveyard = { name: '$graveyard' };
  const range = { root, rangeIn: root };
  const selectedRange = { root, isCollapsed: false, selected: true };
  const selectedContent = { fragment: true };
  const parsed = { parsed: true };
  const markers = new Map<string, IFakeMarker>();
  const writer = {
    addMarker: vi.fn((name:string, { range: markedRange }:{ range:unknown }) => {
      markers.set(name, { name, getRange: () => markedRange });
    }),
    removeMarker: vi.fn((marker:IFakeMarker) => markers.delete(marker.name)),
  };
  const model = {
    document: {
      getRoot: vi.fn(() => root),
      graveyard,
      selection: { isCollapsed: true, rangeCount: 1, getFirstRange: vi.fn(() => selectedRange) },
    },
    markers: { get: (name:string) => markers.get(name) ?? null },
    createRangeIn: vi.fn(() => range),
    getSelectedContent: vi.fn(() => selectedContent),
    insertContent: vi.fn(),
    change: vi.fn((callback:(changeWriter:typeof writer) => void) => callback(writer)),
  };
  const events = fakeEmitter();
  const dataEvents = fakeEmitter();
  const editor = {
    state: 'ready',
    getData: vi.fn(() => data),
    data: { parse: vi.fn(() => parsed), stringify: vi.fn(() => ''), on: dataEvents.on, off: dataEvents.off },
    model,
    config: { get: vi.fn((name:string) => (name === 'openProject.context.field' ? field : undefined)) },
    on: events.on,
    off: events.off,
  };

  const select = (markdown:string) => {
    model.document.selection.isCollapsed = false;
    editor.data.stringify.mockReturnValue(markdown);
  };

  return {
    editor,
    asEditor: editor as unknown as IAiActionsEditor,
    model,
    writer,
    markers,
    graveyard,
    range,
    selectedRange,
    selectedContent,
    parsed,
    select,
    events,
    dataEvents,
    listenerCount: () => events.count() + dataEvents.count(),
  };
}

describe('AiActionsService', () => {
  let service:AiActionsService;
  let httpMock:HttpTestingController;
  let activeFeatureFlags:string[];
  let turboRequests:{ request:Mock<TurboRequestsService['request']> };
  let toast:{ addError:ReturnType<typeof vi.fn> };

  beforeEach(() => {
    activeFeatureFlags = ['aiTextActions'];
    turboRequests = { request: vi.fn<TurboRequestsService['request']>().mockResolvedValue({ html: '', headers: new Headers() }) };
    toast = { addError: vi.fn() };
    TestBed.configureTestingModule({
      providers: [
        AiActionsService,
        { provide: ConfigurationService, useValue: { get activeFeatureFlags() { return activeFeatureFlags; } } },
        { provide: TurboRequestsService, useValue: turboRequests },
        { provide: ToastService, useValue: toast },
        { provide: I18nService, useValue: { t: (key:string) => key } },
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

      const request = httpMock.expectOne('/api/v3/work_packages/123/ai_text_actions');
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
        .expectOne('/api/v3/projects/7/ai_text_actions?typeId=45')
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
        .expectOne('/api/v3/ai_text_actions')
        .flush(halCollection([halAction(2, 'Summarize', 2), halAction(1, 'Fix grammar', 1)]));

      expect((await promise).map((action) => action.id)).toEqual([1, 2]);
    });

    it('resolves to no actions when the request fails', async () => {
      const promise = service.actionsFor(existingWorkPackage, 'description');

      httpMock
        .expectOne('/api/v3/work_packages/123/ai_text_actions')
        .flush({ message: 'nope' }, { status: 403, statusText: 'Forbidden' });

      expect(await promise).toEqual([]);
    });

    it('resolves to no actions when the request for the actions offered everywhere fails', async () => {
      const promise = service.actionsFor(undefined, undefined);

      httpMock
        .expectOne('/api/v3/ai_text_actions')
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
      await service.run(makeConcise, fakeEditor().asEditor);

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
  describe('run', () => {
    afterEach(() => vi.restoreAllMocks());

    function requestBody(call = 0):Record<string, FormDataEntryValue> {
      const init = turboRequests.request.mock.calls[call][1]!;
      return Object.fromEntries((init.body as FormData).entries());
    }

    function requestIdOf(call = 0):string {
      return requestBody(call).request_id as string;
    }

    function accept(requestId:string, text = 'Login page does not work.'):void {
      document.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_ACCEPTED_EVENT, { detail: { requestId, scope: 'document', text } }));
    }

    it('requests the result pane for the whole work package description with its context', async () => {
      await service.run(fixGrammar, fakeEditor('description').asEditor, existingWorkPackage);

      const [url, init, suppressErrorToast] = turboRequests.request.mock.calls[0] as [string, RequestInit, boolean];
      expect(url).toBe('/ai/text_transform_panes');
      expect(init).toMatchObject({ method: 'POST', headers: { Accept: 'text/vnd.turbo-stream.html' } });
      expect(suppressErrorToast).toBe(true);
      expect(requestBody()).toEqual({
        request_id: expect.stringMatching(/^[0-9a-f-]{36}$/) as string,
        action_id: '1',
        scope: 'document',
        input: 'Login page dont work.',
        work_package_id: '123',
      });
    });

    it('sends project and type for a new work package', async () => {
      await service.run(fixGrammar, fakeEditor('description').asEditor, newWorkPackage);

      expect(requestBody()).toMatchObject({ project_id: '7', type_id: '45' });
      expect(requestBody()).not.toHaveProperty('work_package_id');
    });

    it.each([
      ['a work package comment', existingWorkPackage, 'journal[notes]'],
      ['an editor without resource', undefined, 'content'],
    ])('sends no context for %s', async (_, resource, field) => {
      await service.run(fixGrammar, fakeEditor(field).asEditor, resource);

      expect(Object.keys(requestBody()).sort()).toEqual(['action_id', 'input', 'request_id', 'scope']);
    });

    it('replaces the whole document as one undoable change and reports it', async () => {
      const { asEditor, model, range, parsed, editor } = fakeEditor('description');
      const applied = vi.fn();
      window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);
      await service.run(fixGrammar, asEditor, existingWorkPackage);

      accept(requestIdOf());
      window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);

      expect(editor.data.parse).toHaveBeenCalledWith('Login page does not work.');
      expect(model.change).toHaveBeenCalledTimes(1);
      expect(model.insertContent).toHaveBeenCalledWith(parsed, range);
      expect((applied.mock.calls[0][0] as CustomEvent).detail).toEqual({ requestId: requestIdOf(), ok: true });
    });

    it('applies each request only once', async () => {
      const { asEditor, model } = fakeEditor();
      await service.run(fixGrammar, asEditor);

      accept(requestIdOf());
      accept(requestIdOf());

      expect(model.insertContent).toHaveBeenCalledTimes(1);
    });

    it('ignores requests it did not start', async () => {
      const { asEditor, model } = fakeEditor();
      await service.run(fixGrammar, asEditor);

      accept('3f1c2b4a-5d6e-4f70-8a9b-0c1d2e3f4a5b');

      expect(model.insertContent).not.toHaveBeenCalled();
    });

    it('drops the older request once a new pane replaced its pane, even from another editor', async () => {
      const first = fakeEditor();
      const second = fakeEditor();
      await service.run(fixGrammar, first.asEditor);
      await service.run(makeConcise, second.asEditor);

      accept(requestIdOf(0));
      expect(first.model.insertContent).not.toHaveBeenCalled();

      accept(requestIdOf(1));
      expect(second.model.insertContent).toHaveBeenCalledTimes(1);
    });

    it('keeps the current request when a new pane could not be requested', async () => {
      const { asEditor, model } = fakeEditor();
      await service.run(fixGrammar, asEditor);
      turboRequests.request.mockRejectedValueOnce(new Error('403'));
      await service.run(makeConcise, fakeEditor().asEditor);

      accept(requestIdOf(0));

      expect(model.insertContent).toHaveBeenCalledTimes(1);
    });

    it('aborts the older start when another action starts', async () => {
      const first = fakeEditor();
      const second = fakeEditor();
      let rejectFirst:(error:unknown) => void = () => undefined;
      turboRequests.request.mockImplementationOnce(() => new Promise((_, reject) => { rejectFirst = reject; }));

      const firstRun = service.run(fixGrammar, first.asEditor);
      await service.run(makeConcise, second.asEditor);
      rejectFirst(new DOMException('The operation was aborted.', 'AbortError'));
      await firstRun;

      const startIds = turboRequests.request.mock.calls.map(([, , , requestId]) => requestId);
      expect(startIds).toEqual(['ai-text-transform-pane', 'ai-text-transform-pane']);
      expect(toast.addError).not.toHaveBeenCalled();
      accept(requestIdOf(0));
      accept(requestIdOf(1));
      expect(first.model.insertContent).not.toHaveBeenCalled();
      expect(second.model.insertContent).toHaveBeenCalledTimes(1);
    });

    it('keeps the newest request when an older start answers last', async () => {
      const first = fakeEditor();
      const second = fakeEditor();
      let resolveFirst:(value:{ html:string, headers:Headers }) => void = () => undefined;
      turboRequests.request.mockImplementationOnce(() => new Promise((resolve) => { resolveFirst = resolve; }));

      const firstRun = service.run(fixGrammar, first.asEditor);
      await service.run(makeConcise, second.asEditor);
      resolveFirst({ html: '', headers: new Headers() });
      await firstRun;

      accept(requestIdOf(0));
      accept(requestIdOf(1));
      expect(first.model.insertContent).not.toHaveBeenCalled();
      expect(second.model.insertContent).toHaveBeenCalledTimes(1);
    });

    it.each([
      ['its content is set from outside, as when a comment draft is reset', 'data', 'set'],
      ['the user switches to the source mode', 'editor', 'op:source-code-enabled'],
    ])('leaves the answer to the pane when %s', async (_, emitter, event) => {
      const editor = fakeEditor();
      const applied = vi.fn();
      window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);
      await service.run(fixGrammar, editor.asEditor);

      (emitter === 'data' ? editor.dataEvents : editor.events).fire(event);
      accept(requestIdOf());
      window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);

      expect(editor.model.insertContent).not.toHaveBeenCalled();
      expect(applied).not.toHaveBeenCalled();
      expect(editor.listenerCount()).toBe(0);
    });

    it('stops watching the editor once its request is applied or replaced', async () => {
      const first = fakeEditor();
      const second = fakeEditor();
      await service.run(fixGrammar, first.asEditor);
      expect(first.listenerCount()).toBe(2);

      await service.run(makeConcise, second.asEditor);
      expect(first.listenerCount()).toBe(0);

      accept(requestIdOf(1));
      expect(second.listenerCount()).toBe(0);
    });

    it('leaves the answer to the pane when the editor was destroyed meanwhile', async () => {
      const { asEditor, model, editor } = fakeEditor();
      const applied = vi.fn();
      window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);
      await service.run(fixGrammar, asEditor);

      editor.state = 'destroyed';
      accept(requestIdOf());
      window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);

      expect(model.insertContent).not.toHaveBeenCalled();
      expect(applied).not.toHaveBeenCalled();
    });

    it('forgets a request once its pane was closed', async () => {
      const { asEditor, model } = fakeEditor();
      await service.run(fixGrammar, asEditor);

      document.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_CLOSED_EVENT, { detail: { requestId: requestIdOf() } }));
      accept(requestIdOf());

      expect(model.insertContent).not.toHaveBeenCalled();
    });

    describe('with selected text', () => {
      const markerNames = (markers:Map<string, IFakeMarker>) => [...markers.keys()];

      it('requests the result pane for the selected text only and marks it', async () => {
        const { asEditor, editor, model, markers, selectedRange, selectedContent, select } = fakeEditor('description');
        select('Login page dont work.');

        await service.run(fixGrammar, asEditor, existingWorkPackage);

        expect(editor.data.stringify).toHaveBeenCalledWith(selectedContent);
        expect(model.getSelectedContent).toHaveBeenCalledWith(model.document.selection);
        expect(requestBody()).toMatchObject({ scope: 'selection', input: 'Login page dont work.', work_package_id: '123' });
        expect(markerNames(markers)).toEqual([`ai-text-transform:selection:${requestIdOf()}`]);
        expect(markers.get(markerNames(markers)[0])!.getRange()).toBe(selectedRange);
      });

      it('runs on the whole document when the selected text is blank', async () => {
        const { asEditor, markers, select } = fakeEditor();
        select(' \n');

        await service.run(fixGrammar, asEditor);

        expect(requestBody()).toMatchObject({ scope: 'document', input: 'Login page dont work.' });
        expect(markers.size).toBe(0);
      });

      it('runs on the whole document when several ranges are selected', async () => {
        const { asEditor, model, markers, select } = fakeEditor();
        select('| Login | page |');
        model.document.selection.rangeCount = 2;

        await service.run(fixGrammar, asEditor);

        expect(requestBody()).toMatchObject({ scope: 'document', input: 'Login page dont work.' });
        expect(markers.size).toBe(0);
      });

      it('runs an action that injects the type template on the whole document', async () => {
        const { asEditor, editor, markers, select } = fakeEditor('description');
        select('Login page dont work.');

        await service.run(sortIntoTemplate, asEditor, existingWorkPackage);

        expect(requestBody()).toMatchObject({ scope: 'document', input: 'Login page dont work.' });
        expect(editor.data.stringify).not.toHaveBeenCalled();
        expect(markers.size).toBe(0);
      });

      it('replaces only the selected text as one undoable change and reports it', async () => {
        const { asEditor, model, writer, markers, parsed, selectedRange, select } = fakeEditor();
        const applied = vi.fn();
        window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);
        select('Login page dont work.');
        await service.run(fixGrammar, asEditor);
        model.change.mockClear();

        accept(requestIdOf());
        window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);

        expect(model.change).toHaveBeenCalledTimes(1);
        expect(model.insertContent).toHaveBeenCalledWith(parsed, selectedRange);
        expect(writer.removeMarker).toHaveBeenCalledTimes(1);
        expect(markers.size).toBe(0);
        expect((applied.mock.calls[0][0] as CustomEvent).detail).toEqual({ requestId: requestIdOf(), ok: true });
      });

      it('applies each request only once', async () => {
        const { asEditor, model, select } = fakeEditor();
        select('Login page dont work.');
        await service.run(fixGrammar, asEditor);

        accept(requestIdOf());
        accept(requestIdOf());

        expect(model.insertContent).toHaveBeenCalledTimes(1);
      });

      it.each([
        ['was deleted meanwhile', (markers:Map<string, IFakeMarker>, graveyard:unknown) => {
          markers.forEach((marker) => { marker.getRange = () => ({ root: graveyard, isCollapsed: false }); });
        }],
        ['collapsed when its blocks merged', (markers:Map<string, IFakeMarker>) => {
          markers.forEach((marker) => { marker.getRange = () => ({ isCollapsed: true }); });
        }],
        ['lost its marker', (markers:Map<string, IFakeMarker>) => markers.clear()],
      ])('changes nothing and reports it when the selected text %s', async (_, loseSelection) => {
        const { asEditor, model, markers, graveyard, select } = fakeEditor();
        const applied = vi.fn();
        window.addEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);
        select('Login page dont work.');
        await service.run(fixGrammar, asEditor);

        loseSelection(markers, graveyard);
        accept(requestIdOf());
        window.removeEventListener(AI_TEXT_TRANSFORM_APPLIED_EVENT, applied);

        expect(model.insertContent).not.toHaveBeenCalled();
        expect(markers.size).toBe(0);
        expect((applied.mock.calls[0][0] as CustomEvent).detail).toEqual({ requestId: requestIdOf(), ok: false });
      });

      it('unmarks the text once its pane was closed', async () => {
        const { asEditor, markers, select } = fakeEditor();
        select('Login page dont work.');
        await service.run(fixGrammar, asEditor);

        document.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_CLOSED_EVENT, { detail: { requestId: requestIdOf() } }));

        expect(markers.size).toBe(0);
      });

      it('unmarks the text of the older request once a new pane replaced its pane', async () => {
        const { asEditor, markers, select } = fakeEditor();
        select('Login page dont work.');
        await service.run(fixGrammar, asEditor);
        await service.run(makeConcise, asEditor);

        expect(markerNames(markers)).toEqual([`ai-text-transform:selection:${requestIdOf(1)}`]);
      });

      it('unmarks only its own text when the pane could not be requested', async () => {
        const { asEditor, markers, select } = fakeEditor();
        select('Login page dont work.');
        await service.run(fixGrammar, asEditor);
        turboRequests.request.mockRejectedValueOnce(new Error('403'));
        await service.run(makeConcise, asEditor);

        expect(markerNames(markers)).toEqual([`ai-text-transform:selection:${requestIdOf(0)}`]);
      });

      it.each([
        ['is aborted', (settle:() => void, fail:(error:unknown) => void) => fail(new DOMException('Aborted', 'AbortError'))],
        ['answers last', (settle:() => void) => settle()],
      ])('unmarks the text of an older start that %s', async (_, finish) => {
        const { asEditor, markers, select } = fakeEditor();
        select('Login page dont work.');
        let resolveFirst:() => void = () => undefined;
        let rejectFirst:(error:unknown) => void = () => undefined;
        turboRequests.request.mockImplementationOnce(() => new Promise((resolve, reject) => {
          resolveFirst = () => resolve({ html: '', headers: new Headers() });
          rejectFirst = reject;
        }));

        const firstRun = service.run(fixGrammar, asEditor);
        await service.run(makeConcise, asEditor);
        finish(resolveFirst, rejectFirst);
        await firstRun;

        expect(markerNames(markers)).toEqual([`ai-text-transform:selection:${requestIdOf(1)}`]);
      });
    });

    it('tells the user when the pane could not be requested', async () => {
      turboRequests.request.mockRejectedValueOnce(new Error('403'));
      const { asEditor, model } = fakeEditor();
      await service.run(fixGrammar, asEditor);

      accept(requestIdOf());

      expect(toast.addError).toHaveBeenCalledWith('js.editor.ai_actions.start_failed');
      expect(model.insertContent).not.toHaveBeenCalled();
    });
  });
});
