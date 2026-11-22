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
import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { Component, Directive, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { settlePopover } from 'core-common/testing/timing';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { OpActionMenuComponent } from './op-action-menu.component';
import { OpActionMenuTriggerDirective } from './op-action-menu-trigger.directive';
import { OpActionMenuItems } from './op-action-menu-items';

class Deferred<T> {
  resolve!:(value:T) => void;

  reject!:(reason:unknown) => void;

  readonly promise = new Promise<T>((resolve, reject) => {
    this.resolve = resolve;
    this.reject = reject;
  });
}

@Directive({ selector: '[opTestMenuItems]' })
class TestMenuItemsDirective extends OpActionMenuItems {
  supply:() => OpContextMenuItem[]|PromiseLike<OpContextMenuItem[]> = () => [];

  calls = 0;

  protected buildItems():OpContextMenuItem[]|PromiseLike<OpContextMenuItem[]> {
    this.calls += 1;
    return this.supply();
  }
}

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, TestMenuItemsDirective],
  template: `
    <op-action-menu opTestMenuItems label="Create menu">
      <button opActionMenuTrigger [attr.aria-disabled]="disabled() || null">Create</button>
    </op-action-menu>
    <button type="button">Next</button>
  `,
})
class HostComponent {
  readonly disabled = signal(false);
}

