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

import { vi } from 'vitest';
import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { BeforeunloadController } from './beforeunload.controller';

describe('BeforeunloadController', () => {
  let originalOpenProject:OpenProject;
  let controller:BeforeunloadController;

  beforeEach(() => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();
    vi.stubGlobal('I18n', { t: vi.fn().mockReturnValue('Leave page?') });
    controller = Object.create(BeforeunloadController.prototype) as BeforeunloadController;
  });

  afterEach(() => {
    window.OpenProject = originalOpenProject;
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  function turboBeforeVisit(url = 'http://example.com/projects') {
    return new CustomEvent('turbo:before-visit', {
      detail: { url },
      cancelable: true,
    });
  }

  function handle(event:Event) {
    controller.handleEvent(event);

    return event;
  }

  it('shows confirm when Angular edit forms have unsaved changes', () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);

    window.OpenProject.editFormsContainUnsavedChanges = () => true;
    const event = handle(turboBeforeVisit());

    expect(confirm).toHaveBeenCalledWith('Leave page?');
    expect(event.defaultPrevented).toBe(true);
  });

  it('shows confirm when pageState is edited', () => {
    window.OpenProject.pageState = 'edited';
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);

    const event = handle(turboBeforeVisit());

    expect(confirm).toHaveBeenCalledWith('Leave page?');
    expect(event.defaultPrevented).toBe(true);
  });

  it('does not show confirm when nothing is dirty', () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);

    const event = handle(turboBeforeVisit());

    expect(confirm).not.toHaveBeenCalled();
    expect(event.defaultPrevented).toBe(false);
  });

  it('does not prevent navigation when user accepts confirm', () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true);

    window.OpenProject.editFormsContainUnsavedChanges = () => true;
    const event = handle(turboBeforeVisit());

    expect(confirm).toHaveBeenCalledWith('Leave page?');
    expect(event.defaultPrevented).toBe(false);
  });

  it('only checks pageWasEdited for native beforeunload', () => {
    window.OpenProject.editFormsContainUnsavedChanges = () => true;
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
    const event = new Event('beforeunload', { cancelable: true });

    handle(event);

    expect(confirm).not.toHaveBeenCalled();
    expect(event.defaultPrevented).toBe(false);
  });

  it('resets pageState to pristine on turbo:render', () => {
    window.OpenProject.pageState = 'edited';

    handle(new Event('turbo:render'));

    expect(window.OpenProject.pageState).toBe('pristine');
  });

  it('sets pageState to submitted on form submit', () => {
    handle(new Event('submit'));

    expect(window.OpenProject.pageState).toBe('submitted');
  });
});
