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
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageMarkNotificationButtonComponent } from './work-package-mark-notification-button.component';

describe('WorkPackageMarkNotificationButtonComponent', () => {
  it('renders a toolbar icon button with a tooltip', async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [WorkPackageMarkNotificationButtonComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: I18nService, useValue: { t: () => 'Mark as read' } },
          { provide: WpSingleViewService, useValue: {} },
        ],
      })
      .compileComponents();

    const fixture = TestBed.createComponent(WorkPackageMarkNotificationButtonComponent);
    fixture.detectChanges();
    await fixture.whenStable();

    const button = screen.getByRole('button', { name: 'Mark as read' });
    expect(button).toHaveClass('button', 'toolbar-icon');
    expect(screen.getByText('Mark as read', { selector: 'tool-tip' })).toHaveAttribute('for', button.id);
  });
});
