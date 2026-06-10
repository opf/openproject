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
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import FlashController, { SUCCESS_AUTOHIDE_TIMEOUT } from './flash.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('FlashController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { flash: FlashController },
    });
  });

  afterEach(() => ctx.dispose());

  describe('without autohide', () => {
    it('keeps flash items visible', async () => {
      await ctx.mount(`
        <div data-controller="flash">
          <div data-flash-target="item" data-autohide="true" role="alert">
            Success message
          </div>
        </div>
      `);

      expect(ctx.screen.getByRole('alert')).toBeInTheDocument();
    });
  });

  describe('with autohide', () => {
    it('schedules removal of autohide items', async () => {
      const timeoutSpy = vi.spyOn(globalThis, 'setTimeout');

      await ctx.mount(`
        <div data-controller="flash" data-flash-autohide-value="true">
          <div data-flash-target="item" data-autohide="true" role="alert">
            Success message
          </div>
        </div>
      `);

      const autohideCall = timeoutSpy.mock.calls.find(([, delay]) => delay === SUCCESS_AUTOHIDE_TIMEOUT);

      expect(autohideCall).toBeDefined();

      timeoutSpy.mockRestore();
    });

    it('does not schedule removal for items without data-autohide', async () => {
      const timeoutSpy = vi.spyOn(globalThis, 'setTimeout');

      await ctx.mount(`
        <div data-controller="flash" data-flash-autohide-value="true">
          <div data-flash-target="item" role="alert">
            Error message
          </div>
        </div>
      `);

      const autohideCall = timeoutSpy.mock.calls.find(([, delay]) => delay === SUCCESS_AUTOHIDE_TIMEOUT);

      expect(autohideCall).toBeUndefined();

      timeoutSpy.mockRestore();
    });
  });

  describe('flashTargetDisconnected', () => {
    it('removes empty item containers when flash target is removed', async () => {
      await ctx.mount(`
        <div data-controller="flash">
          <div data-flash-target="item" data-testid="item-container"></div>
          <div data-flash-target="flash" data-testid="flash-content">Content</div>
        </div>
      `);

      ctx.screen.getByTestId('flash-content').remove();
      await ctx.nextFrame();

      expect(ctx.screen.queryByTestId('item-container')).not.toBeInTheDocument();
    });
  });
});
