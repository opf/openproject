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

import { fireEvent, within } from '@testing-library/dom';
import { LiveRegionElement } from '@primer/live-region-element';
import type { MockInstance } from 'vitest';
import ColorContrastController from './color-contrast.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

const INVALID_MESSAGE = 'Hex code is not a valid 6-digit hexadecimal color code.';

function fixture({ serverInvalid = false } = {}):string {
  const invalidAttributes = serverInvalid ? 'invalid="true" aria-invalid="true"' : '';
  return `
    <form data-controller="color-contrast">
      <div class="FormControl">
        <label for="color_hexcode">Hex code</label>
        <input type="text"
               id="color_hexcode"
               name="color[hexcode]"
               ${invalidAttributes}
               aria-describedby="validation-hexcode"
               data-color-contrast-target="hexcode"
               data-invalid-message="${INVALID_MESSAGE}"
               data-action="input->color-contrast#markOutdated change->color-contrast#check">
        <div class="FormControl-inlineValidation" id="validation-hexcode" ${serverInvalid ? '' : 'hidden'}>
          <span class="FormControl-inlineValidation--visual" hidden></span>
          <span class="FormControl-inlineValidation--visual"></span>
          <span>${serverInvalid ? INVALID_MESSAGE : ''}</span>
        </div>
      </div>
      <button type="button" data-action="color-contrast#check">Check contrast</button>
      <section data-color-contrast-target="preview" hidden>
        <p data-color-contrast-target="outdated" hidden>Outdated</p>
        <span data-color-contrast-target="summary" data-template="{{count}} of 4 pass"></span>
      </section>
    </form>
  `;
}

function card(mode:'light'|'dark', usage:'foreground'|'background'):string {
  return `
    <li data-color-contrast-target="card">
      <h5>Used as ${usage}</h5>
      <div class="color-contrast--surface" data-color-mode="${mode}" data-${mode}-theme="${mode}">
        <span class="__hl_${usage}" data-color-contrast-target="sample">Sample text</span>
      </div>
      <dl>
        <div><dt>Text</dt><dd data-contrast-value="foreground"></dd></div>
        <div><dt>Background</dt><dd data-contrast-value="background"></dd></div>
      </dl>
      <span hidden data-contrast-verdict="pass">Pass</span>
      <span hidden data-contrast-verdict="fail">Fail</span>
      <span data-contrast-value="ratio"></span>
    </li>
  `;
}

function resultsFixture():string {
  return `
    <form data-controller="color-contrast">
      <div class="FormControl">
        <label for="color_hexcode">Hex code</label>
        <input type="text"
               id="color_hexcode"
               name="color[hexcode]"
               aria-describedby="validation-hexcode"
               data-color-contrast-target="hexcode"
               data-invalid-message="${INVALID_MESSAGE}"
               data-action="input->color-contrast#markOutdated change->color-contrast#check">
        <div class="FormControl-inlineValidation" id="validation-hexcode" hidden>
          <span class="FormControl-inlineValidation--visual" hidden></span>
          <span class="FormControl-inlineValidation--visual"></span>
          <span></span>
        </div>
      </div>
      <button type="button" data-action="color-contrast#check">Check contrast</button>
      <section data-color-contrast-target="preview" hidden>
        <p data-color-contrast-target="outdated" hidden>Outdated</p>
        <span data-color-contrast-target="summary" data-template="{{count}} of 4 pass"></span>
        <ul>
          ${card('light', 'foreground')}
          ${card('light', 'background')}
          ${card('dark', 'foreground')}
          ${card('dark', 'background')}
        </ul>
      </section>
    </form>
  `;
}

