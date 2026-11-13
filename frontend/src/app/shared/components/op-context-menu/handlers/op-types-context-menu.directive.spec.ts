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
import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { settlePopover } from 'core-common/testing/timing';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { OpTypesContextMenuDirective } from './op-types-context-menu.directive';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, OpTypesContextMenuDirective],
  template: `
    <op-action-menu opTypesCreateDropdown projectIdentifier="demo" label="Create new work package">
      <button opActionMenuTrigger
        type="button"
        [disabled]="createPaneOpen()"
        [attr.aria-disabled]="notAllowed() || null">Create</button>
    </op-action-menu>
  `,
})
class HostComponent {
  createPaneOpen = signal(false);

  notAllowed = signal(false);
}

describe('OpTypesContextMenuDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let resolveForm:() => void;
  let getEmptyForm:ReturnType<typeof vi.fn>;
  let turboVisit:ReturnType<typeof vi.fn>;
  let isMobile:boolean;

  const settle = settlePopover;
  const button = () => screen.getByRole('button', { name: 'Create' });
  const menus = () => screen.queryAllByRole('menu', { name: 'Create new work package' });
  const openedMenu = async () => {
    await userEvent.click(button());
    resolveForm();
    await fixture.whenStable();
    await settle();
    return screen.findByRole('menu', { name: 'Create new work package' });
  };

  beforeEach(async () => {
    isMobile = false;
    turboVisit = vi.fn();
    vi.stubGlobal('Turbo', { visit: turboVisit });
    getEmptyForm = vi.fn(() => new Promise((resolve) => {
      resolveForm = () => resolve({
        schema: { type: { allowedValues: [{ id: '7', name: 'Bug' }, { id: '1', name: 'Task' }] } },
      });
    }));

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: WorkPackageCreateService, useValue: { getEmptyForm } },
        { provide: PathHelperService, useValue: { projectWorkPackageNewPath: (id:string) => `/projects/${id}/work_packages/new`, workPackageNewPath: () => '/work_packages/new' } },
        { provide: CurrentProjectService, useValue: { id: '5', identifier: 'demo' } },
        { provide: BrowserDetector, useValue: { get isMobile() { return isMobile; } } },
        { provide: UrlParamsService, useValue: { splitCreatePath: () => '/projects/demo/work_packages/create_new' } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  });

  afterEach(() => {
    fixture.destroy();
    vi.unstubAllGlobals();
  });

  it('lists types styled as the quick-add menu', async () => {
    const menu = await openedMenu();

    const items = within(menu).getAllByRole('menuitem');
    expect(items.map((item) => item.textContent?.trim())).toEqual(['Bug', 'Task']);
    items.forEach((item) => expect(item.querySelector('svg')).toBeNull());
    expect(within(items[0]).getByText('Bug')).toHaveClass('__hl_uppercase', '__hl_foreground', '__hl_type_7');
  });

  it('opens the create form in the content frame when a type is chosen', async () => {
    const menu = await openedMenu();

    const href = new URL(within(menu).getByRole('menuitem', { name: 'Bug' }).getAttribute('href')!, window.location.origin);
    expect(href.pathname).toBe('/projects/demo/work_packages/create_new');
    expect(href.searchParams.get('type')).toBe('7');
    await userEvent.click(within(menu).getByRole('menuitem', { name: 'Bug' }));

    expect(turboVisit).toHaveBeenCalledTimes(1);
    const [url, options] = turboVisit.mock.calls[0] as [string, object];
    expect(new URL(url).pathname).toBe('/projects/demo/work_packages/create_new');
    expect(new URL(url).searchParams.get('type')).toBe('7');
    expect(options).toEqual({ frame: 'content-bodyRight', action: 'advance' });
  });

  it('opens once when clicked twice while loading', async () => {
    await userEvent.click(button());
    await userEvent.click(button());
    resolveForm();
    await fixture.whenStable();
    await settle();

    await waitFor(() => expect(menus()).toHaveLength(1));
    expect(getEmptyForm).toHaveBeenCalledTimes(1);
  });

  it('closes when clicked while open', async () => {
    await openedMenu();
    expect(button()).toHaveAttribute('aria-expanded', 'true');

    await userEvent.click(button());
    await settle();

    expect(button()).toHaveAttribute('aria-expanded', 'false');
  });

  it('opens nothing when the button is aria-disabled', async () => {
    fixture.componentInstance.notAllowed.set(true);
    await fixture.whenStable();

    fireEvent.click(button());
    await fixture.whenStable();
    await settle();

    expect(getEmptyForm).not.toHaveBeenCalled();
    expect(button()).toHaveAttribute('aria-expanded', 'false');
  });

  it('opens nothing while the create pane disables the button', async () => {
    fixture.componentInstance.createPaneOpen.set(true);
    await fixture.whenStable();
    const overlay = document.querySelector<HTMLElement & { overlay:HTMLElement }>('action-menu')!.overlay;

    overlay.showPopover();
    await fixture.whenStable();
    await settle();

    expect(button()).toBeDisabled();
    expect(getEmptyForm).not.toHaveBeenCalled();
    expect(overlay.matches(':popover-open')).toBe(false);
    expect(button()).toHaveAttribute('aria-expanded', 'false');
  });

  it('follows the href of a type chosen with a modifier key', async () => {
    const menu = await openedMenu();
    const item = within(menu).getByRole('menuitem', { name: 'Bug' });
    let prevented:boolean|undefined;
    menu.addEventListener('click', (event) => { prevented = event.defaultPrevented; });
    const stopNavigation = (event:Event) => event.preventDefault();
    document.addEventListener('click', stopNavigation);

    fireEvent.click(item, { ctrlKey: true });
    document.removeEventListener('click', stopNavigation);

    expect(prevented).toBe(false);
    expect(turboVisit).not.toHaveBeenCalled();
  });

  describe('on mobile', () => {
    it.skipIf(!('navigation' in window))('navigates to the full new work package page', async () => {
      isMobile = true;
      const menu = await openedMenu();
      const item = within(menu).getByRole('menuitem', { name: 'Bug' });
      const navigation = (window as unknown as { navigation:EventTarget }).navigation;
      const destinations:URL[] = [];
      const blockNavigation = (event:Event) => {
        event.preventDefault();
        destinations.push(new URL((event as Event & { destination:{ url:string } }).destination.url));
      };
      navigation.addEventListener('navigate', blockNavigation);

      fireEvent.click(item);
      navigation.removeEventListener('navigate', blockNavigation);

      expect(destinations).toHaveLength(1);
      expect(destinations[0].pathname).toBe('/projects/5/work_packages/new');
      expect(destinations[0].searchParams.get('type')).toBe('7');
      expect(turboVisit).not.toHaveBeenCalled();
    });
  });
});
