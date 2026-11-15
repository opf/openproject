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
import { FormsModule } from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { ChildPagesMacroModalComponent } from './child-pages-macro.modal';

describe('ChildPagesMacroModalComponent', () => {
  it('renders the initial page and saves the edited page', async () => {
    const close = vi.fn();
    TestBed.configureTestingModule({
      declarations: [ChildPagesMacroModalComponent],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalLocalsToken, useValue: { page: 'Original', includeParent: false, service: { close } } },
      ],
    });
    const fixture = TestBed.createComponent(ChildPagesMacroModalComponent);
    await fixture.whenStable();
    const element = fixture.nativeElement as HTMLElement;
    const input = element.querySelector<HTMLInputElement>('input[type="text"]')!;
    expect(input).toHaveValue('Original');
    input.value = 'Updated';
    input.dispatchEvent(new Event('change', { bubbles: true }));
    await fixture.whenStable();
    element.querySelector<HTMLButtonElement>('.spot-modal--submit-button')!.click();
    expect(fixture.componentInstance.page).toBe('Updated');
    expect(close).toHaveBeenCalled();
  });
});
