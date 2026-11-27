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

import { TestBed } from '@angular/core/testing';
import { LoadingIndicatorService } from './loading-indicator.service';

describe('LoadingIndicatorService', () => {
  afterEach(() => {
    vi.useRealTimers();
    document.body.replaceChildren();
  });

  it('shows the indicator in its named location', () => {
    document.body.innerHTML = '<div class="loading-indicator--location" data-indicator-name="wpDetails"></div>';

    TestBed.inject(LoadingIndicatorService).wpDetails.start();

    expect(document.querySelector('[data-indicator-name="wpDetails"] .loading-indicator--background')).toBeInTheDocument();
  });

  it('does nothing when the page has no such location', async () => {
    vi.useFakeTimers();
    const indicator = TestBed.inject(LoadingIndicatorService).wpDetails;

    expect(() => { indicator.promise = Promise.resolve(); }).not.toThrow();
    await vi.advanceTimersByTimeAsync(25);

    expect(() => vi.runAllTimers()).not.toThrow();
  });
});
