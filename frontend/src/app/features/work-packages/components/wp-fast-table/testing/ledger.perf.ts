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

// Opt-in: npm run test -- --include=src/app/features/work-packages/components/wp-fast-table/testing/ledger.perf.ts
import { RenderedOccurrenceLedger, wpOccurrenceKey } from '../rendered-occurrence-ledger';

const occurrenceCount = 5000;
const budgetMs = 20;

describe(`occurrence lookup by work package id on ${occurrenceCount} occurrences`, () => {
  it('finds the keys of every work package within budget', () => {
    const ledger = new RenderedOccurrenceLedger();
    const draft = ledger.beginRender();
    const ids = Array.from({ length: occurrenceCount }, (_, index) => String(index + 1));
    ids.forEach((id) => draft.append({
      key: wpOccurrenceKey(id),
      kind: 'workPackage',
      classIdentifier: `wp-row-${id}`,
      workPackageId: id,
      renderType: 'primary',
      hidden: false,
      level: 1,
      element: null,
      additionalClasses: [],
      workPackage: null,
    }));
    ledger.commit(draft);

    const start = performance.now();
    ids.forEach((id) => ledger.keysOf(id));
    const elapsed = performance.now() - start;
    // eslint-disable-next-line no-console
    console.info(`[perf] keysOf for ${occurrenceCount} ids: ${elapsed.toFixed(2)} ms`);

    expect(elapsed).toBeLessThan(budgetMs);
  });
});
