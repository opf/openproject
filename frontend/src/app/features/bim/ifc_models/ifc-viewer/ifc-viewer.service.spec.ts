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
import { IFCViewerService, XeokitBimViewer } from './ifc-viewer.service';

interface FakeViewer { viewer:Partial<XeokitBimViewer['viewer']> }
const asViewer = (fake:FakeViewer) => fake as XeokitBimViewer;

describe('IFCViewerService#handlesKey', () => {
  let service:IFCViewerService;

  const keydown = (keyCode:number) => new KeyboardEvent('keydown', { keyCode });

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [IFCViewerService] });
    service = TestBed.inject(IFCViewerService);
  });

  it('is false without a viewer', () => {
    expect(service.handlesKey(keydown(83))).toBe(false);
  });

  describe('with a viewer', () => {
    beforeEach(() => {
      const keyMap = { dollyBackwards: [83, 109], panLeft: [[17, 65]], axisViewTop: [] };
      service.viewer = asViewer({ viewer: { cameraControl: { keyMap } } });
    });

    it('is true for a key the camera control maps', () => {
      expect(service.handlesKey(keydown(83))).toBe(true);
    });

    it('is true for a key in a mapped key combination', () => {
      expect(service.handlesKey(keydown(65))).toBe(true);
    });

    it('is false for a key the camera control does not map', () => {
      expect(service.handlesKey(keydown(74))).toBe(false);
    });
  });
});

describe('IFCViewerService#releaseHeldKeys', () => {
  let service:IFCViewerService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [IFCViewerService] });
    service = TestBed.inject(IFCViewerService);
  });

  let releasedKeys:number[];
  const canvas = document.createElement('canvas');
  canvas.addEventListener('keyup', (event) => releasedKeys.push(event.keyCode));

  beforeEach(() => {
    releasedKeys = [];
  });

  it('does nothing without a viewer', () => {
    service.releaseHeldKeys(canvas);

    expect(releasedKeys).toEqual([]);
  });

  it('replays a keyup at the keyboard events element for every held key', () => {
    const keyDown:boolean[] = [];
    keyDown[9] = true;
    keyDown[74] = true;
    keyDown[83] = false;
    service.viewer = asViewer({ viewer: { scene: { input: { keyDown } } } });

    service.releaseHeldKeys(canvas);

    expect(releasedKeys).toEqual([9, 74]);
  });
});
