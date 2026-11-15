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
import { within } from '@testing-library/dom';
import { FormsModule } from '@angular/forms';
import { OpOptionListComponent } from './option-list.component';

describe('OpOptionListComponent', () => {
  it('renders selection changes written through the value accessor', async () => {
    TestBed.configureTestingModule({ declarations: [OpOptionListComponent], imports: [FormsModule] });
    const fixture = TestBed.createComponent(OpOptionListComponent);
    fixture.componentRef.setInput('options', [{ value: 'first', title: 'First' }, { value: 'second', title: 'Second' }]);
    await fixture.whenStable();
    fixture.componentInstance.writeValue('second');
    await fixture.whenStable();
    const element = fixture.nativeElement as HTMLElement;
    expect(within(element).getByRole('radio', { name: 'Second' })).toBeChecked();
    expect(within(element).getByRole('radio', { name: 'First' })).not.toBeChecked();
  });
});
