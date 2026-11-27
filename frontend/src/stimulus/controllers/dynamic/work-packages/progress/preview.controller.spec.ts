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

import { waitFor } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import PreviewController from './preview.controller';

type ProgressField = 'estimated_hours'|'remaining_hours'|'done_ratio';

interface FieldState {
  value?:string;
  initial?:string;
  touched?:boolean;
}

const labels:Record<ProgressField, string> = {
  estimated_hours: 'Work',
  remaining_hours: 'Remaining work',
  done_ratio: '% Complete',
};

describe('Progress preview controller', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'work-packages--progress--preview': PreviewController },
    });
  });

  afterEach(() => ctx?.dispose());

  async function renderForm(fields:Partial<Record<ProgressField, FieldState>>) {
    const markup = (Object.keys(fields) as ProgressField[]).map((name) => {
      const { value = '', initial = value, touched = false } = fields[name]!;
      return `
        <label for="work_package_${name}">${labels[name]}</label>
        <input type="text" id="work_package_${name}" name="work_package[${name}]" value="${value}"
               data-work-packages--progress--preview-target="fieldInput"
               data-action="work-packages--progress--preview#markFieldAsTouched
                            work-packages--progress--preview#debouncedPreview">
        <input type="hidden" name="work_package[initial][${name}]" value="${initial}"
               data-referrer-field="${name}"
               data-work-packages--progress--preview-target="initialValueInput">
        <input type="hidden" name="work_package[${name}_touched]" value="${touched}"
               data-referrer-field="${name}"
               data-work-packages--progress--preview-target="touchedFieldInput">
      `;
    }).join('');

    await ctx.mount(`
      <turbo-frame id="progress-frame" disabled>
        <form action="/work_packages/1/progress"
              data-controller="work-packages--progress--preview"
              data-work-packages--progress--preview-target="form">
          ${markup}
        </form>
      </turbo-frame>
    `);
  }

  async function setValue(name:ProgressField, value:string) {
    const input = ctx.screen.getByLabelText(labels[name]);
    await userEvent.clear(input);
    if (value !== '') {
      await userEvent.type(input, value);
    }
  }

  function touchedFields():ProgressField[] {
    return Array.from(ctx.container.querySelectorAll<HTMLInputElement>('input[name$="_touched]"]'))
      .filter((input) => input.value === 'true')
      .map((input) => input.dataset.referrerField as ProgressField)
      .sort();
  }

  it('sends the touched fields with the preview request', async () => {
    await renderForm({
      estimated_hours: { value: '10h' },
      remaining_hours: { value: '4h' },
      done_ratio: { value: '60%' },
    });

    await setValue('estimated_hours', '12');

    const frame = ctx.container.querySelector('turbo-frame') as HTMLElement & { src:string };
    const previewParams = () => new URL(frame.src, window.location.origin).searchParams;
    await waitFor(() => {
      expect(frame.src).toContain('/work_packages/1/progress/preview?');
      expect(previewParams().get('work_package[estimated_hours]')).toBe('12');
    });
    const params = previewParams();
    expect(params.get('work_package[estimated_hours_touched]')).toBe('true');
    expect(params.get('work_package[remaining_hours_touched]')).toBe('false');
    expect(params.get('field')).toBe('work_package[estimated_hours]');
  });

  it('keeps a derived remaining work untouched when work changes again (cases 2 and 3)', async () => {
    await renderForm({
      estimated_hours: { value: '12h', initial: '10h', touched: true },
      remaining_hours: { value: '6h', initial: '4h' },
      done_ratio: { value: '50%', initial: '60%' },
    });

    await setValue('estimated_hours', '14');

    expect(touchedFields()).toEqual(['estimated_hours']);
  });

  it('derives work again when remaining work is set after work was cleared (case 23-11)', async () => {
    await renderForm({
      estimated_hours: { value: '', initial: '10h', touched: true },
      remaining_hours: { value: '', initial: '4h' },
      done_ratio: { value: '60%' },
    });

    await setValue('remaining_hours', '8h');

    expect(touchedFields()).toEqual(['done_ratio', 'remaining_hours']);
  });

  it('derives remaining work again when work is set after remaining work was cleared (case 23-14)', async () => {
    await renderForm({
      estimated_hours: { value: '', initial: '10h' },
      remaining_hours: { value: '', initial: '4h', touched: true },
      done_ratio: { value: '60%' },
    });

    await setValue('estimated_hours', '20h');

    expect(touchedFields()).toEqual(['done_ratio', 'estimated_hours']);
  });

  it('derives % complete again when work is set after work and % complete were cleared (case 33-1)', async () => {
    await renderForm({
      estimated_hours: { value: '', initial: '10h', touched: true },
      remaining_hours: { value: '4h' },
      done_ratio: { value: '', initial: '60%', touched: true },
    });

    await setValue('estimated_hours', '20h');

    expect(touchedFields()).toEqual(['estimated_hours', 'remaining_hours']);
  });

  it('derives nothing when work changes while remaining work and % complete are cleared (case 33-2)', async () => {
    await renderForm({
      estimated_hours: { value: '10h' },
      remaining_hours: { value: '', initial: '4h', touched: true },
      done_ratio: { value: '', initial: '60%', touched: true },
    });

    await setValue('estimated_hours', '1');
    expect(touchedFields()).toEqual(['done_ratio', 'estimated_hours', 'remaining_hours']);

    await setValue('estimated_hours', '');
    expect(touchedFields()).toEqual(['done_ratio', 'estimated_hours', 'remaining_hours']);
  });

  it('derives an initially empty work from remaining work and % complete (case 20-4)', async () => {
    await renderForm({
      estimated_hours: { value: '' },
      remaining_hours: { value: '' },
      done_ratio: { value: '' },
    });

    await setValue('remaining_hours', '2h');
    await setValue('done_ratio', '50%');

    expect(touchedFields()).toEqual(['done_ratio', 'remaining_hours']);
  });

  it('keeps deriving an initially empty work when remaining work changes again (case 20-4)', async () => {
    await renderForm({
      estimated_hours: { value: '4h', initial: '' },
      remaining_hours: { value: '2h', initial: '', touched: true },
      done_ratio: { value: '50%', initial: '', touched: true },
    });

    await setValue('remaining_hours', '10h');

    expect(touchedFields()).toEqual(['done_ratio', 'remaining_hours']);
  });

  it('keeps deriving an initially empty work after it got a derived value (case 30-1)', async () => {
    await renderForm({
      estimated_hours: { value: '100h', initial: '' },
      remaining_hours: { value: '60h', initial: '', touched: true },
      done_ratio: { value: '40%', initial: '', touched: true },
    });

    await setValue('done_ratio', '80%');

    expect(touchedFields()).toEqual(['done_ratio', 'remaining_hours']);
  });

  it('derives % complete when work changes after remaining work and % complete were both set', async () => {
    await renderForm({
      estimated_hours: { value: '10h' },
      remaining_hours: { value: '4h', touched: true },
      done_ratio: { value: '', initial: '60%', touched: true },
    });

    await setValue('estimated_hours', '20h');

    expect(touchedFields()).toEqual(['estimated_hours', 'remaining_hours']);
  });

  it('derives remaining work when work changes after remaining work and % complete were both set', async () => {
    await renderForm({
      estimated_hours: { value: '10h' },
      remaining_hours: { value: '4h', touched: true },
      done_ratio: { value: '50%', touched: true },
    });

    await setValue('estimated_hours', '20h');

    expect(touchedFields()).toEqual(['done_ratio', 'estimated_hours']);
  });

  it('derives % complete when remaining work changes and work is set', async () => {
    await renderForm({
      estimated_hours: { value: '10h' },
      remaining_hours: { value: '4h' },
      done_ratio: { value: '60%', touched: true },
    });

    await setValue('remaining_hours', '2h');

    expect(touchedFields()).toEqual(['remaining_hours']);
  });

  it('derives remaining work when % complete changes and work is set', async () => {
    await renderForm({
      estimated_hours: { value: '10h' },
      remaining_hours: { value: '4h', touched: true },
      done_ratio: { value: '60%' },
    });

    await setValue('done_ratio', '80%');

    expect(touchedFields()).toEqual(['done_ratio']);
  });

  it('keeps every touched field in status-based mode', async () => {
    await renderForm({
      estimated_hours: { value: '10h', touched: true },
      remaining_hours: { value: '5h', touched: true },
    });

    await setValue('estimated_hours', '20h');

    expect(touchedFields()).toEqual(['estimated_hours', 'remaining_hours']);
  });
});
