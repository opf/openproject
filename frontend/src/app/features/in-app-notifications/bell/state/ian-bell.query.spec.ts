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

import { IanBellQuery } from 'core-app/features/in-app-notifications/bell/state/ian-bell.query';
import { IanBellStore } from 'core-app/features/in-app-notifications/bell/state/ian-bell.store';

describe('IanBellQuery', () => {
  let store:IanBellStore;
  let query:IanBellQuery;
  let emitted:number[];

  beforeEach(() => {
    store = new IanBellStore();
    query = new IanBellQuery(store);
    emitted = [];
  });

  const subscribe = () => query.loadedUnread$.subscribe((count) => emitted.push(count));

  describe('loadedUnread$', () => {
    it('emits nothing while the count has not been loaded', () => {
      subscribe();
      store.update({ totalUnread: 5 });

      expect(emitted).toEqual([]);
    });

    it('emits the count once it is loaded', () => {
      subscribe();
      store.update({ totalUnread: 5, loaded: true });

      expect(emitted).toEqual([5]);
    });

    it('emits the loaded count to a subscriber that arrives afterwards', () => {
      store.update({ totalUnread: 5, loaded: true });
      subscribe();

      expect(emitted).toEqual([5]);
    });

    it('does not re-emit an unchanged count', () => {
      subscribe();
      store.update({ totalUnread: 5, loaded: true });
      store.update({ totalUnread: 5 });
      store.update({ totalUnread: 6 });

      expect(emitted).toEqual([5, 6]);
    });
  });
});
