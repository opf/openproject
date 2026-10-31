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

import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { page } from 'vitest/browser';
import { Injector } from '@angular/core';
import { within } from '@testing-library/dom';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { OpUnlinkTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/unlink-table-action';
import { destructiveControlAttribute } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { TableActionRenderer } from './table-action-renderer';

const linkServices = [
  { provide: I18nService, useValue: { t: (key:string) => ({ 'js.button_open_details': 'Open details view', 'js.label_open_context_menu': 'Open context menu' }[key] ?? key) } },
  { provide: KeepTabService, useValue: { currentDetailsTab: 'overview', currentShowTab: 'activity' } },
  { provide: CurrentProjectService, useValue: { identifier: 'demo' } },
  { provide: PathHelperService, useValue: { genericWorkPackagePath: (_project:string, id:string) => `/work_packages/${id}` } },
  { provide: UrlParamsService, useValue: { basePathWithoutDetails: () => '/work_packages' } },
];

describe('TableActionRenderer tooltips', () => {
  let table:HTMLTableElement;
  let renderer:TableActionRenderer;

  const wp = { id: '42', displayId: 'DEMO-7' } as WorkPackageResource;

  beforeEach(async () => {
    await page.viewport(1280, 900);
    TestBed.configureTestingModule({ providers: [OpTableActionsService, ...linkServices] });
    renderer = new TableActionRenderer(TestBed.inject(Injector));
    table = document.body.appendChild(document.createElement('table'));
  });

  afterEach(() => table.remove());

  function renderRow() {
    const row = table.insertRow();
    row.append(renderer.build(wp));
    return row;
  }

  it('appends real decorated anchors and sibling labels for repeated rows', () => {
    const rows = [renderRow(), renderRow()];

    rows.forEach((row) => {
      const details = within(row).getByRole('link', { name: 'Open details view' });

      expect(details).toHaveAccessibleDescription('');
      expect(details).toHaveAttribute('title', '');
      expect(details).toHaveClass('wp-table--details-link', 'wp-table-context-menu-icon', 'hidden-for-mobile');
      expect(details).toHaveAttribute('data-work-package-id', '42');
      expect(details).toHaveAttribute('href', expect.stringContaining('/details/DEMO-7/overview'));
      expect(details.querySelector('.icon-info2')).toBeInTheDocument();
      expect(details.nextElementSibling?.tagName).toBe('TOOL-TIP');

      const context = within(row).getByRole('link', { name: 'Open context menu' });
      expect(context).toHaveAttribute('title', '');
      expect(context).toHaveClass('wp-table-context-menu-link');
      expect(context.nextElementSibling?.tagName).toBe('TOOL-TIP');
    });

    const ids = [...table.querySelectorAll('[id]')].map((element) => element.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('preserves destructive unlink behavior on the actual labeled link', () => {
    const onClick = vi.fn();
    TestBed.inject(OpTableActionsService).setActions(OpUnlinkTableAction.factoryFor('remove', 'Remove relation', onClick));
    const row = renderRow();
    const unlink = within(row).getByRole('link', { name: 'Remove relation' });
    expect(unlink).toHaveAttribute(destructiveControlAttribute, '');
    expect(unlink).toHaveAttribute('data-work-package-id', '42');
    expect(unlink).toHaveAttribute('title', '');
    unlink.click();
    expect(onClick).toHaveBeenCalledExactlyOnceWith(wp);
  });

  it('omits inapplicable unlink actions', () => {
    TestBed.inject(OpTableActionsService).setActions(OpUnlinkTableAction.factoryFor('remove', 'Remove relation', vi.fn(), () => false));
    expect(within(renderRow()).queryByRole('link')).not.toBeInTheDocument();
  });
});
