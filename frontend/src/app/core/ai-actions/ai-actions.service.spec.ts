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
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

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

  inserted:string|null = null;

  readOnlyLocks:string[] = [];

  data = {
    processor: { toView: (markdown:string) => ({ markdown }) },
    toModel: (view:{ markdown:string }) => ({ fragment: view.markdown }),
  };

  model = {
    document: { getRoot: () => 'root' },
    createRangeIn: (root:string) => `range-in-${root}`,
    change: (callback:() => void) => callback(),
    insertContent: (fragment:{ fragment:string }, range:string) => {
      expect(range).toBe('range-in-root');
      this.inserted = fragment.fragment;
    },
  };

  state = 'ready';

  private listeners:Record<string, (() => void)[]> = {};

  getData():string { return this.content; }

  once(event:string, callback:() => void):void {
    (this.listeners[event] ||= []).push(callback);
  }

  destroy():void {
    this.state = 'destroyed';
    (this.listeners.destroy || []).splice(0).forEach((callback) => callback());
  }

  enableReadOnlyMode(lock:string):void { this.readOnlyLocks.push(lock); }

  disableReadOnlyMode(lock:string):void { this.readOnlyLocks = this.readOnlyLocks.filter((l) => l !== lock); }
}

const runResource = (id:string, status:string, events:unknown[]) => ({
  _type: 'AITextTransformRun', id, status, events,
});

const fixGrammar = { id: 1, label: 'Fix grammar', position: 1, injectsTypeTemplate: false };

