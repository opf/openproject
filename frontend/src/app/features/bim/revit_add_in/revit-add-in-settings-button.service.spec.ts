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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { RevitAddInSettingsButtonService } from 'core-app/features/bim/revit_add_in/revit-add-in-settings-button.service';

describe('RevitAddInSettingsButtonService', () => {
  let loginModal:HTMLElement;

  beforeEach(() => {
    vi.spyOn(window.navigator, 'userAgent', 'get').mockReturnValue('Mozilla/5.0 Revit/2026');

    loginModal = document.createElement('div');
    loginModal.id = 'nav-login-content';
    document.body.appendChild(loginModal);

    TestBed.configureTestingModule({
      providers: [
        RevitAddInSettingsButtonService,
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });

    TestBed.inject(RevitAddInSettingsButtonService);
  });

  afterEach(() => {
    loginModal.remove();
  });

  it('styles the settings entry like the omniauth provider buttons', () => {
    const button = loginModal.querySelector('.revit-add-in-button')!;

    expect(button.tagName).toEqual('BUTTON');
    expect(Array.from(button.classList)).toEqual(
      expect.arrayContaining(['auth-provider', 'Button', 'Button--secondary', 'Button--fullWidth']),
    );
    expect(button.querySelector('.Button-content .Button-label .auth-provider-name')?.textContent)
      .toEqual('js.revit.revit_add_in_settings');
  });

  it('keeps the entry free of block level elements inside the button', () => {
    expect(loginModal.querySelectorAll('.revit-add-in-button div').length).toEqual(0);
  });
});
