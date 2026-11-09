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

import { isApplePlatform } from 'core-common/platform';

export const NAVIGATION_KEYS = {
  plain: {
    ArrowUp: 'ArrowUp',
    ArrowDown: 'ArrowDown',
    ArrowLeft: 'ArrowLeft',
    ArrowRight: 'ArrowRight',
    Home: 'Home',
    End: 'End',
    PageUp: 'PageUp',
    PageDown: 'PageDown',
  },
  command: {
    Home: 'CtrlHome',
    End: 'CtrlEnd',
  },
} as const satisfies Record<'plain'|'command', Partial<Record<string, string>>>;

type CommandsOf<Section extends keyof typeof NAVIGATION_KEYS> = (typeof NAVIGATION_KEYS)[Section][keyof (typeof NAVIGATION_KEYS)[Section]];

export type NavigationCommand = CommandsOf<'plain'>|CommandsOf<'command'>;

/** `ctrlOrMeta` takes either key as the command modifier; `platform` takes Meta on Apple platforms and Ctrl elsewhere. */
export type CommandModifier = 'ctrlOrMeta'|'platform';

export type ModifierClass = 'plain'|'command'|'shift'|'other';

function commandHeld(event:KeyboardEvent, commandModifier:CommandModifier):boolean|null {
  if (commandModifier === 'ctrlOrMeta') return event.ctrlKey || event.metaKey;

  const apple = isApplePlatform();
  const command = apple ? event.metaKey : event.ctrlKey;
  const foreign = apple ? event.ctrlKey : event.metaKey;
  return foreign ? null : command;
}

export function modifierClass(event:KeyboardEvent, commandModifier:CommandModifier):ModifierClass {
  if (event.isComposing || event.altKey || event.getModifierState('AltGraph')) return 'other';

  const command = commandHeld(event, commandModifier);
  if (command === null) return 'other';
  if (command) return event.shiftKey ? 'other' : 'command';
  return event.shiftKey ? 'shift' : 'plain';
}

export function navigationCommand(key:string, modifiers:'plain'|'command'):NavigationCommand|null {
  const section:Partial<Record<string, NavigationCommand>> = NAVIGATION_KEYS[modifiers];
  return Object.hasOwn(section, key) ? section[key] ?? null : null;
}
