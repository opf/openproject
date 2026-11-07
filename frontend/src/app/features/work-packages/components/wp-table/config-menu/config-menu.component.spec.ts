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

import { NgClass } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { fireEvent, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WpTableConfigurationModalComponent } from '../configuration-modal/wp-table-configuration.modal';
import { WorkPackagesTableConfigMenuComponent } from './config-menu.component';

describe('WorkPackagesTableConfigMenuComponent', () => {
  it('closes the context menu and opens table configuration in the table injector', async () => {
    const close = vi.fn<OPContextMenuService['close']>();
    const show = vi.fn<OpModalService['show']>();
    await TestBed.configureTestingModule({
      imports: [NgClass, OpTooltipDirective],
      declarations: [WorkPackagesTableConfigMenuComponent, OpIconComponent],
      providers: [
        { provide: I18nService, useValue: { t: () => 'Configure view' } },
        { provide: OPContextMenuService, useValue: { close } },
        { provide: OpModalService, useValue: { show } },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(WorkPackagesTableConfigMenuComponent);
    await fixture.whenStable();
    const button = within(fixture.nativeElement).getByRole('button', { name: 'Configure view' });

    expect(button).toBeVisible();
    fireEvent.click(button);

    expect(close).toHaveBeenCalledBefore(show);
    expect(show).toHaveBeenCalledWith(WpTableConfigurationModalComponent, fixture.componentInstance.injector);
  });
});
