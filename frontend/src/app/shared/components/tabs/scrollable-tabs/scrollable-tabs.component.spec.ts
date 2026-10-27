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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { ScrollableTabsComponent } from './scrollable-tabs.component';

describe('ScrollableTabsComponent', () => {
  let fixture:ComponentFixture<ScrollableTabsComponent>;

  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [ScrollableTabsComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => key } },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(ScrollableTabsComponent);
    fixture.componentRef.setInput('tabs', [
      { id: 'columns', name: 'Columns' },
      { id: 'gantt', name: 'Gantt chart', disable: 'Not available for embedded tables' },
      { id: 'display', name: 'Display settings', disable: true },
    ]);
    fixture.detectChanges();
    await fixture.whenStable();
  });

  it('describes a disabled tab by its reason through a tooltip', () => {
    expect(screen.getByRole('tab', { name: 'Gantt chart' }))
      .toHaveAccessibleDescription('Not available for embedded tables');
    expect(fixture.nativeElement.querySelectorAll('tool-tip')).toHaveLength(1);
  });

  it('leaves tabs without a reason undescribed', () => {
    expect(screen.getByRole('tab', { name: 'Columns' })).not.toHaveAccessibleDescription();
    expect(screen.getByRole('tab', { name: 'Display settings' })).not.toHaveAccessibleDescription();
  });
});
