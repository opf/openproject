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
import { within } from '@testing-library/dom';
import { TestBed } from '@angular/core/testing';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { UiStateLinkBuilder } from './ui-state-link-builder';

describe('UiStateLinkBuilder', () => {
  let builder:UiStateLinkBuilder;
  let owner:HTMLElement;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [
      { provide: KeepTabService, useValue: { currentDetailsTab: 'overview', currentShowTab: 'activity' } },
      { provide: CurrentProjectService, useValue: { identifier: 'demo' } },
      { provide: PathHelperService, useValue: { genericWorkPackagePath: (_project:string, id:string) => `/work_packages/${id}` } },
      { provide: UrlParamsService, useValue: { basePathWithoutDetails: () => '/work_packages' } },
    ] });

    builder = new UiStateLinkBuilder(TestBed.inject(KeepTabService), TestBed.inject(CurrentProjectService),
      TestBed.inject(PathHelperService), TestBed.inject(UrlParamsService));
    owner = document.body.appendChild(document.createElement('div'));
  });

  afterEach(() => owner.remove());

  it('exposes the actual details anchor for decoration and its appendable fragment', () => {
    const result = builder.linkToDetails('42', 'Open details view', '', 'DEMO-7');

    expect(result).toHaveProperty('link');
    expect(result.element).toBeInstanceOf(DocumentFragment);

    result.link.classList.add('caller-decoration');
    owner.append(result.element);

    const link = within(owner).getByRole('link', { name: 'Open details view' });
    expect(link).toBe(result.link);
    expect(link).toHaveClass('__ui-state-link', 'caller-decoration');
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('data-wp-state', 'split');
    expect(link).toHaveAttribute('href', expect.stringContaining('/details/DEMO-7/overview'));
    expect(link).toHaveAttribute('title', '');
    expect(link).toHaveAccessibleDescription('');
  });

  it('describes a visible ID without changing record identity or routing', () => {
    const { link, element } = builder.linkToShow('42', 'Open full view', 'DEMO-7', 'DEMO-7');
    owner.append(element);

    expect(within(owner).getByRole('link', { name: 'DEMO-7' })).toBe(link);
    expect(link).toHaveAccessibleDescription('Open full view');
    expect(link).toHaveAttribute('href', expect.stringContaining('/work_packages/DEMO-7'));
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('data-wp-state', 'show');
  });

  it.each(['', 'DEMO-7'])('omits a redundant or empty title (%s)', (title) => {
    const { link, element } = builder.linkToShow('42', title, 'DEMO-7');
    owner.append(element);
    expect(link).toHaveAccessibleName('DEMO-7');
    expect(link).toHaveAccessibleDescription('');
    expect(link).toHaveAttribute('title', '');
    expect(owner.querySelector('tool-tip')).not.toBeInTheDocument();
  });
});
