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

import { TestBed } from '@angular/core/testing';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SpotTextFieldComponent } from './text-field.component';

describe('SpotTextFieldComponent', () => {
  it('renders value-accessor writes after the initial render', async () => {
    TestBed.configureTestingModule({
      imports: [OpSpotModule],
      providers: [{ provide: I18nService, useValue: { t: (key:string) => key } }],
    });
    const fixture = TestBed.createComponent(SpotTextFieldComponent);
    await fixture.whenStable();
    fixture.componentInstance.writeValue('Updated');
    await fixture.whenStable();
    const element = fixture.nativeElement as HTMLElement;
    expect(element.querySelector('input')).toHaveValue('Updated');

    element.querySelector('button')!.click();
    await fixture.whenStable();
    expect(element.querySelector('input')).toHaveValue('');
  });
});
