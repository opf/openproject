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

import { destructiveControlAttribute } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { cellIntent, walkIntent } from './key-intent';

const keydown = (key:string, init:KeyboardEventInit = {}) => new KeyboardEvent('keydown', { key, ...init });

const withAltGraph = (event:KeyboardEvent):KeyboardEvent => {
  vi.spyOn(event, 'getModifierState').mockImplementation((key) => key === 'AltGraph');
  return event;
};

describe('cellIntent', () => {
  it.each<[string, KeyboardEventInit, unknown]>([
    ['ArrowDown', {}, { type: 'move', command: 'ArrowDown' }],
    ['PageUp', {}, { type: 'move', command: 'PageUp' }],
    ['Home', { ctrlKey: true }, { type: 'move', command: 'CtrlHome' }],
    ['End', { metaKey: true }, { type: 'move', command: 'CtrlEnd' }],
    ['ArrowDown', { ctrlKey: true }, { type: 'none' }],
    ['ArrowDown', { metaKey: true }, { type: 'none' }],
    ['ArrowDown', { altKey: true }, { type: 'none' }],
    ['ArrowDown', { isComposing: true }, { type: 'none' }],
    ['Home', { ctrlKey: true, shiftKey: true }, { type: 'none' }],
    ['Enter', {}, { type: 'activate', key: 'Enter' }],
    ['F2', {}, { type: 'activate', key: 'F2' }],
    ['Enter', { ctrlKey: true }, { type: 'none' }],
    ['Enter', { shiftKey: true }, { type: 'none' }],
    ['a', {}, { type: 'none' }],
    ['constructor', {}, { type: 'none' }],
    ['toString', { ctrlKey: true }, { type: 'none' }],
    ['ArrowDown', { shiftKey: true }, { type: 'selection', chord: 'extend', command: 'ArrowDown' }],
    ['ArrowUp', { shiftKey: true }, { type: 'selection', chord: 'extend', command: 'ArrowUp' }],
    [' ', { shiftKey: true }, { type: 'selection', chord: 'toggle' }],
    ['a', { ctrlKey: true }, { type: 'selection', chord: 'selectAll' }],
  ])('classifies %s %o as %o', (key, init, intent) => {
    expect(cellIntent(keydown(key, init), false)).toEqual(intent);
  });

  it('ignores an AltGraph arrow', () => {
    expect(cellIntent(withAltGraph(keydown('ArrowDown')), false)).toEqual({ type: 'none' });
  });

  it('takes Meta+A as select all on Apple platforms', () => {
    expect(cellIntent(keydown('a', { metaKey: true }), true)).toEqual({ type: 'selection', chord: 'selectAll' });
  });
});

describe('walkIntent', () => {
  it.each<[string, KeyboardEventInit, unknown]>([
    ['ArrowDown', {}, { type: 'leave', command: 'ArrowDown' }],
    ['Home', {}, { type: 'leave', command: 'Home' }],
    ['ArrowDown', { ctrlKey: true }, { type: 'leave', command: null }],
    ['ArrowDown', { metaKey: true }, { type: 'leave', command: null }],
    ['Home', { ctrlKey: true }, { type: 'leave', command: 'CtrlHome' }],
    ['ArrowDown', { isComposing: true }, { type: 'none' }],
    ['ArrowDown', { ctrlKey: true, altKey: true }, { type: 'none' }],
    ['ArrowDown', { shiftKey: true }, { type: 'none' }],
    ['ArrowDown', { altKey: true }, { type: 'none' }],
    ['Tab', {}, { type: 'tab' }],
    ['Tab', { shiftKey: true }, { type: 'tab' }],
    ['Escape', {}, { type: 'escape' }],
    ['Enter', {}, { type: 'none' }],
    ['a', {}, { type: 'none' }],
    ['constructor', {}, { type: 'none' }],
    ['__proto__', {}, { type: 'none' }],
  ])('classifies %s %o as %o', (key, init, intent) => {
    expect(walkIntent(keydown(key, init))).toEqual(intent);
  });

  it('ignores an AltGraph arrow', () => {
    expect(walkIntent(withAltGraph(keydown('ArrowDown')))).toEqual({ type: 'none' });
  });

  it('flags a repeated Enter on a destructive control', () => {
    const control = document.createElement('button');
    control.setAttribute(destructiveControlAttribute, '');
    document.body.append(control);
    const event = new KeyboardEvent('keydown', { key: 'Enter', repeat: true, bubbles: true });
    let intent:unknown;
    control.addEventListener('keydown', (received) => { intent = walkIntent(received); });

    control.dispatchEvent(event);

    expect(intent).toEqual({ type: 'destructiveRepeat' });
    control.remove();
  });

  it('leaves a single Enter on a destructive control alone', () => {
    const control = document.createElement('button');
    control.setAttribute(destructiveControlAttribute, '');
    document.body.append(control);
    let intent:unknown;
    control.addEventListener('keydown', (received) => { intent = walkIntent(received); });

    control.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));

    expect(intent).toEqual({ type: 'none' });
    control.remove();
  });
});
