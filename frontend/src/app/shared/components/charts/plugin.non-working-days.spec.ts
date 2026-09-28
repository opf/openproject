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

import { Scale } from 'chart.js';
import { Band, bandFor, NonWorkingInterval } from './plugin.non-working-days';

// A scale mapping one day to 10px, starting at 2026-10-12.
function scaleStub(attrs:Partial<Scale> = {}):Scale {
  const origin = Date.parse('2026-10-12T00:00:00Z');
  const day = 24 * 60 * 60 * 1000;

  return {
    left: 0,
    right: 1000,
    getPixelForValue: (value:number) => ((value - origin) / day) * 10,
    ...attrs,
  } as Scale;
}

// The zone is never left to the machine's, which would make every expectation here local to
// whoever runs it.
function bandIn(zone:string, interval:NonWorkingInterval, scale:Scale = scaleStub()):Band {
  const band = bandFor(interval, scale, zone);

  if (!band) {
    throw new Error('expected an interval inside the drawable area');
  }

  return band;
}

const weekend = { from: '2026-10-17', to: '2026-10-18' };

describe('bandFor', () => {
  it('spans from the first day up to the end of the last', () => {
    expect(bandIn('UTC', weekend)).toEqual({ left: 50, width: 20 });
  });

  it('begins at midnight in the given zone rather than UTC', () => {
    // Berlin is two hours ahead in October, so its Saturday opens two hours earlier in
    // absolute terms, and two hours of a 10px day is 0.83px.
    expect(bandIn('Europe/Berlin', weekend).left).toBeCloseTo(50 - (10 * 2) / 24, 5);
  });

  it('keeps a band whole across a daylight saving transition', () => {
    // The clocks go back on Sunday 2026-10-25, making that weekend 49 hours rather than 48.
    expect(bandIn('Europe/Berlin', { from: '2026-10-24', to: '2026-10-25' }).width)
      .toBeCloseTo((10 * 49) / 24, 5);
  });

  it('covers a whole day for a single day interval', () => {
    expect(bandIn('UTC', { from: '2026-10-17', to: '2026-10-17' })).toEqual({ left: 50, width: 10 });
  });

  it('clips to the drawable area', () => {
    expect(bandIn('UTC', weekend, scaleStub({ left: 55, right: 65 }))).toEqual({ left: 55, width: 10 });
  });

  it('returns null when the interval falls outside the drawable area', () => {
    expect(bandFor(weekend, scaleStub({ left: 0, right: 40 }), 'UTC')).toBeNull();
  });

  it('returns null for an unparseable interval', () => {
    expect(bandFor({ from: 'not-a-date', to: '2026-10-18' }, scaleStub(), 'UTC')).toBeNull();
  });
});
