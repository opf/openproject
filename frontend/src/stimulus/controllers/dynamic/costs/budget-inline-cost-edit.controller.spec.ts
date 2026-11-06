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

import { fireEvent, screen } from '@testing-library/dom';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type BudgetInlineCostEditControllerType from './budget-inline-cost-edit.controller';

describe('Budget inline cost edit controller', () => {
  const identifier = 'costs--budget-inline-cost-edit';
  let ctx:StimulusTestContext;
  let BudgetInlineCostEditController:typeof BudgetInlineCostEditControllerType;

  beforeAll(async () => {
    ({ default: BudgetInlineCostEditController } = await import('./budget-inline-cost-edit.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { [identifier]: BudgetInlineCostEditController } });
  });

  afterEach(() => {
    ctx.dispose();
  });

  function fixture({ overridden = false, hint = true } = {}) {
    return `
      <form aria-label="Budget form">
        <div data-controller="${identifier}"
             data-action="keydown.esc->${identifier}#cancel"
             ${overridden ? `data-${identifier}-is-editing-value="true"` : ''}>
          <button type="button" aria-label="Edit"
                  ${overridden ? 'hidden' : ''}
                  data-${identifier}-target="editButton"
                  data-action="${identifier}#edit"></button>
          <button type="button" aria-label="Cancel"
                  ${overridden ? '' : 'hidden'}
                  data-${identifier}-target="cancelButton"
                  data-action="${identifier}#cancel"></button>
          <input type="text" aria-label="Budget" name="amount"
                 value="${overridden ? '99.00' : ''}"
                 ${overridden ? '' : 'hidden'}
                 data-${identifier}-target="input"
                 data-action="keydown.enter->${identifier}#keepValue">
          <div data-testid="display"
               ${overridden ? 'hidden' : ''}
               data-${identifier}-target="display"
               data-action="click->${identifier}#edit">20.00 EUR</div>
          <div data-testid="currency" ${overridden ? '' : 'hidden'} data-${identifier}-target="currency">EUR</div>
          <span hidden data-${identifier}-target="calculated">20.00</span>
          ${hint ? `<span data-testid="hint" ${overridden ? 'hidden' : ''} data-${identifier}-target="hint">No hourly rate</span>` : ''}
        </div>
      </form>
    `;
  }

  const input = () => screen.getByLabelText<HTMLInputElement>('Budget');
  const editButton = () => screen.getByLabelText<HTMLButtonElement>('Edit');
  const cancelButton = () => screen.getByLabelText<HTMLButtonElement>('Cancel');
  const submittedAmount = () => new FormData(screen.getByRole<HTMLFormElement>('form')).get('amount');

  function expectDisplayState() {
    expect(input()).not.toBeVisible();
    expect(cancelButton()).not.toBeVisible();
    expect(screen.getByTestId('currency')).not.toBeVisible();
    expect(editButton()).toBeVisible();
    expect(screen.getByTestId('display')).toBeVisible();
  }

  function expectEditState() {
    expect(input()).toBeVisible();
    expect(cancelButton()).toBeVisible();
    expect(screen.getByTestId('currency')).toBeVisible();
    expect(editButton()).not.toBeVisible();
    expect(screen.getByTestId('display')).not.toBeVisible();
  }

  describe('without an override', () => {
    beforeEach(async () => {
      await ctx.mount(fixture());
    });

    it('starts in display state without moving focus', () => {
      expectDisplayState();
      expect(document.activeElement).toBe(document.body);
    });

    it('submits a blank amount in display state', () => {
      expect(submittedAmount()).toBe('');
    });

    it('submits the typed amount in edit state and a blank one again after cancel', async () => {
      fireEvent.click(editButton());
      await ctx.nextFrame();
      fireEvent.input(input(), { target: { value: '77' } });

      expect(submittedAmount()).toBe('77');

      fireEvent.click(cancelButton());
      await ctx.nextFrame();

      expect(submittedAmount()).toBe('');
    });

    it('enters edit state from the edit button, prefilled with the calculated cost', async () => {
      fireEvent.click(editButton());
      await ctx.nextFrame();

      expectEditState();
      expect(input()).toHaveValue('20.00');
      expect(input()).toHaveFocus();
      expect(screen.getByTestId('hint')).not.toBeVisible();
    });

    it('enters edit state from the display with a click', async () => {
      fireEvent.click(screen.getByTestId('display'));
      await ctx.nextFrame();

      expect(input()).toBeVisible();
      expectEditState();
    });

    it('picks up a calculated cost changed by the row refresh', async () => {
      document.querySelector(`[data-${identifier}-target="calculated"]`)!.textContent = '35.50';

      fireEvent.click(editButton());
      await ctx.nextFrame();

      expect(input()).toHaveValue('35.50');
    });

    it('leaves edit state with the cancel button and returns focus to the edit button', async () => {
      fireEvent.click(editButton());
      await ctx.nextFrame();
      fireEvent.click(cancelButton());
      await ctx.nextFrame();

      expectDisplayState();
      expect(editButton()).toHaveFocus();
      expect(screen.getByTestId('hint')).toBeVisible();
    });

    it('leaves edit state with Escape', async () => {
      fireEvent.click(editButton());
      await ctx.nextFrame();
      fireEvent.keyDown(input(), { key: 'Escape' });
      await ctx.nextFrame();

      expect(input()).not.toBeVisible();
      expectDisplayState();
    });

    it('ignores Escape when not editing', async () => {
      fireEvent.keyDown(screen.getByTestId('display'), { key: 'Escape' });
      await ctx.nextFrame();

      expectDisplayState();
      expect(document.activeElement).toBe(document.body);
    });

    it('keeps a typed value when edit is triggered again', async () => {
      fireEvent.click(editButton());
      await ctx.nextFrame();
      fireEvent.input(input(), { target: { value: '77' } });
      ctx.getController<BudgetInlineCostEditControllerType>(identifier).edit();
      await ctx.nextFrame();

      expect(input()).toHaveValue('77');
    });

    it('does not submit the form on Enter in the input', async () => {
      fireEvent.click(editButton());
      await ctx.nextFrame();
      const notPrevented = fireEvent.keyDown(input(), { key: 'Enter' });

      expect(notPrevented).toBe(false);
      expectEditState();
    });
  });

  describe('with a saved override', () => {
    beforeEach(async () => {
      await ctx.mount(fixture({ overridden: true }));
    });

    it('starts in edit state with the override and without moving focus', () => {
      expectEditState();
      expect(input()).toHaveValue('99.00');
      expect(document.activeElement).toBe(document.body);
    });

    it('submits the saved override while editing', () => {
      expect(submittedAmount()).toBe('99.00');
    });

    it('blanks the input on cancel so that the override is cleared on save', async () => {
      fireEvent.click(cancelButton());
      await ctx.nextFrame();

      expectDisplayState();
      expect(submittedAmount()).toBe('');
    });
  });

  it('works without a hint element', async () => {
    await ctx.mount(fixture({ hint: false }));

    fireEvent.click(editButton());
    await ctx.nextFrame();

    expect(input()).toBeVisible();
    expectEditState();
  });
});
