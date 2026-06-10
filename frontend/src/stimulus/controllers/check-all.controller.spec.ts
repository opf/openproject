/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import CheckAllController from './check-all.controller';
import CheckableController from './checkable.controller';

const checkAllTemplate = `
  <div data-controller="check-all" data-check-all-checkable-outlet="#checkables">
    <button id="check-all" data-action="check-all#checkAll">Check all</button>
    <button id="uncheck-all" data-action="check-all#uncheckAll">Uncheck all</button>
  </div>
`;

const checkableTemplate = `
  <div id="checkables" data-controller="checkable">
    <input type="checkbox" data-checkable-target="checkbox">
    <input type="checkbox" data-checkable-target="checkbox">
    <input type="checkbox" data-checkable-target="checkbox">
  </div>
`;

describe('CheckAllController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: {
        'check-all': CheckAllController,
        checkable: CheckableController,
      },
    });
  });

  afterEach(() => ctx.dispose());

  describe('without checkable controller', () => {
    beforeEach(async () => {
      await ctx.mount(checkAllTemplate);
    });

    it('does nothing and does not error', () => {
      expect(() => {
        ctx.screen.getByRole('button', { name: 'Check all' }).click();
        ctx.screen.getByRole('button', { name: 'Uncheck all' }).click();
      }).not.toThrow();
    });
  });

  describe('with checkable controller', () => {
    beforeEach(async () => {
      await ctx.mount(`
        ${checkableTemplate}
        ${checkAllTemplate}
      `);
    });

    it('toggles checkboxes', async () => {
      const inputs = ctx.screen.getAllByRole('checkbox');

      expect(inputs).toHaveLength(3);
      inputs.forEach((input) => {
        expect(input).not.toBeChecked();
      });

      ctx.screen.getByRole('button', { name: 'Check all' }).click();
      await ctx.nextFrame();

      inputs.forEach((input) => {
        expect(input).toBeChecked();
      });

      ctx.screen.getByRole('button', { name: 'Uncheck all' }).click();
      await ctx.nextFrame();

      inputs.forEach((input) => {
        expect(input).not.toBeChecked();
      });
    });

    it('applies aria-controls for connected outlet', () => {
      const checkAllEl = ctx.container.querySelector('[data-controller="check-all"]')!;

      expect(checkAllEl).toHaveAttribute('aria-controls');

      const ariaControls = checkAllEl.getAttribute('aria-controls')!;

      expect(ariaControls.split(/\s+/)).toContain('checkables');
    });

    it('removes aria-controls entry when outlet disconnects', async () => {
      const checkAllEl = ctx.container.querySelector('[data-controller="check-all"]')!;
      const ariaBefore = checkAllEl.getAttribute('aria-controls') ?? '';

      expect(ariaBefore.split(/\s+/)).toContain('checkables');

      ctx.container.querySelector('#checkables')!.remove();
      await ctx.nextFrame();

      const ariaAfter = checkAllEl.getAttribute('aria-controls') ?? '';

      expect(ariaAfter.split(/\s+/)).not.toContain('checkables');
    });
  });
});
