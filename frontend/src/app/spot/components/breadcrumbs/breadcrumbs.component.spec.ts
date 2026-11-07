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

import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { BreadcrumbsContent } from './breadcrumbs-content';
import { SpotBreadcrumbsComponent } from './breadcrumbs.component';

describe('SpotBreadcrumbsComponent', () => {
  let fixture:ComponentFixture<SpotBreadcrumbsComponent>;

  async function render(texts:string[]) {
    fixture.componentRef.setInput('content', new BreadcrumbsContent(texts.map((text) => ({ text, navigate: () => undefined }))));
    fixture.detectChanges();
    await fixture.whenStable();
  }

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [SpotBreadcrumbsComponent],
        schemas: [NO_ERRORS_SCHEMA],
      })
      .compileComponents();

    fixture = TestBed.createComponent(SpotBreadcrumbsComponent);
  });

  it('names each crumb button by its full text in a tooltip', async () => {
    await render(['Root', 'A rather long parent folder name', 'Current']);

    const root = screen.getByRole('button', { name: 'Root' });
    const parent = screen.getByRole('button', { name: 'A rather long parent folder name' });

    expect(root.nextElementSibling).toHaveTextContent('Root');
    expect(parent.nextElementSibling).toHaveTextContent('A rather long parent folder name');
    expect(fixture.nativeElement.querySelectorAll('tool-tip')).toHaveLength(2);
  });

  it('removes the tooltips of crumbs that are no longer shown', async () => {
    await render(['Root', 'Parent', 'Current']);
    await render(['Root']);

    expect(screen.queryAllByRole('button')).toHaveLength(0);
    expect(fixture.nativeElement.querySelectorAll('tool-tip')).toHaveLength(0);
  });
});