describe('AiActionsService', () => {
  let service:AiActionsService;
  let httpMock:HttpTestingController;
  let toasts:{ type:string, message:string }[];
  let editor:FakeEditor;

  beforeEach(() => {
    toasts = [];
    const toastStub = {
      addSuccess: (message:string) => { toasts.push({ type: 'success', message }); },
      addError: (message:string) => { toasts.push({ type: 'error', message }); },
      addNotice: (message:string) => { const toast = { type: 'notice', message }; toasts.push(toast); return toast; },
      remove: (toast:{ type:string, message:string }) => { toasts = toasts.filter((t) => t !== toast); },
    };

    TestBed.configureTestingModule({
      providers: [
        AiActionsService,
        { provide: ToastService, useValue: toastStub },
        { provide: I18nService, useValue: { t: (key:string, options?:Record<string, unknown>) => `${key}${options ? JSON.stringify(options) : ''}` } },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(AiActionsService);
    service.delay = () => Promise.resolve();
    httpMock = TestBed.inject(HttpTestingController);
    editor = new FakeEditor();
  });

  afterEach(() => httpMock.verify());

  const nextRequest = async (urlPart:string) => {
    for (let attempt = 0; attempt < 50; attempt++) {
      const [request] = httpMock.match((req) => req.url.includes(urlPart));
      if (request) return request;
      await new Promise((resolve) => { setTimeout(resolve, 0); });
    }
    throw new Error(`no request for ${urlPart}`);
  };

  describe('run', () => {
    it('ignores a second selection while a run is active on the same editor', async () => {
      const first = service.run(fixGrammar, editor, existingWorkPackage);
      const second = service.run({ ...fixGrammar, id: 2, label: 'Make concise' }, editor, existingWorkPackage);

      const create = await nextRequest('/api/v3/ai_text_transform_runs');
      await second;
      expect(httpMock.match(() => true)).toEqual([]);
      expect(create.request.body).toMatchObject({ actionId: 1 });

      create.flush(runResource('run-6', 'queued', []), { status: 202, statusText: 'Accepted' });
      (await nextRequest('run-6?after=0')).flush(runResource('run-6', 'succeeded', [
        { seq: 1, kind: 'completed', payload: { text: 'Done' } },
      ]));

      await first;
      expect(editor.inserted).toBe('Done');
      expect(editor.readOnlyLocks).toEqual([]);
      expect(toasts.filter((t) => t.type === 'success')).toHaveLength(1);
    });

    it('leaves the content untouched and reports an error when the run completes without text', async () => {
      const promise = service.run(fixGrammar, editor, existingWorkPackage);

      (await nextRequest('/api/v3/ai_text_transform_runs')).flush(runResource('run-4', 'queued', []), { status: 202, statusText: 'Accepted' });
      (await nextRequest('run-4?after=0')).flush(runResource('run-4', 'succeeded', [
        { seq: 1, kind: 'completed', payload: { text: '  ' } },
      ]));

      await promise;
      expect(editor.inserted).toBeNull();
      expect(editor.readOnlyLocks).toEqual([]);
      expect(toasts).toEqual([{ type: 'error', message: 'js.editor.ai_actions.failed' }]);
    });

    it('unlocks the editor and reports a timeout when a request never answers', async () => {
      service.requestTimeout = 20;
      const promise = service.run(fixGrammar, editor, existingWorkPackage);

      await nextRequest('/api/v3/ai_text_transform_runs');

      await promise;
      expect(editor.inserted).toBeNull();
      expect(editor.readOnlyLocks).toEqual([]);
      expect(toasts).toEqual([{ type: 'error', message: 'js.editor.ai_actions.timeout' }]);
    });

    it('cancels the run and applies nothing once the editor is destroyed', async () => {
      const promise = service.run(fixGrammar, editor, existingWorkPackage);

      (await nextRequest('/api/v3/ai_text_transform_runs')).flush(runResource('run-5', 'queued', []), { status: 202, statusText: 'Accepted' });
      (await nextRequest('run-5?after=0')).flush(runResource('run-5', 'running', [
        { seq: 1, kind: 'status', payload: { status: 'running' } },
      ]));
      editor.destroy();
      (await nextRequest('run-5/cancel')).flush(null, { status: 204, statusText: 'No Content' });

      await promise;
      expect(editor.inserted).toBeNull();
      expect(toasts).toEqual([]);
    });

    it('replaces the editor content with the completed text once the run succeeds', async () => {
      const promise = service.run(fixGrammar, editor, existingWorkPackage);

      const create = await nextRequest('/api/v3/ai_text_transform_runs');
      expect(create.request.method).toBe('POST');
      expect(create.request.body).toEqual({ actionId: 1, content: '# Old text', workPackageId: '123' });
      expect(editor.readOnlyLocks).toEqual(['ai-actions']);
      create.flush(runResource('run-1', 'queued', []), { status: 202, statusText: 'Accepted' });

      const firstPoll = await nextRequest('/api/v3/ai_text_transform_runs/run-1?after=0');
      firstPoll.flush(runResource('run-1', 'running', [
        { seq: 1, kind: 'status', payload: { status: 'running' } },
        { seq: 2, kind: 'text_delta', payload: { delta: 'Hello' } },
      ]));

      const secondPoll = await nextRequest('/api/v3/ai_text_transform_runs/run-1?after=2');
      secondPoll.flush(runResource('run-1', 'succeeded', [
        { seq: 3, kind: 'completed', payload: { text: 'Hello world' } },
      ]));

      await promise;
      expect(editor.inserted).toBe('Hello world');
      expect(editor.readOnlyLocks).toEqual([]);
      expect(toasts).toEqual([{ type: 'success', message: 'js.editor.ai_actions.succeeded{"action":"Fix grammar"}' }]);
    });

    it('leaves the content untouched and reports the error when the run fails', async () => {
      const promise = service.run(fixGrammar, editor, existingWorkPackage);

      (await nextRequest('/api/v3/ai_text_transform_runs')).flush(runResource('run-2', 'queued', []), { status: 202, statusText: 'Accepted' });
      (await nextRequest('run-2?after=0')).flush(runResource('run-2', 'failed', [
        { seq: 1, kind: 'error', payload: { message: 'The AI service did not respond in time.', reason: 'timeout' } },
      ]));

      await promise;
      expect(editor.inserted).toBeNull();
      expect(editor.readOnlyLocks).toEqual([]);
      expect(toasts).toEqual([{ type: 'error', message: 'The AI service did not respond in time.' }]);
    });

    it('leaves the content untouched and reports the message when the run cannot be created', async () => {
      const promise = service.run(fixGrammar, editor, existingWorkPackage);

      (await nextRequest('/api/v3/ai_text_transform_runs')).flush(
        { _type: 'Error', message: 'This AI action is not active.' },
        { status: 422, statusText: 'Unprocessable Content' },
      );

      await promise;
      expect(editor.inserted).toBeNull();
      expect(editor.readOnlyLocks).toEqual([]);
      expect(toasts).toEqual([{ type: 'error', message: 'This AI action is not active.' }]);
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
