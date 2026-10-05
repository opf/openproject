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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import ColorController from './color.controller';

const template = `
  <div data-controller="type-schemes--color"
       data-type-schemes--color-colors-value='{"1":"#FF0000","2":"#00FF00"}'>
    <span data-type-schemes--color-target="swatch"></span>
    <input type="radio" name="type_scheme[types][5][color_mode]" value="palette" checked
           data-type-schemes--color-target="mode" data-action="change->type-schemes--color#modeChanged">
    <input type="radio" name="type_scheme[types][5][color_mode]" value="custom"
           data-type-schemes--color-target="mode" data-action="change->type-schemes--color#modeChanged">
    <div data-type-schemes--color-target="palette">
      <input type="hidden" name="type_scheme[types][5][color_id]" value="1"
             data-type-schemes--color-target="select" data-action="change->type-schemes--color#selectChanged">
    </div>
    <div data-type-schemes--color-target="custom" hidden>
      <input type="color" value="#00FF00"
             data-type-schemes--color-target="picker" data-action="input->type-schemes--color#pickerChanged">
    </div>
  </div>`;

describe('ColorController', () => {
  let ctx:StimulusTestContext;

  const swatch = () => document.querySelector<HTMLElement>('[data-type-schemes--color-target="swatch"]')!;
  const select = () => document.querySelector<HTMLInputElement>('[data-type-schemes--color-target="select"]')!;
  const picker = () => document.querySelector<HTMLInputElement>('[data-type-schemes--color-target="picker"]')!;
  const custom = () => document.querySelector<HTMLElement>('[data-type-schemes--color-target="custom"]')!;
  const palette = () => document.querySelector<HTMLElement>('[data-type-schemes--color-target="palette"]')!;
  const customRadio = () => ctx.screen.getByDisplayValue<HTMLInputElement>('custom');
  const backgroundColor = () => swatch().style.backgroundColor.toLowerCase();

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { 'type-schemes--color': ColorController } });
    await ctx.mount(template);
  });

  afterEach(() => ctx.dispose());

  it('paints the swatch from the selected color id', () => {
    expect(['#ff0000', 'rgb(255, 0, 0)']).toContain(backgroundColor());
  });

  it('repaints the swatch when the underlying input changes', () => {
    select().value = '2';
    select().dispatchEvent(new Event('change', { bubbles: true }));

    expect(['#00ff00', 'rgb(0, 255, 0)']).toContain(backgroundColor());
  });

  it('switches to the picker and disables the palette input', () => {
    customRadio().click();

    expect(custom().hidden).toBe(false);
    expect(palette().hidden).toBe(true);
    expect(select().disabled).toBe(true);
    expect(picker().disabled).toBe(false);
  });

  it('paints the swatch while picking a custom color', () => {
    customRadio().click();
    picker().value = '#0000FF';
    picker().dispatchEvent(new Event('input', { bubbles: true }));

    expect(['#0000ff', 'rgb(0, 0, 255)']).toContain(backgroundColor());
  });

  it('ignores picker input while in palette mode', () => {
    picker().dispatchEvent(new Event('input', { bubbles: true }));

    expect(['#ff0000', 'rgb(255, 0, 0)']).toContain(backgroundColor());
  });
});
