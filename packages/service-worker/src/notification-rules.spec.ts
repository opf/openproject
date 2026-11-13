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

import { NotificationRules, type GroupWithFingerprint, type MoreWithFingerprint, type PushStateMap } from './notification-rules';
import { Tags } from './constants';

const tagOf = (id:number) => `openproject-1-wp-${id}`;

const group = (id:number, at:number, fingerprint = `fingerprint-${id}`):GroupWithFingerprint => ({
  tag: tagOf(id),
  title: `Work package ${id}`,
  url: `/work_packages/${id}`,
  revision: `rev:${at}`,
  fingerprint,
});

const more = (fingerprint = 'more-fingerprint'):MoreWithFingerprint => ({ title: '3 more', url: '/notifications', fingerprint });

const decide = (input:{ groups?:GroupWithFingerprint[]; more?:MoreWithFingerprint; openTags?:string[]; state?:PushStateMap }) =>
  NotificationRules.decide({ groups: [], openTags: [], state: {}, ...input });

const remembered = (count:number, firstId = 100):PushStateMap =>
  Object.fromEntries(Array.from({ length: count }, (_, index) => [tagOf(firstId + index), { fingerprint: `f${index}`, at: index + 1 }]));

const kinds = (result:ReturnType<typeof decide>) => result.show.map((item) => item.kind);

