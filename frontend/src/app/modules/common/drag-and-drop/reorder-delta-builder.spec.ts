// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {QueryOrder} from "core-app/modules/hal/dm-services/query-order-dm.service";
import {
  DEFAULT_ORDER,
  MAX_ORDER,
  ReorderDeltaBuilder
} from "core-app/modules/common/drag-and-drop/reorder-delta-builder";

describe('ReorderDeltaBuilder', () => {
  const work_packages:string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

  function buildDelta(
    wpId:string,
    positions:QueryOrder,
    wps:string[] = work_packages,
    fromIndex:number|null = null) {
    // As work_packages is already the list with moved element, simply compute the index
    let index:number = work_packages.indexOf(wpId);

    if (index === -1) {
      throw "Invalid wpId given for work_packages, must be contained.";
    }
    return new ReorderDeltaBuilder(wps, positions, wpId, index, fromIndex).buildDelta();
  }

  it('Empty, inserting at beginning sets the delta for wpId 1 to the default value', () => {
    let delta = buildDelta('1', {});
    expect(Object.keys(delta)).toEqual(['1']);
    expect(delta['1']).toEqual(DEFAULT_ORDER);
  });

  it('Empty, inserting at end sets the delta for all predecessors', () => {
    let delta = buildDelta('10', {});
    expect(Object.keys(delta).length).toEqual(work_packages.length);
    expect(delta).toEqual({
      '1': 0,
      '2': 16384,
      '3': 32768,
      '4': 49152,
      '5': 65536,
      '6': 81920,
      '7': 98304,
      '8': 114688,
      '9': 131072,
      '10': 139264 // 131072 + ORDER_DISTANCE/2
    });
  });

  it('Empty, inserting at end middle the delta for all predecessors', () => {
    let delta = buildDelta('5', {});
    expect(Object.keys(delta).length).toEqual(5);
    expect(delta).toEqual({
      '1': 0,
      '2': 16384,
      '3': 32768,
      '4': 49152,
      '5': 57344 // 49152 + 8192
    });
  });

  it('has no problems inserting in the beginning old sort oder (1..n)', () => {
    let positions = {
      '2': 1,
      '3': 2,
      '4': 3,
      '1': 4,
      '6': 5,
      '7': 6,
      '8': 7,
      '9': 8,
      '10': 9,
    };

    let delta = buildDelta('1', positions);

    expect(Object.keys(delta).length).toEqual(1);
    // Expected to set to 1(position of 2) - 8192(half default distance)
    expect(delta['1']).toEqual(-8191);
  });

  it('has no problems inserting in the middle of old sort oder (1..n)', () => {
    let positions = {
      '1': 0,
      '2': 1,
      '3': 2,
      '4': 4,
      '6': 5,
      '7': 6,
      '8': 7,
      '9': 8,
      '10': 9,
    };

    let delta = buildDelta('5', positions);

    expect(Object.keys(delta).length).toEqual(10);
    expect(delta).toEqual({
      '1': 0,
      '2': 1,
      '3': 2,
      '4': 3,
      '5': 4,
      '6': 5,
      '7': 6,
      '8': 7,
      '9': 8,
      '10': 9
    });
  });

  it('will reorder old sort if there is not enough data', () => {
    let positions = {
      '1': 0,
      '3': 1,
      '4': 2,
    };

    let delta = buildDelta('2', positions);

    expect(Object.keys(delta).length).toEqual(10);
    expect(delta).toEqual({
      '1': 0,
      '2': 1,
      '3': 2,
      '4': 3,
      '5': 4,
      '6': 5,
      '7': 6,
      '8': 7,
      '9': 8,
      '10': 9,
    });
  });

  it('will shift min position when successor is max', () => {
    let positions = {
      '1': DEFAULT_ORDER,
      '2': MAX_ORDER - 1,
      '4': MAX_ORDER,
    };

    let delta = buildDelta('3', positions, ['1', '2', '3', '4']);
    expect(Object.keys(delta).length).toEqual(4);
    expect(delta).toEqual({
      // 1 remains at DEFAULT_ORDER
      '1': DEFAULT_ORDER,
      // rest is evenly spaced until MAX
      '2': 715827882,
      // 715827882 * 2
      '3': 1431655764,
      // 715827882 * 3
      // gets reassigned due to integer floor()
      '4': 2147483646
    });
  });

  it('will shift first position back when predecessor is max', () => {
    let positions = {
      '1': MAX_ORDER - 1,
      '2': MAX_ORDER,
    };

    let delta = buildDelta('3', positions, ['1', '2', '3']);
    expect(Object.keys(delta).length).toEqual(3);
    expect(delta).toEqual({
      '1': MAX_ORDER - 4,
      '2': MAX_ORDER - 2,
      '3': MAX_ORDER
    });
  });

  it('with successor position, sets the delta for wpId 1 to the default value', () => {
    let positions = { '2': DEFAULT_ORDER };
    let delta = buildDelta('1', positions);

    expect(Object.keys(delta)).toEqual(['1']);
    // expect position to be ORDER_DISTANCE/2 before successor position
    expect(delta['1']).toEqual(-8192);
  });

  it('fills in all predecessors when inserting at index > 0', () => {
    let positions = {};
    let delta = buildDelta('2', positions);

    expect(Object.keys(delta)).toEqual(['1', '2']);
    // expect position to be ORDER_DISTANCE/2 before successor position
    expect(delta['1']).toEqual(0);
    expect(delta['2']).toEqual(8192);
  });

  it('just sets the default when order contains wpId only', () => {
    let positions = {};
    let delta = buildDelta('1', positions, ['1']);

    expect(Object.keys(delta)).toEqual(['1']);
    expect(delta['1']).toEqual(0);
  });

  it('just shifts two values when index <- 1 -> fromIndex', () => {
    let positions = { '1': 8192, '2': 0, '3': 16384};
    // From index 1 to 0
    let delta = buildDelta('1', positions, ['1', '2', '3'], 1);

    expect(Object.keys(delta)).toEqual(['1', '2']);
    expect(delta['1']).toEqual(0);
    expect(delta['2']).toEqual(8192);
  });

  it('adds to the predecessor if successor has no position', () => {
    let positions = { '1': 0 };
    let delta = buildDelta('2', positions, ['1', '2', '3']);

    expect(Object.keys(delta)).toEqual(['2']);
    expect(delta['2']).toEqual(8192);
  });

  it('reorders according to positions when not in ascending order', () => {
    let positions = { '1': 0, '2': 1234, '3': 981 };
    let delta = buildDelta('1', positions, ['1', '2', '3']);

    expect(delta).toEqual({
      '1': 0,
      '2': 617,
      '3': 1234
    });
  });

  it('reorders according to positions when not in ascending order with missing position', () => {
    let positions = { '1': 1234, '3': 981 };
    let delta = buildDelta('2', positions, ['1', '2', '3']);

    expect(delta).toEqual({
      '1': 981,
      '2': 1107, // 981 + floor[(1234-981)/2]
      '3': 1233 // Due to flooring
    });
  });

  // It will reassign default orders when not in ascending order and min/max not sufficient

});
