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

import type { DigestedGroup, DigestedMore, SummaryGroup, SummaryMore } from './notification-plan';

export class Digest {
  static async of(...parts:string[]):Promise<string> {
    const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(JSON.stringify(parts)));
    return Array.from(new Uint8Array(bytes), (byte) => byte.toString(16).padStart(2, '0')).join('');
  }

  static async addTo({ groups, more }:{ groups:SummaryGroup[]; more?:SummaryMore }):Promise<{ groups:DigestedGroup[]; more?:DigestedMore }> {
    const moreWithDigest = more && { ...more, digest: await Digest.of(more.title) };
    const reversed:DigestedGroup[] = [];
    for (const group of [...groups].reverse()) {
      reversed.push({ ...group, digest: await Digest.of(group.revision, group.title, group.body ?? '') });
    }
    return { groups: reversed.reverse(), more: moreWithDigest };
  }
}