describe('ColorContrastController', () => {
  let ctx:StimulusTestContext;

  const hexcode = () => ctx.screen.getByRole<HTMLInputElement>('textbox', { name: 'Hex code' });
  const checkButton = () => ctx.screen.getByRole('button', { name: 'Check contrast' });
  const validation = () => ctx.container.querySelector<HTMLElement>('.FormControl-inlineValidation')!;
  const message = () => validation().querySelector<HTMLElement>('span:not(.FormControl-inlineValidation--visual)')!;
  const preview = () => ctx.container.querySelector<HTMLElement>('[data-color-contrast-target="preview"]')!;
  const outdated = () => ctx.container.querySelector<HTMLElement>('[data-color-contrast-target="outdated"]')!;

  let announceSpy:MockInstance<typeof LiveRegionElement.prototype.announce>;

  beforeEach(async () => {
    document.body.appendChild(document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
    ctx = await setupStimulusTest({
      controllers: { 'color-contrast': ColorContrastController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    document.body.querySelector('live-region')?.remove();
    vi.restoreAllMocks();
  });

  describe('client-side validation', () => {
    beforeEach(async () => {
      await ctx.mount(fixture());
    });

    it('shows the invalid message in the validation element on check', () => {
      hexcode().value = '#XXX';
      checkButton().click();

      expect(hexcode()).toBeInvalid();
      expect(hexcode()).toHaveAttribute('invalid', 'true');
      expect(hexcode()).toHaveAccessibleDescription(INVALID_MESSAGE);
      expect(validation()).toBeVisible();
      expect(preview()).not.toBeVisible();
    });

    it('shows the preview and no error for a valid hex code', () => {
      hexcode().value = '#fff';
      checkButton().click();

      expect(hexcode()).not.toHaveAttribute('aria-invalid');
      expect(validation()).not.toBeVisible();
      expect(preview()).toBeVisible();
    });

    it('runs the check on change', () => {
      hexcode().value = '#XXX';
      fireEvent.change(hexcode());

      expect(hexcode()).toBeInvalid();
    });

    it('clears the client error when the field is edited', () => {
      hexcode().value = '#XXX';
      checkButton().click();
      fireEvent.input(hexcode());

      expect(hexcode()).not.toHaveAttribute('aria-invalid');
      expect(hexcode()).not.toHaveAttribute('invalid');
      expect(validation()).not.toBeVisible();
      expect(message()).toBeEmptyDOMElement();
    });

    it('announces the invalid message', () => {
      hexcode().value = '#XXX';
      checkButton().click();

      expect(announceSpy).toHaveBeenCalledWith(INVALID_MESSAGE, expect.objectContaining({ politeness: 'assertive' }));
    });

    it('announces nothing for a valid hex code', () => {
      hexcode().value = '#fff';
      checkButton().click();

      expect(announceSpy).not.toHaveBeenCalled();
    });

    it('keeps the results current when the same hex code is entered again', () => {
      hexcode().value = '#fff';
      checkButton().click();
      hexcode().value = '#FFFFFF';
      fireEvent.input(hexcode());

      expect(outdated()).not.toBeVisible();
    });

    it('marks the results outdated when a different hex code is entered', () => {
      hexcode().value = '#fff';
      checkButton().click();
      hexcode().value = '#ff0';
      fireEvent.input(hexcode());

      expect(outdated()).toBeVisible();
    });

    it('keeps the preview hidden after an invalid check until the next check', () => {
      hexcode().value = '#fff';
      checkButton().click();
      hexcode().value = '#XXX';
      checkButton().click();
      expect(preview()).not.toBeVisible();
      expect(validation()).toBeVisible();

      hexcode().value = '#FFFFFF';
      fireEvent.input(hexcode());
      expect(validation()).not.toBeVisible();
      expect(preview()).not.toBeVisible();
      expect(outdated()).not.toBeVisible();

      checkButton().click();
      expect(preview()).toBeVisible();
      expect(outdated()).not.toBeVisible();
    });
  });

  describe('contrast results', () => {
    const cards = () => ctx.screen.getAllByRole('listitem');
    const valuesOf = (item:HTMLElement) => ({
      foreground: item.querySelector('[data-contrast-value="foreground"]')!.textContent,
      background: item.querySelector('[data-contrast-value="background"]')!.textContent,
      ratio: item.querySelector('[data-contrast-value="ratio"]')!.textContent,
      verdict: within(item).getByText(/^(Pass|Fail)$/, { ignore: '[hidden]' }).textContent,
    });

    beforeEach(async () => {
      await ctx.mount(resultsFixture());
    });

    it('reports foreground, background, ratio and verdict per theme and usage', () => {
      hexcode().value = '#FF69B4';
      checkButton().click();

      expect(cards().map(valuesOf)).toEqual([
        { foreground: '#FF1A8C', background: '#FFFFFF', ratio: '3.63:1', verdict: 'Fail' },
        { foreground: '#000000', background: '#FF69B4', ratio: '7.93:1', verdict: 'Pass' },
        { foreground: '#FF7EBF', background: '#0D1117', ratio: '8.11:1', verdict: 'Pass' },
        { foreground: '#FF7EBF', background: '#392133', ratio: '6.27:1', verdict: 'Pass' },
      ]);
      expect(ctx.screen.getByText('3 of 4 pass')).toBeVisible();
    });

    it('replaces the previous results on recheck', () => {
      hexcode().value = '#FF69B4';
      checkButton().click();
      hexcode().value = '#1F75D3';
      checkButton().click();

      expect(cards().map(valuesOf)).toEqual([
        { foreground: '#185BA5', background: '#FFFFFF', ratio: '6.81:1', verdict: 'Pass' },
        { foreground: '#000000', background: '#1F75D3', ratio: '4.54:1', verdict: 'Pass' },
        { foreground: '#68A6E9', background: '#0D1117', ratio: '7.38:1', verdict: 'Pass' },
        { foreground: '#68A6E9', background: '#102339', ratio: '6.20:1', verdict: 'Pass' },
      ]);
      expect(ctx.screen.getByText('4 of 4 pass')).toBeVisible();
      expect(ctx.screen.queryByText('3 of 4 pass')).toBeNull();
    });
  });

  describe('with a server-side error', () => {
    beforeEach(async () => {
      await ctx.mount(fixture({ serverInvalid: true }));
    });

    it('clears the server error when the field is edited', () => {
      fireEvent.input(hexcode());

      expect(hexcode()).not.toHaveAttribute('aria-invalid');
      expect(validation()).not.toBeVisible();
    });
  });
});
