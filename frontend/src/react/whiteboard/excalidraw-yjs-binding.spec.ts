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

import { mutateElement } from '@excalidraw/excalidraw';
import type { OrderedExcalidrawElement } from '@excalidraw/excalidraw/element/types';
import type { AppState, ExcalidrawImperativeAPI, SceneData } from '@excalidraw/excalidraw/types';
import * as Y from 'yjs';
import { ExcalidrawYjsBinding, WHITEBOARD_ELEMENTS_KEY } from './excalidraw-yjs-binding';

class FakeExcalidraw {
  elements:OrderedExcalidrawElement[] = [];
  updates:SceneData[] = [];

  readonly api = {
    getSceneElementsIncludingDeleted: () => this.elements,
    getAppState: () => ({ editingTextElement: null, resizingElement: null, newElement: null }) as unknown as AppState,
    updateScene: (scene:SceneData) => {
      this.updates.push(scene);
      if (scene.elements) this.elements = scene.elements as OrderedExcalidrawElement[];
    },
  } as unknown as ExcalidrawImperativeAPI;
}

function rectangle(id:string, version:number, overrides:Partial<OrderedExcalidrawElement> = {}) {
  return {
    id,
    type: 'rectangle',
    x: 0,
    y: 0,
    width: 10,
    height: 10,
    version,
    versionNonce: version,
    index: 'a0',
    isDeleted: false,
    ...overrides,
  } as OrderedExcalidrawElement;
}

const nextFrame = () => new Promise<void>((resolve) => { requestAnimationFrame(() => resolve()); });

function connect(a:Y.Doc, b:Y.Doc) {
  a.on('update', (update:Uint8Array, origin:unknown) => { if (origin !== b) Y.applyUpdate(b, update, a); });
  b.on('update', (update:Uint8Array, origin:unknown) => { if (origin !== a) Y.applyUpdate(a, update, b); });
}

