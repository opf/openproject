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

import { MAX_REMEMBERED_UNLISTED, Tags } from './constants';

export interface SummaryGroup {
  tag:string;
  title:string;
  body?:string;
  url:string;
  revision:string;
}

export interface SummaryMore {
  title:string;
  url:string;
}

export interface GroupWithFingerprint extends SummaryGroup {
  fingerprint:string;
}

export interface MoreWithFingerprint extends SummaryMore {
  fingerprint:string;
}

export interface StateEntry {
  fingerprint?:string;
  at?:number;
  evicted?:boolean;
}

export type PushStateMap = Record<string, StateEntry>;

export type NotificationAction =
  | { kind:'alert'|'refresh'; group:GroupWithFingerprint }
  | { kind:'more'; more:MoreWithFingerprint }
  | { kind:'fallback' }
  | { kind:'nothingNew' };

export interface NotificationDecision {
  show:NotificationAction[];
  state:PushStateMap;
}

/**
 * Decides what to show for an unread summary, without touching the browser.
 *
 * Each group is one work package. Compared with what was shown before, per group:
 *
 * ```
 * new activity since last shown ............................ alert  (sound, renotify)
 * else: open and its content changed, nothing but the
 *       placeholder open, or it was evicted earlier ........ refresh (silent, same tag)
 * else .................................................... skip
 * ```
 *
 * Only the newest five groups are listed; the rest collapse into one "more" notification. A group
 * that drops out of the list is closed and remembered as evicted, so it returns silently if it
 * comes back. Groups are shown oldest first so the newest ends on top.
 *
 * A push must end with something visible: if nothing qualifies, the newest group is refreshed when
 * it is open, otherwise a quiet "nothing new" notice shows, which does not bring dismissed groups
 * back. The refresh is needed even when that notification is already on screen: Safari only counts
 * a push that calls showNotification and drops every subscription of the site after three pushes
 * that did not.
 */
export class NotificationRules {
  static activityAt(group:SummaryGroup):number {
    return Number(group.revision.split(':')[1]) || 0;
  }

  static pruneUnlisted({ state, groups }:{ state:PushStateMap; groups:SummaryGroup[] }):PushStateMap {
    const listedTags = new Set([...groups.map((group) => group.tag), Tags.more]);
    const entries = Object.entries(state);
    const unlisted = entries
      .filter(([tag]) => !listedTags.has(tag))
      .sort(([, a], [, b]) => (b.at ?? 0) - (a.at ?? 0))
      .slice(0, MAX_REMEMBERED_UNLISTED);
    return Object.fromEntries([...entries.filter(([tag]) => listedTags.has(tag)), ...unlisted]);
  }

  static staleTags({ groups, more, openTags }:{ groups:SummaryGroup[]; more?:SummaryMore; openTags:string[] }):string[] {
    const keepTags = new Set(groups.map((group) => group.tag));
    if (more) keepTags.add(Tags.more);
    return openTags.filter((tag) => !keepTags.has(tag));
  }

  static isNewActivity(previous:StateEntry|undefined, at:number):boolean {
    return previous?.at === undefined || at > previous.at;
  }

  static needsRefresh({ group, previous, openTags }:{ group:GroupWithFingerprint; previous:StateEntry|undefined; openTags:string[] }):boolean {
    const onlyPlaceholderOpen = openTags.length > 0 && openTags.every((tag) => tag === Tags.placeholder);
    return (
      onlyPlaceholderOpen || !!previous?.evicted || (openTags.includes(group.tag) && previous?.fingerprint !== group.fingerprint)
    );
  }

  static evictedState(closeTags:string[], state:PushStateMap):PushStateMap {
    const evicted:PushStateMap = {};
    closeTags
      .filter((tag) => state[tag]?.at !== undefined)
      .forEach((tag) => {
        evicted[tag] = { ...state[tag], evicted: true };
      });
    return evicted;
  }

  static stateAfterClose({ closeTags, groups, more, state }:{
    closeTags:string[];
    groups:SummaryGroup[];
    more?:SummaryMore;
    state:PushStateMap;
  }):PushStateMap {
    const remaining = Object.fromEntries(Object.entries(state).filter(([tag]) => !closeTags.includes(tag)));
    if (!more) return remaining;

    return NotificationRules.pruneUnlisted({
      state: { ...remaining, ...NotificationRules.evictedState(closeTags, state) },
      groups,
    });
  }

  static decide({ groups, more, openTags, state }:{
    groups:GroupWithFingerprint[];
    more?:MoreWithFingerprint;
    openTags:string[];
    state:PushStateMap;
  }):NotificationDecision {
    const closeTags = NotificationRules.staleTags({ groups, more, openTags });
    const nextState:PushStateMap = {};
    const show:NotificationAction[] = [];

    if (more) {
      Object.assign(nextState, NotificationRules.evictedState(closeTags, state));
      nextState[Tags.more] = { fingerprint: more.fingerprint };
      if (state[Tags.more]?.fingerprint !== more.fingerprint || !openTags.includes(Tags.more)) {
        show.push({ kind: 'more', more });
      }
    }

    // Shown oldest first, so the newest ends on top.
    for (const group of [...groups].reverse()) {
      const previous:StateEntry|undefined = state[group.tag];
      const at = NotificationRules.activityAt(group);
      nextState[group.tag] = { fingerprint: group.fingerprint, at: Math.max(at, previous?.at ?? 0) };

      if (NotificationRules.isNewActivity(previous, at)) {
        show.push({ kind: 'alert', group });
      } else if (NotificationRules.needsRefresh({ group, previous, openTags })) {
        show.push({ kind: 'refresh', group });
      }
    }

    if (show.length === 0) {
      show.push(openTags.includes(groups[0].tag) ? { kind: 'refresh', group: groups[0] } : { kind: 'nothingNew' });
    }

    const nextRemembered = more ? NotificationRules.pruneUnlisted({ state: { ...state, ...nextState }, groups }) : nextState;
    return { show, state: nextRemembered };
  }
}
