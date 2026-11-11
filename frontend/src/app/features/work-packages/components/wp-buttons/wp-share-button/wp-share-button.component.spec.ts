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
import { EMPTY, of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageShareButtonComponent } from './wp-share-button.component';

describe('WorkPackageShareButtonComponent', () => {
  let fixture:ComponentFixture<WorkPackageShareButtonComponent>;

  async function render(total:number) {
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [WorkPackageShareButtonComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: I18nService, useValue: { t: () => 'Share' } },
          { provide: OpModalService, useValue: {} },
          { provide: BannersService, useValue: { allowsTo: () => true } },
          { provide: ActionsService, useValue: { ofType: () => EMPTY } },
          {
            provide: ApiV3Service,
            useValue: { shares: { filtered: () => ({ get: () => of({ total }) }) } },
          },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WorkPackageShareButtonComponent);
    fixture.componentRef.setInput('workPackage', { id: '42' });
    fixture.detectChanges();
    await fixture.whenStable();
  }

  it('names the button with the share count when shared', async () => {
    await render(3);

    expect(screen.getByRole('button', { name: 'Share 3' })).toBeInTheDocument();
  });

  it('names the button without a count when not shared', async () => {
    await render(0);

    expect(screen.getByRole('button', { name: 'Share' })).toBeInTheDocument();
  });
});
