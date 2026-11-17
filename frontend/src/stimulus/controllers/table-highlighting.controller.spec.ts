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

import { page, userEvent } from 'vitest/browser';
import TableHighlightingController from './table-highlighting.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

const tableTemplate = `
  <table data-controller="table-highlighting">
    <colgroup>
      <col>
      <col>
      <col data-highlight="false">
    </colgroup>
    <thead>
      <tr>
        <th>Name</th>
        <th>Value</th>
        <th>Notes</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Row 1</td>
        <td>100</td>
        <td>Note</td>
      </tr>
    </tbody>
  </table>
  <div data-testid="outside">Outside</div>
`;

const header = (name:string|RegExp) => page.getByRole('columnheader', { name });
const outside = page.getByTestId('outside');

describe('TableHighlightingController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'table-highlighting': TableHighlightingController },
    });

    await ctx.mount(tableTemplate);

    // Firefox fires native mouseenter when the fixture renders under the pointer
    // left behind by earlier tests, so start every test from a known position.
    await userEvent.hover(outside);
  });

  afterEach(() => ctx.dispose());

  it('adds hover class to col on header mouseenter', async () => {
    const col = ctx.container.querySelector('colgroup col:first-child')!;

    await userEvent.hover(header('Name'));

    expect(col).toHaveClass('hover');
  });

  it('removes hover class on header mouseleave', async () => {
    const col = ctx.container.querySelector('colgroup col:first-child')!;

    await userEvent.hover(header('Name'));

    expect(col).toHaveClass('hover');

    await userEvent.hover(outside);

    expect(col).not.toHaveClass('hover');
  });

  it('keeps hover class when the pointer leaves a descendant of the header', async () => {
    const th = ctx.screen.getByRole('columnheader', { name: 'Name' });
    const col = ctx.container.querySelector('colgroup col:first-child')!;
    const child = document.createElement('span');
    child.textContent = 'Child';
    th.appendChild(child);

    await userEvent.hover(page.getByText('Child'));
    await userEvent.hover(header(/^Name/), { position: { x: 10, y: 10 } });

    expect(col).toHaveClass('hover');

    await userEvent.hover(outside);

    expect(col).not.toHaveClass('hover');
  });

  it('removes hover class on disconnect', async () => {
    const col = ctx.container.querySelector('colgroup col:first-child')!;

    await userEvent.hover(header('Name'));
    ctx.container.querySelector('table')!.removeAttribute('data-controller');
    await ctx.nextFrame();

    expect(col).not.toHaveClass('hover');
  });

  it('skips headers spanning multiple columns', async () => {
    const th = ctx.screen.getByRole('columnheader', { name: 'Name' });
    const col = ctx.container.querySelector('colgroup col:first-child')!;
    th.setAttribute('colspan', '2');

    await userEvent.hover(header('Name'));

    expect(col).not.toHaveClass('hover');
  });

  it('skips columns with data-highlight="false"', async () => {
    const col = ctx.container.querySelector('colgroup col:nth-child(3)')!;

    await userEvent.hover(header('Notes'));

    expect(col).not.toHaveClass('hover');
  });

  it('does not error on tables without colgroup', async () => {
    await ctx.mount(`
      <table data-controller="table-highlighting">
        <thead><tr><th>Col</th></tr></thead>
        <tbody><tr><td>Val</td></tr></tbody>
      </table>
    `);

    expect(() => {
      ctx.screen.getAllByRole('columnheader').at(-1)!
        .dispatchEvent(new MouseEvent('mouseenter'));
    }).not.toThrow();
  });
});
