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

import { TurboVisitTracker } from './turbo-visit-tracker';

describe('TurboVisitTracker', () => {
  let controller:AbortController;

  function visit(action:string) {
    document.dispatchEvent(new CustomEvent('turbo:visit', { detail: { action } }));
  }

  beforeEach(() => {
    TurboVisitTracker.lastAction = undefined;
    controller = new AbortController();
    TurboVisitTracker.listen(document, controller.signal);
  });

  afterEach(() => {
    controller.abort();
    TurboVisitTracker.lastAction = undefined;
  });

  it('has no action before a visit', () => {
    expect(TurboVisitTracker.lastAction).toBeUndefined();
  });

  it('records the action of the latest visit', () => {
    visit('restore');
    expect(TurboVisitTracker.lastAction).toBe('restore');

    visit('advance');
    expect(TurboVisitTracker.lastAction).toBe('advance');
  });

  it('stops recording once the signal aborts', () => {
    controller.abort();
    visit('replace');

    expect(TurboVisitTracker.lastAction).toBeUndefined();
  });
});
