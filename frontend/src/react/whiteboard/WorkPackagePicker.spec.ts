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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { WorkPackagePicker } from './WorkPackagePicker';

function workPackage(id:number, subject:string) {
  return {
    id,
    subject,
    _links: {
      type: { href: '/api/v3/types/1', title: 'Task' },
      project: { href: '/api/v3/projects/1', title: 'Rocket' },
    },
  };
}

describe('WorkPackagePicker', () => {
  let container:HTMLElement;
  let root:Root;
  let fetchSpy:ReturnType<typeof vi.fn<typeof window.fetch>>;
  let onPick:ReturnType<typeof vi.fn<(reference:string) => void>>;
  let onOpenChange:ReturnType<typeof vi.fn<(open:boolean) => void>>;

  const input = () => container.querySelector<HTMLInputElement>('input[role="combobox"]')!;
  const options = () => Array.from(container.querySelectorAll<HTMLElement>('[role="option"]'));

  async function type(text:string) {
    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')!.set!.call(input(), text);
      input().dispatchEvent(new Event('input', { bubbles: true }));
    });
    await act(async () => { await new Promise((resolve) => { setTimeout(resolve, 350); }); });
  }

  function press(key:string) {
    act(() => { input().dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true })); });
  }

  function searchedTerm():string {
    const url = new URL(fetchSpy.mock.calls.at(-1)![0] as string, window.location.origin);
    return (JSON.parse(url.searchParams.get('filters')!) as { typeahead:{ values:string[] } }[])[0].typeahead.values[0];
  }

  beforeAll(() => {
    (globalThis as { IS_REACT_ACT_ENVIRONMENT?:boolean }).IS_REACT_ACT_ENVIRONMENT = true;
  });

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
    onPick = vi.fn<(reference:string) => void>();
    onOpenChange = vi.fn<(open:boolean) => void>();
    fetchSpy = vi.fn<typeof window.fetch>(() => Promise.resolve(new Response(JSON.stringify({
      _embedded: { elements: [workPackage(11, 'Plan the launch'), workPackage(12, 'Launch the rocket')] },
    }))));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);
    act(() => root.render(createElement(WorkPackagePicker, { open: true, showTrigger: true, onOpenChange, onPick })));
  });

  afterEach(() => {
    vi.restoreAllMocks();
    act(() => root.unmount());
    container.remove();
  });

  it('searches as the user types and lists the matches', async () => {
    await type('launch');

    expect(searchedTerm()).toBe('launch');
    expect(options().map((option) => option.textContent)).toEqual([
      'Task#11RocketPlan the launch',
      'Task#12RocketLaunch the rocket',
    ]);
  });

  it('picks the highlighted work package with the keyboard', async () => {
    await type('launch');
    press('ArrowDown');
    press('Enter');

    expect(onPick).toHaveBeenCalledWith('12');
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it('picks a work package by clicking it', async () => {
    await type('launch');
    act(() => options()[0].click());

    expect(onPick).toHaveBeenCalledWith('11');
  });

  it('searches for the referenced work package when a link is pasted', async () => {
    await type(`${window.location.origin}/projects/rocket/work_packages/12/activity`);

    expect(searchedTerm()).toBe('#12');
  });

  it('does not search for an empty input', async () => {
    await type('   ');

    expect(fetchSpy).not.toHaveBeenCalled();
    expect(options()).toEqual([]);
  });

  it('closes when pressing outside of it', () => {
    act(() => { document.body.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true })); });

    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it('stays open when pressing inside of it', () => {
    act(() => { input().dispatchEvent(new PointerEvent('pointerdown', { bubbles: true })); });

    expect(onOpenChange).not.toHaveBeenCalled();
  });

  it('uses an input type that Excalidraw does not intercept keystrokes from', () => {
    expect(input().type).toBe('text');
  });

  it('closes on escape', () => {
    press('Escape');

    expect(onOpenChange).toHaveBeenCalledWith(false);
  });
});
