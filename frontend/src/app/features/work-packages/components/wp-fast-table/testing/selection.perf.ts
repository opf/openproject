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

// Opt-in: npm run test -- --include=src/app/features/work-packages/components/wp-fast-table/testing/selection.perf.ts
import { buildTable, TableHarness } from './table-harness';

const rowCount = 300;
const columns = ['id', 'subject', 'type', 'status', 'assignee', 'priority', 'startDate', 'dueDate', 'project', 'author'];
const perRowBudgetMs = 1.5;
const perGestureBudgetMs = 20;

describe(`selection on ${rowCount} rows × ${columns.length} columns`, () => {
  let harness:TableHarness;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: Array.from({ length: rowCount }, (_, index) => ({ id: String(index + 1) })),
      columns,
      productionMarkup: true,
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const rows = () => harness.table.renderedRows;

  const samples = 5;

  const measure = (label:string, operations:number, budgetMs:number, prepare:() => void, run:() => void) => {
    const perOperation = Array.from({ length: samples }, () => {
      prepare();
      const start = performance.now();
      run();
      return (performance.now() - start) / operations;
    }).sort((a, b) => a - b)[Math.floor(samples / 2)];
    // eslint-disable-next-line no-console
    console.info(`[perf] ${label}: ${perOperation.toFixed(2)} ms per operation (median of ${samples})`);
    expect(perOperation, label).toBeLessThan(budgetMs);
  };

  const fromNothing = () => harness.selection.reset();
  const fromFirstRow = () => {
    harness.selection.reset();
    harness.selection.replaceOccurrence(rows()[0]);
  };

  it('toggles rows one by one', () => {
    measure('toggle', 150, perRowBudgetMs, fromNothing, () => {
      for (let index = 0; index < 150; index++) harness.selection.toggleOccurrence(rows()[index]);
    });
  });

  it('extends a range one row at a time', () => {
    measure('extend range', 149, perRowBudgetMs, fromFirstRow, () => {
      for (let index = 1; index < 150; index++) harness.selection.rangeTo(rows()[index], rows());
    });
  });

  it('selects a range in one gesture', () => {
    measure('range', 1, perGestureBudgetMs, fromFirstRow, () => harness.selection.rangeTo(rows()[149], rows()));
  });

  it('selects all', () => {
    measure('select all', 1, perGestureBudgetMs, fromNothing, () => harness.selection.selectAll(rows()));
  });

  it('resets a full selection', () => {
    measure('reset', 1, perGestureBudgetMs, () => harness.selection.selectAll(rows()), () => harness.selection.reset());
  });
});