describe('NotificationRules', () => {
  describe('per group', () => {
    it('alerts for a group shown for the first time', () => {
      const result = decide({ groups: [group(1, 100)] });

      expect(kinds(result)).toEqual(['alert']);
      expect(result.state[tagOf(1)]).toEqual({ fingerprint: 'fingerprint-1', at: 100 });
    });

    it('alerts when the group has newer activity than last shown', () => {
      const state = { [tagOf(1)]: { fingerprint: 'old', at: 100 } };

      const result = decide({ groups: [group(1, 200)], openTags: [tagOf(1)], state });

      expect(kinds(result)).toEqual(['alert']);
    });

    it('refreshes silently when an open group changed without newer activity', () => {
      const state = { [tagOf(1)]: { fingerprint: 'old', at: 100 } };

      const result = decide({ groups: [group(1, 100)], openTags: [tagOf(1)], state });

      expect(kinds(result)).toEqual(['refresh']);
    });

    it('skips a dismissed group that has not changed', () => {
      const state = {
        [tagOf(1)]: { fingerprint: 'old', at: 200 },
        [tagOf(2)]: { fingerprint: 'fingerprint-2', at: 100 },
      };

      const result = decide({ groups: [group(1, 200), group(2, 100)], openTags: [tagOf(1)], state });

      expect(result.show).toEqual([{ kind: 'refresh', group: group(1, 200) }]);
    });

    it('rebuilds silently when only the placeholder is open', () => {
      const state = { [tagOf(1)]: { fingerprint: 'fingerprint-1', at: 100 } };

      const result = decide({ groups: [group(1, 100)], openTags: [Tags.placeholder], state });

      expect(kinds(result)).toEqual(['refresh']);
    });

    it('shows the groups oldest first so the newest ends on top', () => {
      const result = decide({ groups: [group(2, 200), group(1, 100)] });

      expect(result.show.map((item) => item.kind === 'alert' && item.group.tag)).toEqual([tagOf(1), tagOf(2)]);
    });

    it('never moves the stored activity time back', () => {
      const state = { [tagOf(1)]: { fingerprint: 'old', at: 300 } };

      const result = decide({ groups: [group(1, 100)], openTags: [tagOf(1)], state });

      expect(result.state[tagOf(1)].at).toBe(300);
      expect(kinds(result)).toEqual(['refresh']);
    });

    it('treats a revision without a timestamp as time zero', () => {
      expect(NotificationRules.activityAt({ ...group(1, 0), revision: 'rev' })).toBe(0);
    });
  });

  describe('when nothing qualifies', () => {
    const state = { [tagOf(1)]: { fingerprint: 'fingerprint-1', at: 100 }, [tagOf(2)]: { fingerprint: 'fingerprint-2', at: 50 } };

    it('refreshes the newest group when it is open', () => {
      const result = decide({ groups: [group(1, 100)], openTags: [tagOf(1), tagOf(2)], state });

      expect(result.show).toEqual([{ kind: 'refresh', group: group(1, 100) }]);
    });

    it('shows a nothing-new notice when the newest group is not open', () => {
      const result = decide({ groups: [group(1, 100)], openTags: [tagOf(2)], state });

      expect(result.show).toEqual([{ kind: 'nothingNew' }]);
    });

    it('keeps dismissed groups closed after everything was dismissed', () => {
      const result = decide({ groups: [group(1, 100), group(2, 50)], openTags: [], state });

      expect(result.show).toEqual([{ kind: 'nothingNew' }]);
    });

    it('does not refresh any group when only the nothing-new notice is open', () => {
      const result = decide({ groups: [group(1, 100)], openTags: [Tags.nothingNew], state });

      expect(result.show).toEqual([{ kind: 'nothingNew' }]);
    });
  });

  describe('overflow into the "more" notification', () => {
    const stale = { [tagOf(2)]: { fingerprint: 'fingerprint-2', at: 50 } };

    it('remembers a group that dropped out of the list as evicted', () => {
      const result = decide({
        groups: [group(1, 100)], more: more(), openTags: [tagOf(1), tagOf(2), Tags.more], state: stale,
      });

      expect(result.state[tagOf(2)]).toEqual({ fingerprint: 'fingerprint-2', at: 50, evicted: true });
    });

    it('does not remember a stale tag that never had activity recorded', () => {
      const result = decide({ groups: [group(1, 100)], more: more(), openTags: [tagOf(1), 'openproject-wp-9'] });

      expect(result.state['openproject-wp-9']).toBeUndefined();
    });

    it('returns silently when an evicted group comes back without newer activity', () => {
      const state = { [tagOf(1)]: { fingerprint: 'fingerprint-1', at: 100, evicted: true } };

      const result = decide({ groups: [group(1, 100)], openTags: [tagOf(2)], state });

      expect(kinds(result)).toEqual(['refresh']);
    });

    it('alerts when an evicted group comes back with newer activity', () => {
      const state = { [tagOf(1)]: { fingerprint: 'fingerprint-1', at: 100, evicted: true } };

      const result = decide({ groups: [group(1, 200)], openTags: [tagOf(2)], state });

      expect(kinds(result)).toEqual(['alert']);
    });

    it('shows the "more" notification when it is not open', () => {
      const state = { ...stale, [Tags.more]: { fingerprint: 'more-fingerprint' } };

      const result = decide({ groups: [group(1, 100)], more: more(), openTags: [tagOf(1)], state });

      expect(kinds(result)).toContain('more');
    });

    it('does not reshow the "more" notification when it is open and unchanged', () => {
      const state = { [Tags.more]: { fingerprint: 'more-fingerprint' } };

      const result = decide({ groups: [group(1, 100)], more: more(), openTags: [tagOf(1), Tags.more], state });

      expect(kinds(result)).not.toContain('more');
    });

    it('keeps the state of groups that are not in the current list', () => {
      const result = decide({ groups: [group(1, 100)], more: more(), state: stale });

      expect(result.state[tagOf(2)]).toEqual({ fingerprint: 'fingerprint-2', at: 50 });
    });

    it('shows only the "more" notification when there are no groups', () => {
      const result = decide({ more: more() });

      expect(result.show).toEqual([{ kind: 'more', more: more() }]);
    });
  });

  describe('staleTags', () => {
    it('lists the open tags that are neither a listed group nor the "more" notification', () => {
      const openTags = [tagOf(1), tagOf(2), Tags.more, Tags.placeholder];

      const withMore = NotificationRules.staleTags({ groups: [group(1, 100)], more: more(), openTags });
      const withoutMore = NotificationRules.staleTags({ groups: [group(1, 100)], openTags });

      expect(withMore).toEqual([tagOf(2), Tags.placeholder]);
      expect(withoutMore).toEqual([tagOf(2), Tags.more, Tags.placeholder]);
    });

    it('lists every open tag when there are no groups and no overflow', () => {
      expect(NotificationRules.staleTags({ groups: [], openTags: [tagOf(1), Tags.more] })).toEqual([tagOf(1), Tags.more]);
    });
  });

  describe('remembered state bound', () => {
    const limit = 50;
    const stateWith = (count:number) => ({ ...remembered(count), [Tags.more]: { fingerprint: 'old' } });

    it('keeps only the newest unlisted entries while "more" exists', () => {
      const result = decide({ groups: [group(1, 100)], more: more(), openTags: [], state: remembered(limit + 10) });
      const unlisted = Object.keys(result.state).filter((tag) => tag !== tagOf(1) && tag !== Tags.more);

      expect(unlisted).toHaveLength(limit);
      expect(result.state[tagOf(100)]).toBeUndefined();
      expect(result.state[tagOf(109)]).toBeUndefined();
      expect(result.state[tagOf(110)]).toBeDefined();
      expect(result.state[tagOf(159)]).toBeDefined();
    });

    it('never prunes the listed groups or the "more" entry', () => {
      const listed = [group(1, 1), group(2, 2)];
      const result = decide({ groups: listed, more: more(), openTags: [], state: stateWith(limit + 10) });

      expect(Object.keys(result.state)).toEqual(expect.arrayContaining([tagOf(1), tagOf(2), Tags.more]));
      expect(result.state[tagOf(1)]?.at).toBe(1);
    });

    it('does not prune without "more"', () => {
      const result = decide({ groups: [group(1, 100)], openTags: [], state: remembered(limit + 10) });

      expect(Object.keys(result.state)).toEqual([tagOf(1)]);
    });

    it('prunes when closing notifications while "more" exists', () => {
      const state = { ...stateWith(limit + 10), [tagOf(1)]: { fingerprint: 'f', at: 500 } };
      const result = NotificationRules.stateAfterClose({
        closeTags: [tagOf(1)], groups: [group(2, 2)], more: more(), state,
      });
      const unlisted = Object.keys(result).filter((tag) => tag !== Tags.more);

      expect(unlisted).toHaveLength(limit);
      expect(result[tagOf(1)]).toEqual({ fingerprint: 'f', at: 500, evicted: true });
      expect(result[Tags.more]).toBeDefined();
      expect(result[tagOf(100)]).toBeUndefined();
    });
  });

  describe('stateAfterClose', () => {
    const state = {
      [tagOf(1)]: { fingerprint: 'd1', at: 100 },
      [tagOf(2)]: { fingerprint: 'd2', at: 50 },
    };

    it('forgets the closed groups when nothing collapsed into "more"', () => {
      const result = NotificationRules.stateAfterClose({ closeTags: [tagOf(2)], groups: [], state });

      expect(result).toEqual({ [tagOf(1)]: state[tagOf(1)] });
    });

    it('remembers the closed groups as evicted when more are collapsed', () => {
      const result = NotificationRules.stateAfterClose({ closeTags: [tagOf(2)], groups: [group(1, 100)], more: more(), state });

      expect(result).toEqual({
        [tagOf(1)]: state[tagOf(1)],
        [tagOf(2)]: { fingerprint: 'd2', at: 50, evicted: true },
      });
    });
  });
});
