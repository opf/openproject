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

import { LiveRegionElement } from '@primer/live-region-element';
import { type MockInstance } from 'vitest';
import { SelectionAnnouncements } from './selection-announcements';

describe('SelectionAnnouncements', () => {
  let announceSpy:MockInstance<typeof LiveRegionElement.prototype.announce>;
  let announcements:SelectionAnnouncements;

  const keys = (...values:string[]) => new Set(values);

  beforeEach(() => {
    document.body.append(document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
    window.I18n.store({
      en: {
        test: {
          selection: {
            selected: { one: '1 item selected.', other: '%{count} items selected.' },
            cleared: 'Selection cleared.',
            all_selected: { other: 'All %{count} items selected.' },
          },
        },
      },
    });
    announcements = new SelectionAnnouncements(() => 'test.selection');
  });

  afterEach(() => {
    document.querySelector('live-region')?.remove();
    announceSpy.mockRestore();
  });

  it('selection gesture speaks on a size change', () => {
    expect(announcements.commit('selection', keys('a', 'b'))).toBe(true);

    expect(announceSpy).toHaveBeenCalledTimes(1);
    expect(announceSpy).toHaveBeenCalledWith('2 items selected.', { politeness: 'polite' });
  });

  it('selection gesture speaks on a same-count replacement', () => {
    announcements.rebase(keys('a'));

    announcements.commit('selection', keys('b'));

    expect(announceSpy).toHaveBeenCalledTimes(1);
  });

  it('selection gesture stays silent when membership is unchanged', () => {
    announcements.rebase(keys('a', 'b'));

    expect(announcements.commit('selection', keys('a', 'b'))).toBe(false);

    expect(announceSpy).not.toHaveBeenCalled();
  });

  it('navigation gesture speaks only when a batch collapsed', () => {
    announcements.rebase(keys('a', 'b'));
    announcements.commit('navigation', keys('a'));
    expect(announceSpy).toHaveBeenCalledTimes(1);

    announcements.commit('navigation', keys('b'));
    expect(announceSpy).toHaveBeenCalledTimes(1);

    announcements.rebase(keys());
    announcements.commit('navigation', keys('a'));
    expect(announceSpy).toHaveBeenCalledTimes(1);
  });

  it('speaks cleared when the selection empties', () => {
    announcements.rebase(keys('a', 'b'));

    announcements.commit('selection', keys());

    expect(announceSpy).toHaveBeenCalledWith('Selection cleared.', { politeness: 'polite' });
  });

  it('rebase is silent and moves the baseline', () => {
    announcements.rebase(keys('a'));

    announcements.commit('selection', keys('a'));

    expect(announceSpy).not.toHaveBeenCalled();
    expect(announcements.baseline).toEqual(keys('a'));
  });

  it('commit against an explicit previous ignores the baseline', () => {
    announcements.rebase(keys('a'));

    announcements.commit('selection', keys('a'), keys());

    expect(announceSpy).toHaveBeenCalledTimes(1);
  });

  it('speak always announces with the given count', () => {
    announcements.speak('all_selected', 7);

    expect(announceSpy).toHaveBeenCalledWith('All 7 items selected.', { politeness: 'polite' });
  });
});