describe('OpActionMenuItems', () => {
  let fixture:ComponentFixture<HostComponent>;
  let supplier:TestMenuItemsDirective;
  let component:OpActionMenuComponent;

  const settle = settlePopover;
  const items = (...names:string[]):OpContextMenuItem[] => names.map((linkText) => ({ linkText, onClick: () => true }));
  const trigger = () => screen.getByRole('button', { name: 'Create' });
  const next = () => screen.getByRole('button', { name: 'Next' });
  const menu = () => screen.getByRole('menu', { name: 'Create menu' });
  const overlay = () => (fixture.nativeElement as HTMLElement).querySelector<ActionMenuElement>('action-menu')!.overlay;
  const isOpen = () => overlay().matches(':popover-open');
  const render = async () => {
    await fixture.whenStable();
    await settle();
  };
  const deferredLoads = (...loads:Deferred<OpContextMenuItem[]>[]) => {
    const queue = [...loads];
    supplier.supply = () => queue.shift()!.promise;
  };
  const pressTrigger = async () => {
    trigger().focus();
    await userEvent.keyboard('{Enter}');
    await render();
  };
  const pressTriggerCapturingListeners = async () => {
    const spy = vi.spyOn(document, 'addEventListener');
    let calls:typeof spy.mock.calls;
    try {
      await pressTrigger();
    } finally {
      calls = [...spy.mock.calls];
      spy.mockRestore();
    }
    const signals = calls
      .filter(([type]) => type === 'pointerdown' || type === 'keydown' || type === 'click')
      .map(([, , options]) => (typeof options === 'object' ? options.signal : undefined))
      .filter((signal) => signal !== undefined);
    expect(signals).not.toHaveLength(0);
    return signals;
  };
  const expectFirstItemFocused = () => waitFor(() => expect(within(menu()).getAllByRole('menuitem')[0]).toHaveFocus());

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [HostComponent] }).compileComponents();
    fixture = TestBed.createComponent(HostComponent);
    const element = fixture.debugElement.query(By.directive(OpActionMenuComponent));
    supplier = element.injector.get(TestMenuItemsDirective);
    component = element.componentInstance as OpActionMenuComponent;
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('fills the menu when it opens', async () => {
    supplier.supply = () => items('Bug', 'Task');

    await userEvent.click(trigger());
    await render();

    expect(within(menu()).getAllByRole('menuitem').map((item) => item.textContent?.trim())).toEqual(['Bug', 'Task']);
    await expectFirstItemFocused();
  });

  it('opens nothing when the items it supplies right away are all hidden', async () => {
    supplier.supply = () => [{ linkText: 'Hidden', hidden: true, onClick: () => true }];

    await pressTrigger();

    expect(isOpen()).toBe(false);
    expect(trigger()).toHaveAttribute('aria-expanded', 'false');
    expect(trigger()).toHaveFocus();
  });

  it('opens only once the items have arrived', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);

    await pressTrigger();

    expect(isOpen()).toBe(false);
    expect(trigger()).toHaveAttribute('aria-expanded', 'false');

    load.resolve(items('Bug', 'Task'));
    await render();

    expect(isOpen()).toBe(true);
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'true'));
    await expectFirstItemFocused();
  });

  it('opens nothing when the load yields no visible items', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    load.resolve([{ linkText: 'Hidden', hidden: true, onClick: () => true }]);
    await render();

    expect(isOpen()).toBe(false);
    expect(trigger()).toHaveAttribute('aria-expanded', 'false');
    expect(trigger()).toHaveFocus();
  });

  it('opens nothing when the load fails', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    load.reject(new Error('Request failed'));
    await render();

    expect(isOpen()).toBe(false);
    expect(trigger()).toHaveFocus();
  });

  it('loads once and shows one menu when clicked twice while loading', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);

    await pressTrigger();
    await pressTrigger();
    load.resolve(items('Bug'));
    await render();

    expect(supplier.calls).toBe(1);
    expect(isOpen()).toBe(true);
    expect(document.querySelectorAll(':popover-open')).toHaveLength(1);
    expect(screen.getAllByRole('menu')).toHaveLength(1);
  });

  it('stays closed when the trigger was disabled during the load', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    fixture.componentInstance.disabled.set(true);
    await render();
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(false);
    expect(trigger()).toHaveAttribute('aria-expanded', 'false');
    expect(component.items()).toEqual([]);
  });

  it('stays closed when the menu was destroyed during the load', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    const listeners = await pressTriggerCapturingListeners();

    fixture.destroy();
    load.resolve(items('Bug'));
    await settle();

    expect(document.querySelectorAll(':popover-open')).toHaveLength(0);
    expect(listeners.every((signal) => signal.aborted)).toBe(true);
    expect(() => {
      fireEvent.pointerDown(document.body);
      fireEvent.keyDown(document.body, { key: 'Tab' });
    }).not.toThrow();
  });

  it('abandons the load when the trigger is disabled, even if re-enabled before it resolves', async () => {
    const first = new Deferred<OpContextMenuItem[]>();
    const second = new Deferred<OpContextMenuItem[]>();
    deferredLoads(first, second);
    const listeners = await pressTriggerCapturingListeners();

    fixture.componentInstance.disabled.set(true);
    await render();
    fixture.componentInstance.disabled.set(false);
    await render();
    first.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(false);
    expect(listeners.every((signal) => signal.aborted)).toBe(true);

    await pressTrigger();
    second.resolve(items('Task'));
    await render();

    expect(supplier.calls).toBe(2);
    expect(isOpen()).toBe(true);
    await expectFirstItemFocused();
  });

  it('removes its listeners once a load has opened the menu, leaving Escape and Tab to the menu', async () => {
    const first = new Deferred<OpContextMenuItem[]>();
    const second = new Deferred<OpContextMenuItem[]>();
    deferredLoads(first, second);
    const listeners = await pressTriggerCapturingListeners();
    first.resolve(items('Bug', 'Task'));
    await render();
    await expectFirstItemFocused();

    expect(listeners.every((signal) => signal.aborted)).toBe(true);

    await userEvent.keyboard('{ArrowDown}');
    expect(within(menu()).getByRole('menuitem', { name: 'Task' })).toHaveFocus();
    await userEvent.keyboard('{Escape}');
    await settle();
    expect(isOpen()).toBe(false);
    expect(trigger()).toHaveFocus();

    await pressTrigger();
    second.resolve(items('Bug'));
    await render();
    await expectFirstItemFocused();
    await userEvent.tab();
    await settle();
    expect(isOpen()).toBe(false);
  });

  it('removes its listeners when a load is abandoned and loads again on the next click', async () => {
    const first = new Deferred<OpContextMenuItem[]>();
    const second = new Deferred<OpContextMenuItem[]>();
    deferredLoads(first, second);
    const listeners = await pressTriggerCapturingListeners();
    await userEvent.keyboard('{Escape}');

    expect(listeners.every((signal) => signal.aborted)).toBe(true);
    await userEvent.tab();
    await userEvent.click(next());
    await settle();
    expect(isOpen()).toBe(false);

    await pressTrigger();
    first.resolve(items('Bug'));
    second.resolve(items('Task'));
    await render();

    expect(supplier.calls).toBe(2);
    expect(within(menu()).getAllByRole('menuitem').map((item) => item.textContent?.trim())).toEqual(['Task']);
  });

  it('loads again on the next click after a failed load', async () => {
    const first = new Deferred<OpContextMenuItem[]>();
    const second = new Deferred<OpContextMenuItem[]>();
    deferredLoads(first, second);
    const listeners = await pressTriggerCapturingListeners();
    first.reject(new Error('Request failed'));
    await render();

    expect(listeners.every((signal) => signal.aborted)).toBe(true);

    await pressTrigger();
    second.resolve(items('Bug'));
    await render();

    expect(supplier.calls).toBe(2);
    expect(isOpen()).toBe(true);
    await expectFirstItemFocused();
  });

  it('opens although another element was focused programmatically during the load', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    next().focus();
    load.resolve(items('Bug', 'Task'));
    await render();
    await settle();

    expect(isOpen()).toBe(true);
    await expectFirstItemFocused();
    await userEvent.keyboard('{ArrowDown}');
    expect(within(menu()).getByRole('menuitem', { name: 'Task' })).toHaveFocus();
  });

  it('stays closed after Tab between the load and the opening', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    load.resolve(items('Bug'));
    await load.promise;
    fireEvent.keyDown(document.activeElement!, { key: 'Tab' });
    await render();

    expect(isOpen()).toBe(false);
  });

  it('stays closed after a pointer press on another control during the load', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    await userEvent.click(next());
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(false);
  });

  it.each(['Tab', 'Escape'])('stays closed after %s during the load', async (key) => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    await userEvent.keyboard(`{${key}}`);
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(false);
  });

  it('abandons the load when another control is clicked programmatically', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    next().click();
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(false);
  });

  it('abandons the load when a shortcut key is pressed', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    await userEvent.keyboard('s');
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(false);
  });

  it.each(['{ArrowDown}', '{End}', '{PageDown}'])('keeps the load when %s is pressed', async (key) => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    await userEvent.keyboard(key);
    load.resolve(items('Bug', 'Task'));
    await render();

    expect(isOpen()).toBe(true);
    await expectFirstItemFocused();
  });

  it('keeps the load while text is being composed', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    fireEvent.keyDown(trigger(), { key: 'a', isComposing: true });
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(true);
  });

  it('keeps the load when only a modifier key is pressed', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    await pressTrigger();

    await userEvent.keyboard('{Shift}');
    load.resolve(items('Bug'));
    await render();

    expect(isOpen()).toBe(true);
  });

  it('starts a new load on the next click after an abandoned load', async () => {
    const first = new Deferred<OpContextMenuItem[]>();
    const second = new Deferred<OpContextMenuItem[]>();
    deferredLoads(first, second);
    await pressTrigger();
    await userEvent.keyboard('{Escape}');

    await pressTrigger();
    expect(supplier.calls).toBe(2);
    first.resolve(items('Bug'));
    await render();
    expect(isOpen()).toBe(false);

    second.resolve(items('Task'));
    await render();

    expect(isOpen()).toBe(true);
    expect(within(menu()).getAllByRole('menuitem').map((item) => item.textContent?.trim())).toEqual(['Task']);
  });

  it('opens from a programmatic click with focus on the body', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    deferredLoads(load);
    (document.activeElement as HTMLElement|null)?.blur();
    trigger().click();
    await render();

    load.resolve(items('Bug', 'Task'));
    await render();

    await expectFirstItemFocused();
    await userEvent.keyboard('{ArrowDown}');
    expect(within(menu()).getByRole('menuitem', { name: 'Task' })).toHaveFocus();
  });

  it('empties the menu on close', async () => {
    supplier.supply = () => items('Bug');
    await userEvent.click(trigger());
    await render();
    expect(component.items()).toEqual([expect.objectContaining({ linkText: 'Bug' })]);

    await userEvent.keyboard('{Escape}');
    await render();

    expect(isOpen()).toBe(false);
    expect(component.items()).toEqual([]);
  });
});

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, TestMenuItemsDirective],
  template: `
    <op-action-menu opTestMenuItems label="Create menu">
      <button opActionMenuTrigger>Create</button>
    </op-action-menu>
    <op-action-menu opTestMenuItems label="More menu">
      <button opActionMenuTrigger>More</button>
    </op-action-menu>
  `,
})
class TwoMenusHostComponent {}

