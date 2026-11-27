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

import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { FocusModule } from './focus.module';

@Component({
  template: `
    <button type="button" [opAutofocus]="true" [opAutofocusOnlyWhenFocusLost]="onlyWhenFocusLost">Target</button>
    <button type="button">Elsewhere</button>
  `,
  imports: [FocusModule],
})
class HostComponent {
  onlyWhenFocusLost = false;
}

describe('AutofocusDirective', () => {
  beforeEach(() => vi.useFakeTimers());

  afterEach(() => {
    vi.useRealTimers();
    TestBed.resetTestingModule();
  });

  function mount(onlyWhenFocusLost:boolean) {
    const fixture = TestBed.createComponent(HostComponent);
    fixture.componentInstance.onlyWhenFocusLost = onlyWhenFocusLost;
    fixture.detectChanges();
    return fixture;
  }

  it('focuses its element', () => {
    mount(false);

    vi.advanceTimersByTime(20);

    expect(screen.getByRole('button', { name: 'Target' })).toHaveFocus();
  });

  it('takes focus from wherever it went during the delay by default', () => {
    mount(false);
    screen.getByRole('button', { name: 'Elsewhere' }).focus();

    vi.advanceTimersByTime(20);

    expect(screen.getByRole('button', { name: 'Target' })).toHaveFocus();
  });

  it('leaves focus where it went during the delay when asked to focus only lost focus', () => {
    mount(true);
    screen.getByRole('button', { name: 'Elsewhere' }).focus();

    vi.advanceTimersByTime(20);

    expect(screen.getByRole('button', { name: 'Elsewhere' })).toHaveFocus();
  });

  it('focuses its element when focus is still lost after the delay', () => {
    mount(true);

    vi.advanceTimersByTime(20);

    expect(screen.getByRole('button', { name: 'Target' })).toHaveFocus();
  });
});
