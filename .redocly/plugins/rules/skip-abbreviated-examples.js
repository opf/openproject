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

function removeNodesWithKey(obj, key) {
  if (obj === null) return;
  if (typeof obj === 'string') return;
  if (typeof obj === 'number') return;

  if (Array.isArray(obj)) {
    for (let i = obj.length - 1; i >= 0; i--) {
      if (obj[i] === null) continue;
      if (obj[i][key] !== undefined) {
        obj.splice(i, 1);
      }
    }
  } else {
    const keys = Object.keys(obj);
    for (const k of keys) {
      if (obj[k] === null) continue;
      if (obj[k][key] !== undefined) {
        delete obj[k];
      }
    }
  }

  for (const k of Object.keys(obj)) {
    removeNodesWithKey(obj[k], key);
  }
}

export default function SkipAbbreviatedExamples() {
  return {
    Example: {
      enter(example, _ctx) {
        // remove every nested object with the `_abbreviated` key,
        // but keep the rest to be run against other rules.
        removeNodesWithKey(example.value, '_abbreviated');
      },
    },
  }
}
