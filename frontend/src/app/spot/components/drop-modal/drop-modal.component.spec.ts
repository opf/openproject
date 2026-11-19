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

import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element.js';
import { ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA, QueryList, ViewChild, ViewChildren } from '@angular/core';
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
    <button type="button">Outside</button>
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

    const outside = screen.getByRole('button', { name: 'Outside' });
    outside.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
    outside.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));

    expect(fixture.componentInstance.closed).toHaveBeenCalledOnce();
    expect(fixture.componentInstance.modal.opened).toBe(false);
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

@Component({
  template: `
    <spot-drop-modal (closed)="closed()">
      <button slot="trigger" (click)="modal.opened = !modal.opened">Include projects</button>
      <div slot="body">
        <button>Apply</button>
      </div>
    </spot-drop-modal>
    <action-menu data-select-variant="none">
      <button id="create-button" popovertarget="create-overlay" aria-controls="create-list" aria-haspopup="menu">Create</button>
      <anchored-position data-target="action-menu.overlay" id="create-overlay" anchor="create-button" popover="auto">
        <action-list>
          <ul id="create-list" role="menu" data-target="action-menu.list">
            <li role="none" class="ActionListItem"><button role="menuitem" class="ActionListContent">Task</button></li>
          </ul>
        </action-list>
      </anchored-position>
    </action-menu>
    <opce-spot-drop-modal-portal />
  `,
  imports: [OpSpotModule],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
class DropModalBesideMenuHostComponent {
  @ViewChild(SpotDropModalComponent) modal:SpotDropModalComponent;

  closed = vi.fn();
}

describe('SpotDropModalComponent outside presses', () => {
  let fixture:ComponentFixture<DropModalBesideMenuHostComponent>;

  const modal = () => fixture.componentInstance.modal;
  const press = (target:Element, type:string) => target.dispatchEvent(new PointerEvent(type, { bubbles: true, cancelable: true }));
  // The open modal covers the page in the narrow test viewport, so a real
  // pointer cannot reach the controls behind it.
  const click = (target:HTMLElement) => {
    press(target, 'pointerdown');
    press(target, 'pointerup');
    target.click();
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [DropModalBesideMenuHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(DropModalBesideMenuHostComponent);
    fixture.detectChanges();
    await openModal();
  });

  async function openModal():Promise<void> {
    await userEvent.click(screen.getByRole('button', { name: 'Include projects' }));
    await waitFor(() => expect(screen.getByRole('button', { name: 'Apply' })).toHaveFocus());
  }

  afterEach(() => fixture.destroy());

  it('closes when the button of an action menu is pressed, and the menu opens', async () => {
    click(screen.getByRole('button', { name: 'Create' }));

    expect(fixture.componentInstance.closed).toHaveBeenCalledOnce();
    expect(modal().opened).toBe(false);
    await waitFor(() => expect(screen.getByRole('menuitem', { name: 'Task' })).toHaveFocus());
  });

  it('stays open on a press inside its body', async () => {
    await userEvent.click(screen.getByRole('button', { name: 'Apply' }));

    expect(modal().opened).toBe(true);
  });

  it('closes once when its own trigger is pressed', () => {
    click(screen.getByRole('button', { name: 'Include projects' }));

    expect(modal().opened).toBe(false);
    expect(fixture.componentInstance.closed).toHaveBeenCalledOnce();
  });

  it('closes when an outside control is activated without a pointer', () => {
    screen.getByRole('button', { name: 'Create' }).click();

    expect(modal().opened).toBe(false);
  });

  it('returns focus to its trigger area when the outside press left focus inside', () => {
    const create = screen.getByRole('button', { name: 'Create' });

    press(create, 'pointerdown');
    press(create, 'pointerup');

    expect(modal().opened).toBe(false);
    expect((fixture.nativeElement as HTMLElement).querySelector('spot-drop-modal [tabindex="-1"]')).toHaveFocus();
  });

  it('leaves focus on the outside control the press moved it to', () => {
    const create = screen.getByRole('button', { name: 'Create' });

    press(create, 'pointerdown');
    create.focus();
    press(create, 'pointerup');

    expect(modal().opened).toBe(false);
    expect(create).toHaveFocus();
  });

  it('stays open when an outside press is canceled', () => {
    const outside = screen.getByRole('button', { name: 'Create' });

    press(outside, 'pointerdown');
    press(outside, 'pointercancel');
    press(outside, 'pointerup');

    expect(modal().opened).toBe(true);
  });

  it('stays open when a press that started inside ends outside', () => {
    press(screen.getByRole('button', { name: 'Apply' }), 'pointerdown');
    press(screen.getByRole('button', { name: 'Create' }), 'pointerup');

    expect(modal().opened).toBe(true);
  });
});

@Component({
  template: `
    <spot-drop-modal>
      <button slot="trigger" (click)="work.opened = true">Work</button>
      <div slot="body"><button>Apply work</button></div>
    </spot-drop-modal>
    <spot-drop-modal>
      <input slot="trigger" aria-label="Remaining work" (focus)="remaining.opened = true" />
      <div slot="body"><button>Apply remaining work</button></div>
    </spot-drop-modal>
    <opce-spot-drop-modal-portal />
  `,
  imports: [OpSpotModule],
})
class TwoDropModalsHostComponent {
  @ViewChildren(SpotDropModalComponent) modals:QueryList<SpotDropModalComponent>;

  get work():SpotDropModalComponent { return this.modals.first; }

  get remaining():SpotDropModalComponent { return this.modals.last; }
}

describe('SpotDropModalComponent beside another drop modal', () => {
  let fixture:ComponentFixture<TwoDropModalsHostComponent>;

  const press = (target:Element, type:string) => target.dispatchEvent(new PointerEvent(type, { bubbles: true, cancelable: true }));

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TwoDropModalsHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(TwoDropModalsHostComponent);
    fixture.detectChanges();
    await openWork();
  });

  async function openWork():Promise<void> {
    await userEvent.click(screen.getByRole('button', { name: 'Work' }));
    await waitFor(() => expect(screen.getByRole('button', { name: 'Apply work' })).toHaveFocus());
  }

  afterEach(() => fixture.destroy());

  it('leaves the modal that a press on its trigger opened in place of this one', async () => {
    const trigger = screen.getByRole('textbox', { name: 'Remaining work' });

    press(trigger, 'pointerdown');
    trigger.focus();
    await waitFor(() => expect(screen.getByRole('button', { name: 'Apply remaining work' })).toBeInTheDocument());
    press(trigger, 'pointerup');

    expect(fixture.componentInstance.work.opened).toBe(false);
    expect(fixture.componentInstance.remaining.opened).toBe(true);
    await waitFor(() => expect(screen.getByRole('button', { name: 'Apply remaining work' })).toHaveFocus());
    expect(screen.queryByRole('button', { name: 'Apply work' })).toBeNull();
  });
});

