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

import {
  DEFAULT_ORDER,
  MAX_ORDER,
  MIN_ORDER,
  buildDelta,
  buildMoveDelta,
  buildOrderDelta,
} from 'core-app/shared/helpers/drag-and-drop/reorder-delta-builder';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';

describe('ReorderDeltaBuilder', () => {
  const work_packages:string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

  function buildSpecDelta(
    wpId:string,
    positions:QueryOrder,
    wps:string[] = work_packages,
    fromIndex:number|null = null,
    toIndex:number|null = null,
  ) {
    // As work_packages is already the list with moved element, simply compute the index
    if (!toIndex) {
      toIndex = work_packages.indexOf(wpId);

      if (toIndex === -1) {
        throw new Error('Invalid wpId given for work_packages, must be contained.');
      }
    }
    return buildDelta(wps, positions, wpId, toIndex, fromIndex);
  }

  const reloaded = (result:QueryOrder) => Object.keys(result).sort((a, b) => result[a] - result[b] || Number(a) - Number(b));

  describe('moves', () => {
    it('keeps a move past a tied neighbor after a reload', () => {
      const positions = { '1': 0, '2': 0, '3': 1 };
      const order = ['2', '1', '3'];

      expect(reloaded({ ...positions, ...buildMoveDelta(order, positions, '1', 1, 0) })).toEqual(order);
    });

    it('keeps the single-position delta when no tie is involved', () => {
      const positions = { '1': 0, '2': 16384, '3': 32768, '4': 49152 };
      const order = ['2', '3', '1', '4'];

      expect(buildMoveDelta(order, positions, '1', 2, 0)).toEqual(buildDelta([...order], positions, '1', 2, 0));
      expect(Object.keys(buildMoveDelta(order, positions, '1', 2, 0)).length).toBeLessThan(order.length);
    });

    it('keeps a moved work package ahead of tied rows beyond the page', () => {
      const positions = { '1': 0, '2': 0, '3': 0, '4': 0 };

      expect(reloaded({ ...positions, ...buildMoveDelta(['2', '3', '1'], positions, '1', 2, 0) })).toEqual(['2', '3', '1', '4']);
    });

    it('keeps an added work package ahead of positioned rows beyond the page', () => {
      const positions = { '1': 0, '2': 16384, '3': 32768, '4': 49152 };

      expect(reloaded({ ...positions, ...buildMoveDelta(['1', '2', '3', '5'], positions, '5', 3, null) })).toEqual(['1', '2', '3', '5', '4']);
    });

    it('keeps an added work package ahead of densely positioned rows beyond the page', () => {
      const positions = { '1': 0, '2': 10, '3': 20, '4': 30 };

      expect(reloaded({ ...positions, ...buildMoveDelta(['1', '2', '3', '5'], positions, '5', 3, null) })).toEqual(['1', '2', '3', '5', '4']);
    });

    it('keeps a move on an unpositioned page after the positioned rows before it', () => {
      const positions = { '1': 0, '2': 16384, '3': 32768 };
      const order = ['6', '4', '5'];

      expect(reloaded({ ...positions, ...buildMoveDelta(order, positions, '6', 0, 2) })).toEqual(['1', '2', '3', '6', '4', '5']);
    });

    it('keeps an addition to an unpositioned page after the positioned rows before it', () => {
      const positions = { '1': 0, '2': 16384, '3': 32768 };
      const order = ['4', '5', '6'];

      expect(reloaded({ ...positions, ...buildMoveDelta(order, positions, '6', 2, null) })).toEqual(['1', '2', '3', '4', '5', '6']);
    });

    it('ranks the order instead when a move would pass the largest rank', () => {
      const positions = { '1': 2147456014, '2': 2147444848, '3': 2147481990 };
      const order = ['1', '3', '2'];
      const delta = buildMoveDelta(order, positions, '2', 2, 0);

      expect(Math.max(...Object.values(delta))).toBeLessThanOrEqual(MAX_ORDER);
      expect(reloaded({ ...positions, ...delta })).toEqual(order);
    });

    it('ranks the order instead when a move would pass the smallest rank', () => {
      const positions = { '1': MIN_ORDER + 10, '2': MIN_ORDER + 20, '3': MIN_ORDER + 30 };
      const order = ['3', '1', '2'];
      const delta = buildMoveDelta(order, positions, '3', 0, 2);

      expect(Math.min(...Object.values(delta))).toBeGreaterThanOrEqual(MIN_ORDER);
      expect(reloaded({ ...positions, ...delta })).toEqual(order);
    });

    it('treats a cached deletion as unranked', () => {
      const delta = buildMoveDelta(['3', '2'], { '1': -1, '2': 0, '3': 0 }, '3', 0, 1);

      expect(delta).not.toHaveProperty('1');
      expect(Object.values(delta)).not.toContain(-1);
    });

    it('keeps an added work package ahead of an adjacent row beyond the page', () => {
      const positions = { '1': 0, '2': 1, '3': 2, '4': 3 };

      expect(reloaded({ ...positions, ...buildMoveDelta(['1', '2', '3', '5'], positions, '5', 3, null) })).toEqual(['1', '2', '3', '5', '4']);
    });
  });

  describe('ranking an order', () => {
    it('treats a cached deletion as unranked', () => {
      const delta = buildOrderDelta(['3', '2'], { '1': -1, '2': 0, '3': 0 });

      expect(delta).not.toHaveProperty('1');
      expect(Object.values(delta)).not.toContain(-1);
    });

    it('keeps a tied page ahead of the first off-page row', () => {
      const positions = { '1': 0, '2': 0, '3': 0, '4': 1 };
      const order = ['3', '1', '2'];
      const delta = buildOrderDelta(order, positions);
      const result:QueryOrder = { ...positions, ...delta };

      expect(order.map((id) => result[id])).toEqual([-2, 0, 0]);
      expect(delta).not.toHaveProperty('4');
    });

    it('keeps the hidden row after a block at the minimum integer rank', () => {
      const positions = { '1': MIN_ORDER, '2': MIN_ORDER, '3': MIN_ORDER, '4': MIN_ORDER };
      const result:QueryOrder = { ...positions, ...buildOrderDelta(['3', '2', '1'], positions) };
      expect(reloaded(result)).toEqual(['3', '2', '1', '4']);
      expect(Math.min(...Object.values(result))).toBeGreaterThanOrEqual(MIN_ORDER);
    });

    it('keeps an unpositioned page after the positioned rows before it', () => {
      const positions = { '1': 0, '2': 16384, '3': 32768 };
      const order = ['6', '4', '5'];

      expect(reloaded({ ...positions, ...buildOrderDelta(order, positions) })).toEqual(['1', '2', '3', '6', '4', '5']);
    });

    it('assigns missing ranks and never emits the API deletion sentinel', () => {
      const order = ['3', '2', '1', '4'];
      const positions = { '1': -2, '2': -2, '3': 0 };
      const result:QueryOrder = { ...positions, ...buildOrderDelta(order, positions) };
      const ranks = order.map((id) => result[id]);
      expect(new Set(ranks).size).toBe(4);
      expect(ranks).not.toContain(-1);
      expect(ranks).toEqual([...ranks].sort((a, b) => a - b));
    });
  });

  it('Empty, inserting at beginning sets the delta for wpId 1 to the default value', () => {
    const delta = buildSpecDelta('1', {});

    expect(Object.keys(delta)).toEqual(['1']);
    expect(delta['1']).toEqual(DEFAULT_ORDER);
  });

  it('Empty, inserting at end sets the delta for all predecessors', () => {
    const delta = buildSpecDelta('10', {});

    expect(Object.keys(delta).length).toEqual(work_packages.length);
    expect(delta).toEqual({
      1: 0,
      2: 16384,
      3: 32768,
      4: 49152,
      5: 65536,
      6: 81920,
      7: 98304,
      8: 114688,
      9: 131072,
      10: 139264, // 131072 + ORDER_DISTANCE/2
    });
  });

  it('Empty, inserting at end middle the delta for all predecessors', () => {
    const delta = buildSpecDelta('5', {});

    expect(Object.keys(delta).length).toEqual(5);
    expect(delta).toEqual({
      1: 0,
      2: 16384,
      3: 32768,
      4: 49152,
      5: 57344, // 49152 + 8192
    });
  });

  it('has no problems inserting in the beginning old sort order (1..n)', () => {
    const positions = {
      2: 1,
      3: 2,
      4: 3,
      1: 4,
      6: 5,
      7: 6,
      8: 7,
      9: 8,
      10: 9,
    };

    const delta = buildSpecDelta('1', positions);

    expect(Object.keys(delta).length).toEqual(1);
    // Expected to set to 1(position of 2) - 8192(half default distance)
    expect(delta['1']).toEqual(-8191);
  });

  it('has no problems inserting in the middle of old sort order (1..n)', () => {
    const positions = {
      1: 0,
      2: 1,
      3: 2,
      4: 4,
      6: 5,
      7: 6,
      8: 7,
      9: 8,
      10: 9,
    };

    const delta = buildSpecDelta('5', positions);

    expect(Object.keys(delta).length).toEqual(10);
    expect(delta).toEqual({
      1: 0,
      2: 1,
      3: 2,
      4: 3,
      5: 4,
      6: 5,
      7: 6,
      8: 7,
      9: 8,
      10: 9,
    });
  });

  it('will reorder old sort if there is not enough data', () => {
    const positions = {
      1: 0,
      3: 1,
      4: 2,
    };

    const delta = buildSpecDelta('2', positions);

    expect(Object.keys(delta).length).toEqual(10);
    expect(delta).toEqual({
      1: 0,
      2: 1,
      3: 2,
      4: 3,
      5: 4,
      6: 5,
      7: 6,
      8: 7,
      9: 8,
      10: 9,
    });
  });

  it('will shift min position when successor is max', () => {
    const positions = {
      1: DEFAULT_ORDER,
      2: MAX_ORDER - 1,
      4: MAX_ORDER,
    };

    const delta = buildSpecDelta('3', positions, ['1', '2', '3', '4']);

    expect(Object.keys(delta).length).toEqual(4);
    expect(delta).toEqual({
      // 1 remains at DEFAULT_ORDER
      1: DEFAULT_ORDER,
      // rest is evenly spaced until MAX
      2: 715827882,
      // 715827882 * 2
      3: 1431655764,
      // 715827882 * 3
      // gets reassigned due to integer floor()
      4: 2147483646,
    });
  });

  it('will shift first position back when predecessor is max', () => {
    const positions = {
      1: MAX_ORDER - 1,
      2: MAX_ORDER,
    };

    const delta = buildSpecDelta('3', positions, ['1', '2', '3']);

    expect(Object.keys(delta).length).toEqual(3);
    expect(delta).toEqual({
      1: MAX_ORDER - 4,
      2: MAX_ORDER - 2,
      3: MAX_ORDER,
    });
  });

  it('with successor position, sets the delta for wpId 1 to the default value', () => {
    const positions = { 2: DEFAULT_ORDER };
    const delta = buildSpecDelta('1', positions);

    expect(Object.keys(delta)).toEqual(['1']);
    // expect position to be ORDER_DISTANCE/2 before successor position
    expect(delta['1']).toEqual(-8192);
  });

  it('fills in all predecessors when inserting at index > 0', () => {
    const positions = {};
    const delta = buildSpecDelta('2', positions);

    expect(Object.keys(delta)).toEqual(['1', '2']);
    // expect position to be ORDER_DISTANCE/2 before successor position
    expect(delta['1']).toEqual(0);
    expect(delta['2']).toEqual(8192);
  });

  it('just sets the default when order contains wpId only', () => {
    const positions = {};
    const delta = buildSpecDelta('1', positions, ['1']);

    expect(Object.keys(delta)).toEqual(['1']);
    expect(delta['1']).toEqual(0);
  });

  it('just shifts two values when index <- 1 -> fromIndex', () => {
    const positions = {
      1: 8192,
      2: 0,
      3: 16384,
    };
    // From index 1 to 0
    const delta = buildSpecDelta('1', positions, ['1', '2', '3'], 1);

    expect(Object.keys(delta)).toEqual(['1', '2']);
    expect(delta['1']).toEqual(0);
    expect(delta['2']).toEqual(8192);
  });

  it('adds to the predecessor if successor has no position', () => {
    const positions = { 1: 0 };
    const delta = buildSpecDelta('2', positions, ['1', '2', '3']);

    expect(Object.keys(delta)).toEqual(['2']);
    expect(delta['2']).toEqual(8192);
  });

  it('reorders according to positions when not in ascending order', () => {
    const positions = { 1: 0, 2: 1234, 3: 981 };
    const delta = buildSpecDelta('1', positions, ['1', '2', '3']);

    expect(delta).toEqual({
      1: 0,
      2: 617,
      3: 1234,
    });
  });

  it('reorders according to positions when not in ascending order with missing position', () => {
    const positions = { 1: 1234, 3: 981 };
    const delta = buildSpecDelta('2', positions, ['1', '2', '3']);

    expect(delta).toEqual({
      1: 981,
      2: 1107, // 981 + floor[(1234-981)/2]
      3: 1233, // Due to flooring
    });
  });

  it('reorders on incomplete positions information and moving the first (0 positioned) work package', () => {
    // This can happen if a query is saved and the filters on it changed later on so that
    // additional work packages are now present.
    const delta = buildSpecDelta('1', { 1: 0, 5: 8196 }, ['2', '3', '4', '1', '5'], 0, 3);

    expect(delta).toEqual({
      2: 0,
      3: 2049,
      4: 4098,
      1: 6147,
      5: 8196,
    });
  });

  // It will reassign default orders when not in ascending order and min/max not sufficient
});
