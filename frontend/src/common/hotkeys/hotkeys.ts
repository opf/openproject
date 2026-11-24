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

import { normalizeSequence } from '@github/hotkey';
import definitions from 'core-config/hotkeys.json';

/** The hotkeys `OpenProject::Hotkeys` defines, shared with the backend through `config/hotkeys.json`. */
export const HOTKEYS:Readonly<typeof definitions.actions> = Object.freeze({ ...definitions.actions });

/** Every multi-key sequence the backend or frontend binds, normalized for the dispatcher. */
export const KNOWN_SEQUENCES:ReadonlySet<string> = new Set(
  Object.values(definitions)
    .flatMap((group) => Object.values(group))
    .flatMap((hotkey) => hotkey.split(','))
    .map((alternative) => alternative.trim())
    .filter((alternative) => alternative.includes(' '))
    .map((sequence) => normalizeSequence(sequence)),
);
