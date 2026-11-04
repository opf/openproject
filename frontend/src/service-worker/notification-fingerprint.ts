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

import type { GroupWithFingerprint, MoreWithFingerprint, SummaryGroup, SummaryMore } from './notification-plan';

/**
 * Fingerprints what each notification shows, so the plan can tell whether an open notification
 * is out of date. The fingerprint covers the activity revision, title and body; a change refreshes
 * the notification silently, while only newer activity makes a sound.
 */
export class NotificationFingerprint {
  static async of(...parts:string[]):Promise<string> {
    const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(JSON.stringify(parts)));
    return Array.from(new Uint8Array(bytes), (byte) => byte.toString(16).padStart(2, '0')).join('');
  }

  static async addTo({ groups, more }:{ groups:SummaryGroup[]; more?:SummaryMore }):Promise<{ groups:GroupWithFingerprint[]; more?:MoreWithFingerprint }> {
    return {
      groups: await Promise.all(groups.map(async (group) => ({
        ...group,
        fingerprint: await NotificationFingerprint.of(group.revision, group.title, group.body ?? ''),
      }))),
      more: more && { ...more, fingerprint: await NotificationFingerprint.of(more.title) },
    };
  }
}
