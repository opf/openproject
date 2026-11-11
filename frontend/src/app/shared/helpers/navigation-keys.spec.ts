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

import { usePlatform } from 'core-common/testing/platform';
import { modifierClass, navigationCommand } from './navigation-keys';

const keydown = (init:KeyboardEventInit = {}) => new KeyboardEvent('keydown', { key: 'ArrowDown', ...init });

const withAltGraph = (event:KeyboardEvent):KeyboardEvent => {
  vi.spyOn(event, 'getModifierState').mockImplementation((key) => key === 'AltGraph');
  return event;
};

describe('navigationCommand', () => {
  it.each([
    ['ArrowUp', 'plain', 'ArrowUp'],
    ['ArrowDown', 'plain', 'ArrowDown'],
    ['ArrowLeft', 'plain', 'ArrowLeft'],
    ['ArrowRight', 'plain', 'ArrowRight'],
    ['Home', 'plain', 'Home'],
    ['End', 'plain', 'End'],
    ['PageUp', 'plain', 'PageUp'],
    ['PageDown', 'plain', 'PageDown'],
    ['Home', 'command', 'CtrlHome'],
    ['End', 'command', 'CtrlEnd'],
    ['ArrowDown', 'command', null],
    ['a', 'plain', null],
    ['constructor', 'plain', null],
    ['toString', 'command', null],
    ['__proto__', 'plain', null],
  ] as const)('maps %s with %s modifiers to %s', (key, modifiers, command) => {
    expect(navigationCommand(key, modifiers)).toBe(command);
  });
});

describe('modifierClass', () => {
  const pretendPlatform = usePlatform('Linux');

  it.each<[string, KeyboardEventInit, string]>([
    ['no modifier', {}, 'plain'],
    ['Ctrl', { ctrlKey: true }, 'command'],
    ['Meta', { metaKey: true }, 'command'],
    ['Shift', { shiftKey: true }, 'shift'],
    ['Alt', { altKey: true }, 'other'],
    ['composition', { isComposing: true }, 'other'],
    ['Ctrl+Shift', { ctrlKey: true, shiftKey: true }, 'other'],
  ])('classifies %s as %s with Ctrl or Meta as command', (_name, init, expected) => {
    expect(modifierClass(keydown(init), 'ctrlOrMeta')).toBe(expected);
  });

  it('classifies AltGraph as other', () => {
    expect(modifierClass(withAltGraph(keydown()), 'ctrlOrMeta')).toBe('other');
  });

  it('takes Ctrl as command and Meta as other off Apple platforms', () => {
    expect(modifierClass(keydown({ ctrlKey: true }), 'platform')).toBe('command');
    expect(modifierClass(keydown({ metaKey: true }), 'platform')).toBe('other');
  });

  it('takes Meta as command and Ctrl as other on Apple platforms', () => {
    pretendPlatform('macOS');

    expect(modifierClass(keydown({ metaKey: true }), 'platform')).toBe('command');
    expect(modifierClass(keydown({ ctrlKey: true }), 'platform')).toBe('other');
  });
});
