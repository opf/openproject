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
/* eslint-disable @typescript-eslint/no-empty-function, @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-return */

import { ActionEvent } from '@hotwired/stimulus';
import CheckableController from './checkable.controller';
import { createControllerInstance } from 'core-stimulus/test-helpers';

describe('CheckableController', () => {
  let controller:any;
  let inputs:HTMLInputElement[];

  beforeEach(() => {
    controller = createControllerInstance(CheckableController);

    inputs = [0, 1, 2].map(() => {
      const input = document.createElement('input');
      input.type = 'checkbox';
      input.checked = false;
      return input;
    });

    controller.checkboxTargets = inputs;
  });

  it('checks all when none are checked', () => {
    controller.toggleAll(new Event('click'));

    expect(inputs.every((i) => i.checked)).toBe(true);
  });

  it('checks all when some are checked (mixed state)', () => {
    inputs[0].checked = true; // mixed

    controller.toggleAll(new Event('click'));

    expect(inputs.every((i) => i.checked)).toBe(true);
  });

  it('unchecks all when all are checked', () => {
    inputs.forEach((i) => (i.checked = true));

    controller.toggleAll(new Event('click'));

    expect(inputs.every((i) => !i.checked)).toBe(true);
  });

  it('dispatches a bubbling change event', () => {
    const dispatchSpy = vi.spyOn(inputs[0], 'dispatchEvent');

    controller.toggleAll(new Event('click'));

    expect(dispatchSpy).toHaveBeenCalledTimes(1);

    const eventArg = vi.mocked(dispatchSpy).mock.lastCall![0];

    expect(eventArg.type).toBe('change');
    expect(eventArg.bubbles).toBe(true);
  });

  it('checkAll calls toggleChecked(true)', () => {
    vi.spyOn(controller, 'toggleChecked').mockImplementation(() => { });

    controller.checkAll(new Event('click'));

    expect(controller.toggleChecked).toHaveBeenCalledWith(controller.checkboxTargets, true);
  });

  it('uncheckAll calls toggleChecked(false)', () => {
    vi.spyOn(controller, 'toggleChecked').mockImplementation(() => { });

    controller.uncheckAll(new Event('click'));

    expect(controller.toggleChecked).toHaveBeenCalledWith(controller.checkboxTargets, false);
  });

  describe('toggleSelection', () => {
    function createActionEvent(params:ActionEvent['params']):ActionEvent {
      const event = new Event('click') as ActionEvent;
      event.params = params;
      return event;
    }

    it('throws when key param is missing', () => {
      const event = createActionEvent({ value: 'someValue' });

      expect(() => controller.toggleSelection(event)).toThrowError('Invariant failed: toggleSelection requires a key param');
    });

    it('throws when value param is missing', () => {
      const event = createActionEvent({ key: 'role' });

      expect(() => controller.toggleSelection(event)).toThrowError('Invariant failed: toggleSelection requires value param');
    });

    it('throws when both params are missing', () => {
      const event = createActionEvent({});

      expect(() => controller.toggleSelection(event)).toThrowError('Invariant failed: toggleSelection requires a key param');
    });

    it('toggles only checkboxes matching the key/value pair', () => {
      inputs[0].dataset.role = 'admin';
      inputs[1].dataset.role = 'member';
      inputs[2].dataset.role = 'admin';

      const event = createActionEvent({ key: 'role', value: 'admin' });

      controller.toggleSelection(event);

      expect(inputs[0].checked).toBe(true);
      expect(inputs[1].checked).toBe(false);
      expect(inputs[2].checked).toBe(true);
    });

    it('unchecks all matching checkboxes when all are checked', () => {
      inputs[0].dataset.role = 'admin';
      inputs[0].checked = true;
      inputs[1].dataset.role = 'member';
      inputs[1].checked = true;
      inputs[2].dataset.role = 'admin';
      inputs[2].checked = true;

      const event = createActionEvent({ key: 'role', value: 'admin' });

      controller.toggleSelection(event);

      expect(inputs[0].checked).toBe(false);
      expect(inputs[1].checked).toBe(true); // member stays checked
      expect(inputs[2].checked).toBe(false);
    });

    it('works with numeric value params (converted to string)', () => {
      inputs[0].dataset.columnId = '1';
      inputs[1].dataset.columnId = '2';
      inputs[2].dataset.columnId = '1';

      // Stimulus typecasts numeric strings to numbers, but our code converts back to string
      const event = createActionEvent({ key: 'columnId', value: 1 });

      controller.toggleSelection(event);

      expect(inputs[0].checked).toBe(true);
      expect(inputs[1].checked).toBe(false);
      expect(inputs[2].checked).toBe(true);
    });

    it('works with boolean value params (converted to string)', () => {
      inputs[0].dataset.active = 'true';
      inputs[1].dataset.active = 'false';
      inputs[2].dataset.active = 'true';

      // Stimulus typecasts "true"/"false" to boolean, but our code converts back to string
      const event = createActionEvent({ key: 'active', value: true });

      controller.toggleSelection(event);

      expect(inputs[0].checked).toBe(true);
      expect(inputs[1].checked).toBe(false);
      expect(inputs[2].checked).toBe(true);
    });
  });
});