describe('OpActionMenuItems on two menus', () => {
  let fixture:ComponentFixture<TwoMenusHostComponent>;

  const items = (...names:string[]):OpContextMenuItem[] => names.map((linkText) => ({ linkText, onClick: () => true }));
  const overlays = () => Array.from((fixture.nativeElement as HTMLElement).querySelectorAll<ActionMenuElement>('action-menu'))
    .map((element) => element.overlay);
  const render = async () => {
    await fixture.whenStable();
    await settlePopover();
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TwoMenusHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(TwoMenusHostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('shows only the menu requested last when its load resolves first', async () => {
    const [createSupplier, moreSupplier] = fixture.debugElement
      .queryAll(By.directive(TestMenuItemsDirective))
      .map((element) => element.injector.get(TestMenuItemsDirective));
    const createLoad = new Deferred<OpContextMenuItem[]>();
    const moreLoad = new Deferred<OpContextMenuItem[]>();
    createSupplier.supply = () => createLoad.promise;
    moreSupplier.supply = () => moreLoad.promise;

    screen.getByRole('button', { name: 'Create' }).focus();
    await userEvent.keyboard('{Enter}');
    await render();
    screen.getByRole('button', { name: 'More' }).click();
    await render();
    moreLoad.resolve(items('Copy link'));
    await render();
    createLoad.resolve(items('Bug'));
    await render();

    const [createOverlay, moreOverlay] = overlays();
    expect(moreOverlay.matches(':popover-open')).toBe(true);
    expect(createOverlay.matches(':popover-open')).toBe(false);
    expect(within(screen.getByRole('menu', { name: 'More menu' })).getByRole('menuitem', { name: 'Copy link' })).toHaveFocus();
  });
});

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, OpTooltipDirective, TestMenuItemsDirective],
  template: `
    <op-action-menu opTestMenuItems label="Create menu">
      <button opActionMenuTrigger opTooltip label="Create work package">+</button>
    </op-action-menu>
  `,
})
class TooltipTriggerHostComponent {}

