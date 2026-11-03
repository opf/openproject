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

import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { getBaselineState } from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import { buildTable, TableHarness } from './table-harness';
import { buildWorkPackage } from './work-package-fixture';

describe('table harness production markup', () => {
  let harness:TableHarness|undefined;

  afterEach(async () => {
    await harness?.destroy();
    harness = undefined;
  });

  it('renders a sticky header row with one cell per column plus the configuration cell, and a totals row', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }], columns: ['id', 'subject'], productionMarkup: true });
    await harness.render();

    expect(harness.headerCells().map((th) => th.textContent?.trim())).toEqual(['id', 'subject', '']);
    expect(harness.headerRow().closest('thead')).toHaveClass('-sticky');
    expect(harness.totalsRow()).toHaveClass('wp-table--sums-row');
    expect(harness.headerCells()[0].querySelector('a[href]')).not.toBeNull();
    expect(harness.headerCells()[2].querySelector('button.wp-table--columns-selection')).not.toBeNull();
  });

  it('keyboardNavigationEnabled defaults to false and can be turned on', () => {
    expect(new WorkPackageTableConfiguration({}).keyboardNavigationEnabled).toBe(false);
    expect(new WorkPackageTableConfiguration({ keyboardNavigationEnabled: true }).keyboardNavigationEnabled).toBe(true);
  });

  it('keeps the baseline inactive and the translator returning keys by default', () => {
    harness = buildTable({ workPackages: [{ id: '1' }] });

    expect(harness.injector.get(WorkPackageViewBaselineService).isActive()).toBe(false);
    expect(harness.injector.get(I18nService).t('js.x', { name: 'A' })).toBe('js.x');
  });

  it.each(['added', 'removed', 'updated'] as const)('derives the %s baseline state from the fixture', (baseline) => {
    harness = buildTable({ workPackages: [{ id: '1', baseline }], baseline: true });
    const schemaService = harness.injector.get(SchemaCacheService);

    expect(harness.injector.get(WorkPackageViewBaselineService).isActive()).toBe(true);
    expect(getBaselineState(buildWorkPackage({ id: '1', baseline }), schemaService)).toBe(baseline);
    expect(getBaselineState(buildWorkPackage({ id: '2' }), schemaService)).toBeNull();
  });

  it('keeps caller-supplied timestamp attributes when the fixture sets no baseline', () => {
    const attributesByTimestamp = [{ subject: 'Before' }, {}];

    expect(buildWorkPackage({ id: '1', attributes: { attributesByTimestamp } }).attributesByTimestamp)
      .toBe(attributesByTimestamp);
  });

  it('interpolates configured translations', () => {
    harness = buildTable({ workPackages: [{ id: '1' }], translations: { 'js.x': 'Hello %{name}' } });
    const i18n = harness.injector.get(I18nService);

    expect(i18n.t('js.x', { name: 'A' })).toBe('Hello A');
    expect(i18n.t('js.other')).toBe('js.other');
  });

  it('defaults the formatted id to the hash-prefixed id', () => {
    expect(buildWorkPackage({ id: '1' }).formattedId).toBe('#1');
    expect(buildWorkPackage({ id: '1', formattedId: 'PROJ-1' }).formattedId).toBe('PROJ-1');
  });
});