describe('ExcalidrawYjsBinding', () => {
  let docA:Y.Doc;
  let docB:Y.Doc;
  let editorA:FakeExcalidraw;
  let editorB:FakeExcalidraw;
  let bindingA:ExcalidrawYjsBinding;
  let bindingB:ExcalidrawYjsBinding;

  beforeEach(() => {
    docA = new Y.Doc();
    docB = new Y.Doc();
    connect(docA, docB);
    editorA = new FakeExcalidraw();
    editorB = new FakeExcalidraw();
    bindingA = new ExcalidrawYjsBinding(docA, editorA.api, false);
    bindingB = new ExcalidrawYjsBinding(docB, editorB.api, false);
  });

  afterEach(() => {
    bindingA.destroy();
    bindingB.destroy();
  });

  it('propagates a local element to the other editor', async () => {
    editorA.elements = [rectangle('r1', 1)];
    bindingA.onSceneChange(editorA.elements);
    await nextFrame();
    await nextFrame();

    expect(docB.getMap(WHITEBOARD_ELEMENTS_KEY).has('r1')).toBe(true);
    expect(editorB.elements.map((element) => element.id)).toEqual(['r1']);
  });

  it('does not write elements that are not newer than the stored version', async () => {
    docA.getMap(WHITEBOARD_ELEMENTS_KEY).set('r1', rectangle('r1', 5, { x: 99 }));
    const updates = vi.fn();
    docA.on('update', updates);

    bindingA.onSceneChange([rectangle('r1', 5, { x: 1 })]);
    await nextFrame();

    expect(updates).not.toHaveBeenCalled();
    expect((docA.getMap(WHITEBOARD_ELEMENTS_KEY).get('r1') as OrderedExcalidrawElement).x).toBe(99);
  });

  it('syncs undo, which re-applies an older state with a higher version', async () => {
    bindingA.onSceneChange([rectangle('r1', 1, { x: 0 })]);
    await nextFrame();
    bindingA.onSceneChange([rectangle('r1', 2, { x: 50 })]);
    await nextFrame();
    bindingA.onSceneChange([rectangle('r1', 3, { x: 0 })]);
    await nextFrame();
    await nextFrame();

    expect(editorB.elements[0].x).toBe(0);
    expect(editorB.elements[0].version).toBe(3);
  });

  it('keeps deletions as tombstones', async () => {
    bindingA.onSceneChange([rectangle('r1', 1)]);
    await nextFrame();
    bindingA.onSceneChange([rectangle('r1', 2, { isDeleted: true })]);
    await nextFrame();
    await nextFrame();

    expect((docB.getMap(WHITEBOARD_ELEMENTS_KEY).get('r1') as OrderedExcalidrawElement).isDeleted).toBe(true);
    expect(editorB.elements[0].isDeleted).toBe(true);
  });

  it('applies remote changes without capturing them in the local undo history', async () => {
    bindingA.onSceneChange([rectangle('r1', 1)]);
    await nextFrame();
    await nextFrame();

    expect(editorB.updates.at(-1)?.captureUpdate).toBe('NEVER');
  });

  it('converges when two users concurrently edit the same element to the same version', async () => {
    const isolatedA = new Y.Doc();
    const isolatedB = new Y.Doc();
    const alice = new FakeExcalidraw();
    const bob = new FakeExcalidraw();
    const aliceBinding = new ExcalidrawYjsBinding(isolatedA, alice.api, false);
    const bobBinding = new ExcalidrawYjsBinding(isolatedB, bob.api, false);

    alice.elements = [rectangle('r1', 2, { x: 100, versionNonce: 900 })];
    aliceBinding.onSceneChange(alice.elements);
    bob.elements = [rectangle('r1', 2, { x: 200, versionNonce: 1 })];
    bobBinding.onSceneChange(bob.elements);
    await nextFrame();

    Y.applyUpdate(isolatedB, Y.encodeStateAsUpdate(isolatedA));
    Y.applyUpdate(isolatedA, Y.encodeStateAsUpdate(isolatedB));
    await nextFrame();
    await nextFrame();

    const stored = isolatedA.getMap(WHITEBOARD_ELEMENTS_KEY).get('r1') as OrderedExcalidrawElement;
    expect(alice.elements[0].x).toBe(stored.x);
    expect(bob.elements[0].x).toBe(stored.x);

    aliceBinding.destroy();
    bobBinding.destroy();
  });

  it('flushes pending local changes when the page is hidden', () => {
    bindingA.onSceneChange([rectangle('r1', 1)]);

    window.dispatchEvent(new Event('pagehide'));

    expect(docA.getMap(WHITEBOARD_ELEMENTS_KEY).has('r1')).toBe(true);
  });

  it('syncs edits Excalidraw makes by mutating an element in place', async () => {
    const element = rectangle('r1', 1, { width: 0, height: 0 });
    bindingA.onSceneChange([element]);
    await nextFrame();

    const updates = vi.fn();
    docA.on('update', updates);
    mutateElement(element, { width: 120, height: 80 });
    bindingA.onSceneChange([element]);
    await nextFrame();
    await nextFrame();

    expect(updates).toHaveBeenCalled();
    const stored = docA.getMap(WHITEBOARD_ELEMENTS_KEY).get('r1') as OrderedExcalidrawElement;
    expect(stored).not.toBe(element);
    expect(stored.width).toBe(120);
    expect(editorB.elements[0].width).toBe(120);
  });

  it('never hands stored Y.Map values to Excalidraw', () => {
    docA.getMap(WHITEBOARD_ELEMENTS_KEY).set('r1', rectangle('r1', 1));

    const [restored] = ExcalidrawYjsBinding.storedElements(docA);

    expect(restored).not.toBe(docA.getMap(WHITEBOARD_ELEMENTS_KEY).get('r1'));
  });

  it('never writes for read-only users', async () => {
    const readOnlyDoc = new Y.Doc();
    const binding = new ExcalidrawYjsBinding(readOnlyDoc, new FakeExcalidraw().api, true);

    binding.onSceneChange([rectangle('r1', 1)]);
    await nextFrame();
    binding.destroy();

    expect(readOnlyDoc.getMap(WHITEBOARD_ELEMENTS_KEY).size).toBe(0);
  });
});
