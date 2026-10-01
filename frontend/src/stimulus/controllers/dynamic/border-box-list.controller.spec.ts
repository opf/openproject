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

import BorderBoxListController from './border-box-list.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('BorderBoxListController', () => {
  let ctx:StimulusTestContext;

  const HTML = `
<div data-controller="border-box-list">
  <div class="Box"><ul data-border-box-list-target="list">
    <li class="Box-row">one</li><li class="Box-row">two</li>
  </ul></div>
  <template data-border-box-list-target="emptyStateTemplate"><li class="Box-row" data-empty-list-item="true">empty</li></template>
</div>`;

  // Mirrors a server-rendered empty :dynamic list: the ul contains only the
  // real placeholder row, and the template still parks the prototype.
  const EMPTY_HTML = `
<div data-controller="border-box-list">
  <div class="Box"><ul data-border-box-list-target="list">
    <li class="Box-row" data-empty-list-item="true">empty</li>
  </ul></div>
  <template data-border-box-list-target="emptyStateTemplate"><li class="Box-row" data-empty-list-item="true">empty</li></template>
</div>`;

  const flush = async () => { await new Promise((resolve) => { setTimeout(resolve); }); };
  const list = () => ctx.container.querySelector('[data-border-box-list-target="list"]')!;
  const placeholder = () => list().querySelector('[data-empty-list-item]');

  async function boot():Promise<StimulusTestContext> {
    return setupStimulusTest({ controllers: { 'border-box-list': BorderBoxListController } });
  }

  // Replaces the fixture, restarting the Stimulus application from scratch,
  // so an initially empty list boots with connect()-time state rather than
  // being mutated into that shape by a running controller instance.
  async function remount(html:string):Promise<void> {
    ctx.dispose();
    ctx = await boot();
    await ctx.mount(html);
  }

  beforeEach(async () => {
    ctx = await boot();
    await ctx.mount(HTML);
  });

  afterEach(() => {
    ctx.dispose();
  });

  it('inserts the placeholder when the last visible row disappears', async () => {
    list().querySelectorAll('li').forEach((row) => row.remove());
    await flush();
    expect(placeholder()).not.toBeNull();
  });

  it('inserts the placeholder when all rows are filter-hidden', async () => {
    list().querySelectorAll('li').forEach((row) => row.classList.add('d-none'));
    await flush();
    expect(placeholder()).not.toBeNull();
  });

  it('removes the placeholder when a hidden row becomes visible again', async () => {
    list().querySelectorAll('li').forEach((row) => row.classList.add('d-none'));
    await flush();
    list().querySelector('li:not([data-empty-list-item])')!.classList.remove('d-none');
    await flush();
    expect(placeholder()).toBeNull();
  });

  it('keeps exactly one placeholder across repeated syncs', async () => {
    list().querySelectorAll('li').forEach((row) => row.remove());
    await flush();
    // the placeholder insertion itself fires the observer again; a second
    // pass must not insert a duplicate
    await flush();
    expect(list().querySelectorAll('[data-empty-list-item]')).toHaveLength(1);
  });

  it('survives an empty -> populated -> empty cycle on an initially empty list', async () => {
    await remount(EMPTY_HTML);
    const row = document.createElement('li');
    row.className = 'Box-row';
    list().append(row);
    await flush();
    expect(placeholder()).toBeNull();
    row.remove();
    await flush();
    expect(placeholder()).not.toBeNull();
  });
});
