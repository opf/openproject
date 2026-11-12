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
import { of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { TimeEntryTimerService } from 'core-app/shared/components/time_entries/services/time-entry-timer.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WorkPackageTimerButtonComponent } from './wp-timer-button.component';

describe('WorkPackageTimerButtonComponent', () => {
  it('renders an idle toolbar icon button with a tooltip', async () => {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [WorkPackageTimerButtonComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: I18nService, useValue: { t: () => 'Start timer' } },
          { provide: TimeEntryTimerService, useValue: { activeTimer$: of(null) } },
          { provide: ApiV3Service, useValue: {} },
          { provide: HalResourceEditingService, useValue: {} },
          { provide: SchemaCacheService, useValue: {} },
          { provide: TimezoneService, useValue: {} },
          { provide: ToastService, useValue: {} },
          { provide: PathHelperService, useValue: {} },
          { provide: TurboRequestsService, useValue: {} },
        ],
      })
      .compileComponents();

    const fixture = TestBed.createComponent(WorkPackageTimerButtonComponent);
    fixture.detectChanges();
    await fixture.whenStable();

    const button = screen.getByRole('button', { name: 'Start timer' });
    expect(button).toHaveClass('button', 'toolbar-icon');
    expect(screen.getByText('Start timer', { selector: 'tool-tip' })).toHaveAttribute('for', button.id);
  });
});
