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

import {
  modifierClass, NAVIGATION_KEYS, navigationCommand, type NavigationCommand,
} from 'core-app/shared/helpers/navigation-keys';
import { destructiveControlAttribute } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { selectionChord, type SelectionChord } from './keyboard-selection';

export type KeyIntent =
  | { type:'move', command:NavigationCommand }
  | { type:'selection', chord:Exclude<SelectionChord, 'extend'> }
  | { type:'selection', chord:'extend', command:NavigationCommand }
  | { type:'activate', key:'Enter'|'F2' }
  | { type:'none' };

export type ActivationKey = Extract<KeyIntent, { type:'activate' }>['key'];

/** `leave` returns focus to the walk origin, then moves by `command` when there is one. */
export type WalkIntent =
  | { type:'leave', command:NavigationCommand|null }
  | { type:'escape' }
  | { type:'tab' }
  | { type:'destructiveRepeat' }
  | { type:'none' };

const NONE = { type: 'none' } as const;

export function cellIntent(event:KeyboardEvent, applePlatform:boolean):KeyIntent {
  const chord = selectionChord(event, applePlatform);
  if (chord === 'extend') {
    const command = navigationCommand(event.key, 'plain');
    return command ? { type: 'selection', chord, command } : NONE;
  }

  if (chord) {
    return { type: 'selection', chord };
  }

  const modifiers = modifierClass(event, 'ctrlOrMeta');
  if (modifiers === 'other' || modifiers === 'shift') return NONE;

  if (modifiers === 'plain' && (event.key === 'Enter' || event.key === 'F2')) {
    return { type: 'activate', key: event.key };
  }

  const command = navigationCommand(event.key, modifiers);
  return command ? { type: 'move', command } : NONE;
}

export function walkIntent(event:KeyboardEvent):WalkIntent {
  if (event.key === 'Enter' && event.repeat && event.target instanceof Element && event.target.closest(`[${destructiveControlAttribute}]`)) {
    return { type: 'destructiveRepeat' };
  }
  if (event.key === 'Tab') return { type: 'tab' };
  if (event.key === 'Escape') return { type: 'escape' };

  const modifiers = modifierClass(event, 'ctrlOrMeta');
  if (modifiers === 'other' || modifiers === 'shift' || !Object.hasOwn(NAVIGATION_KEYS.plain, event.key)) return NONE;

  return { type: 'leave', command: navigationCommand(event.key, modifiers) };
}
