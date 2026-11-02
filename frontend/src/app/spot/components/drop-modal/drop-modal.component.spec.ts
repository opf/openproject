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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpSpotModule } from 'core-app/spot/spot.module';

@Component({
  template: `
    <button type="button">Before</button>
    <spot-drop-modal [opened]="false">
      <button slot="trigger" type="button">Include projects</button>
    </spot-drop-modal>
    <button type="button">After</button>
  `,
  imports: [OpSpotModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class HostComponent {}

describe('SpotDropModalComponent', () => {
  beforeEach(async () => {
    await TestBed
      .configureTestingModule({
        providers: [{ provide: I18nService, useValue: { t: (key:string) => key } }],
      })
      .compileComponents();

    const fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  it('moves focus from the trigger straight to the next control', async () => {
    screen.getByRole('button', { name: 'Before' }).focus();

    await userEvent.tab();
    expect(screen.getByRole('button', { name: 'Include projects' })).toHaveFocus();

    await userEvent.tab();
    expect(screen.getByRole('button', { name: 'After' })).toHaveFocus();
  });
});
