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

import { ChangeDetectionStrategy, Component, ViewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { SpotDropModalComponent } from './drop-modal.component';

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

@Component({
  template: `
    <spot-drop-modal (closed)="closed()">
      <button slot="trigger" (click)="modal.opened = true">Open menu</button>
      <div slot="body">
        <button (click)="activated()">Activate</button>
        <a href="#drop-modal-target">Native link</a>
      </div>
    </spot-drop-modal>
    <opce-spot-drop-modal-portal />
  `,
  imports: [OpSpotModule],
})
class DropModalHostComponent {
  @ViewChild(SpotDropModalComponent) modal:SpotDropModalComponent;

  activated = vi.fn();
  closed = vi.fn();
}

describe('SpotDropModalComponent activation', () => {
  let fixture:ComponentFixture<DropModalHostComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [DropModalHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(DropModalHostComponent);
    fixture.detectChanges();
    await openModal();
  });

  async function openModal():Promise<void> {
    await userEvent.click(screen.getByRole('button', { name: 'Open menu' }));
    await waitFor(() => expect(screen.getByRole('button', { name: 'Activate' })).toHaveFocus());
  }

  afterEach(() => fixture.destroy());

  it('keeps pointer activation inside open and closes on an outside click', async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Activate' }));

    expect(fixture.componentInstance.activated).toHaveBeenCalledOnce();
    expect(fixture.componentInstance.modal.opened).toBe(true);

    fireEvent.click(document.body);

    expect(fixture.componentInstance.closed).toHaveBeenCalledOnce();
    expect(fixture.componentInstance.modal.opened).toBe(false);
    expect(fixture.nativeElement.querySelector('[tabindex="-1"]')).toHaveFocus();
  });

  it.each(['{Enter}', ' '])('preserves native button activation for %s', async (key) => {
    screen.getByRole('button', { name: 'Activate' }).focus();

    await userEvent.keyboard(key);

    expect(fixture.componentInstance.activated).toHaveBeenCalledOnce();
    expect(fixture.componentInstance.modal.opened).toBe(true);
  });

  it('does not cancel native modifier-link or keyboard defaults', () => {
    const link = screen.getByRole('link', { name: 'Native link' });
    const defaults:boolean[] = [];
    const body = link.closest('.spot-drop-modal--body')!;
    body.addEventListener('click', (event) => {
      defaults.push(event.defaultPrevented);
      event.preventDefault();
    });
    body.addEventListener('keydown', event => defaults.push(event.defaultPrevented));

    fireEvent.click(link, { ctrlKey: true });
    fireEvent.keyDown(link, { key: 'Enter' });
    fireEvent.keyDown(link, { key: ' ' });

    expect(defaults).toEqual([false, false, false]);
    expect(fixture.componentInstance.modal.opened).toBe(true);
  });

  it('keeps native keyboard navigation of links inside the open modal', async () => {
    const originalURL = window.location.href;
    try {
      screen.getByRole('link', { name: 'Native link' }).focus();

      await userEvent.keyboard('{Enter}');

      expect(window.location.hash).toBe('#drop-modal-target');
      expect(fixture.componentInstance.modal.opened).toBe(true);
    } finally {
      window.history.replaceState(window.history.state, '', originalURL);
    }
  });

  it('closes on Escape and restores focus', async () => {
    await userEvent.keyboard('{Escape}');

    await waitFor(() => expect(fixture.componentInstance.modal.opened).toBe(false));
    expect(fixture.componentInstance.closed).toHaveBeenCalledOnce();
    expect(fixture.nativeElement.querySelector('[tabindex="-1"]')).toHaveFocus();
  });
});