describe('OpActionMenuItems on a trigger with a tooltip', () => {
  let fixture:ComponentFixture<TooltipTriggerHostComponent>;

  const trigger = () => screen.getByRole('button', { name: 'Create work package' });
  const tooltip = () => (fixture.nativeElement as HTMLElement).querySelector('tool-tip')!;
  const overlay = () => (fixture.nativeElement as HTMLElement).querySelector<ActionMenuElement>('action-menu')!.overlay;
  const render = async () => {
    await fixture.whenStable();
    await settlePopover();
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TooltipTriggerHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(TooltipTriggerHostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('abandons the load on one Escape although the tooltip was open', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    const supplier = fixture.debugElement.query(By.directive(TestMenuItemsDirective)).injector.get(TestMenuItemsDirective);
    supplier.supply = () => load.promise;
    trigger().focus();
    await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));

    await userEvent.keyboard('{Enter}');
    await render();
    await userEvent.keyboard('{Escape}');
    load.resolve([{ linkText: 'Bug', onClick: () => true }]);
    await render();

    expect(overlay().matches(':popover-open')).toBe(false);
    expect(tooltip().matches(':popover-open')).toBe(false);
  });

  it('abandons the load on Escape when the tooltip was shown again by hovering', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    const supplier = fixture.debugElement.query(By.directive(TestMenuItemsDirective)).injector.get(TestMenuItemsDirective);
    supplier.supply = () => load.promise;
    trigger().focus();
    await userEvent.keyboard('{Enter}');
    await render();
    await userEvent.hover(trigger());
    await waitFor(() => expect(tooltip().matches(':popover-open')).toBe(true));

    await userEvent.keyboard('{Escape}');
    load.resolve([{ linkText: 'Bug', onClick: () => true }]);
    await render();

    expect(overlay().matches(':popover-open')).toBe(false);
  });
});

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, TestMenuItemsDirective],
  template: `
    <div style="display: flex; justify-content: flex-end; padding-block-start: 200px">
      <op-action-menu opTestMenuItems label="More actions" align="end">
        <button opActionMenuTrigger>More</button>
      </op-action-menu>
    </div>
  `,
})
class EndAlignedHostComponent {}

describe('OpActionMenuItems on an end-aligned menu', () => {
  let fixture:ComponentFixture<EndAlignedHostComponent>;

  const overlay = () => (fixture.nativeElement as HTMLElement).querySelector<ActionMenuElement>('action-menu')!.overlay;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [EndAlignedHostComponent] }).compileComponents();
    fixture = TestBed.createComponent(EndAlignedHostComponent);
    await fixture.whenStable();
  });

  afterEach(() => fixture.destroy());

  it('shows a loaded menu at its final position from its first frame', async () => {
    const load = new Deferred<OpContextMenuItem[]>();
    const supplier = fixture.debugElement.query(By.directive(TestMenuItemsDirective)).injector.get(TestMenuItemsDirective);
    supplier.supply = () => load.promise;
    screen.getByRole('button', { name: 'More' }).focus();
    await userEvent.keyboard('{Enter}');
    await fixture.whenStable();
    await settlePopover();

    const painted:DOMRect[] = [];
    const sampleAfterEachFrame = () => requestAnimationFrame(() => {
      setTimeout(() => {
        if (overlay().matches(':popover-open')) {
          painted.push(overlay().getBoundingClientRect());
        }
        if (painted.length < 4) {
          sampleAfterEachFrame();
        }
      });
    });
    sampleAfterEachFrame();
    load.resolve(['Configure view', 'Add columns', 'Sort by'].map((linkText) => ({ linkText, onClick: () => true })));
    await waitFor(() => expect(painted).toHaveLength(4));

    const settled = painted[3];
    expect({ left: Math.round(painted[0].left), top: Math.round(painted[0].top) })
      .toEqual({ left: Math.round(settled.left), top: Math.round(settled.top) });
  });
});
