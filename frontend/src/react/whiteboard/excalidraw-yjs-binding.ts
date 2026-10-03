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

import { CaptureUpdateAction, reconcileElements, restoreElements } from '@excalidraw/excalidraw';
import type { RemoteExcalidrawElement } from '@excalidraw/excalidraw/data/reconcile';
import type { OrderedExcalidrawElement } from '@excalidraw/excalidraw/element/types';
import type { ExcalidrawImperativeAPI } from '@excalidraw/excalidraw/types';
import * as Y from 'yjs';

export const WHITEBOARD_ELEMENTS_KEY = 'elements';

/**
 * Syncs the Excalidraw scene with a Y.Doc.
 *
 * Every element is stored as a whole under its id in a Y.Map, deletions stay as
 * `isDeleted` tombstones so stale clients cannot resurrect them. Excalidraw bumps
 * `version` on every mutation (including undo/redo), so a local element is only
 * written when it is newer than the stored one. Remote updates are merged with
 * Excalidraw's own `reconcileElements` and applied without being captured in the
 * local undo history.
 */
export class ExcalidrawYjsBinding {
  private readonly elements:Y.Map<OrderedExcalidrawElement>;
  private readonly localOrigin = {};
  private pendingLocal:readonly OrderedExcalidrawElement[]|null = null;
  private localFrame:number|null = null;
  private remoteFrame:number|null = null;

  static storedElements(doc:Y.Doc):OrderedExcalidrawElement[] {
    const stored = Array.from(doc.getMap<OrderedExcalidrawElement>(WHITEBOARD_ELEMENTS_KEY).values());
    return restoreElements(stored, null);
  }

  constructor(
    private readonly doc:Y.Doc,
    private readonly api:ExcalidrawImperativeAPI,
    private readonly readOnly:boolean,
  ) {
    this.elements = doc.getMap(WHITEBOARD_ELEMENTS_KEY);
    this.elements.observe(this.onYjsChange);
  }

  destroy():void {
    this.elements.unobserve(this.onYjsChange);
    if (this.localFrame !== null) cancelAnimationFrame(this.localFrame);
    if (this.remoteFrame !== null) cancelAnimationFrame(this.remoteFrame);
    this.flushLocal();
  }

  onSceneChange(elements:readonly OrderedExcalidrawElement[]):void {
    if (this.readOnly) return;

    this.pendingLocal = elements;
    this.localFrame ??= requestAnimationFrame(() => {
      this.localFrame = null;
      this.flushLocal();
    });
  }

  private flushLocal():void {
    const elements = this.pendingLocal;
    this.pendingLocal = null;
    if (!elements) return;

    const changed = elements.filter((element) => {
      const stored = this.elements.get(element.id);
      return !stored || stored.version < element.version;
    });
    if (changed.length === 0) return;

    this.doc.transact(() => {
      changed.forEach((element) => this.elements.set(element.id, element));
    }, this.localOrigin);
  }

  private onYjsChange = (_event:Y.YMapEvent<OrderedExcalidrawElement>, transaction:Y.Transaction):void => {
    if (transaction.origin === this.localOrigin) return;

    this.remoteFrame ??= requestAnimationFrame(() => {
      this.remoteFrame = null;
      this.applyRemote();
    });
  };

  private applyRemote():void {
    const remote = ExcalidrawYjsBinding.storedElements(this.doc) as RemoteExcalidrawElement[];
    const reconciled = reconcileElements(
      this.api.getSceneElementsIncludingDeleted(),
      remote,
      this.api.getAppState(),
    );

    this.api.updateScene({ elements: reconciled, captureUpdate: CaptureUpdateAction.NEVER });
  }
}
