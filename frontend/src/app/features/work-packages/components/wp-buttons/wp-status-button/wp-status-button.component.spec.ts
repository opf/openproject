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
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, waitFor } from '@testing-library/dom';
import { of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageStatusButtonComponent } from './wp-status-button.component';

const translations:Record<string, string> = {
  'js.work_packages.properties.status': 'Status',
  'js.work_packages.message_work_package_read_only': 'Work package is locked',
};

describe('WorkPackageStatusButtonComponent', () => {
  let fixture:ComponentFixture<WorkPackageStatusButtonComponent>;

  async function render({ readonly = false, width = '' } = {}) {
    const workPackage = { status: { id: '1', name: 'Waiting for customer feedback', $load: () => Promise.resolve() } };
    const schema = { isReadonly: readonly, isEditable: !readonly, isAttributeEditable: () => !readonly };

    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [WorkPackageStatusButtonComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => translations[key] ?? key } },
          { provide: SchemaCacheService, useValue: { of: () => schema } },
          {
            provide: HalResourceEditingService,
            useValue: {
              temporaryEditResource: () => ({ values$: () => of(workPackage) }),
              typedState: () => ({ hasValue: () => false }),
            },
          },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WorkPackageStatusButtonComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    fixture.nativeElement.style.display = 'block';
    fixture.nativeElement.style.width = width;
    fixture.detectChanges();
    await fixture.whenStable();
  }

  const tooltip = () => fixture.nativeElement.querySelector('tool-tip') as HTMLElement;

  it('shows the full status in a tooltip while the status is cut off', async () => {
    await render({ width: '60px' });

    screen.getByRole('button', { name: 'Status Waiting for customer feedback' }).focus();

    await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
    expect(tooltip()).toHaveTextContent('Status Waiting for customer feedback');
  });

  it('shows no tooltip while the status fits', async () => {
    await render();

    screen.getByRole('button', { name: 'Status Waiting for customer feedback' }).focus();
    await new Promise((resolve) => { setTimeout(resolve, 100); });

    expect(tooltip().matches(':popover-open')).toBe(false);
  });

  it('describes a locked status by its reason even when the status fits', async () => {
    await render({ readonly: true });

    const button = screen.getByRole('button', { name: 'Status Waiting for customer feedback' });
    expect(button).toHaveAccessibleDescription('Work package is locked');

    button.focus();
    await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));
  });
});
