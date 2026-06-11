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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type CustomFieldRoleAssignmentControllerType from './custom-field-role-assignment.controller';

describe('Custom field role assignment controller', () => {
  let ctx:StimulusTestContext;
  let CustomFieldRoleAssignmentController:typeof CustomFieldRoleAssignmentControllerType;
  let request:Mock;
  let previewCustomFieldRoleAssignmentDialog:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: CustomFieldRoleAssignmentController } = await import('./custom-field-role-assignment.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    previewCustomFieldRoleAssignmentDialog = vi.fn().mockReturnValue('/custom_fields/7/preview_role_assignment');
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { request },
          pathHelperService: { previewCustomFieldRoleAssignmentDialog },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'admin--custom-field-role-assignment': CustomFieldRoleAssignmentController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderAssignment() {
    await ctx.mount(`
      <div data-controller="admin--custom-field-role-assignment"
           data-admin--custom-field-role-assignment-initial-role-value="1"
           data-admin--custom-field-role-assignment-custom-field-id-value="7"></div>
    `);
    return ctx.getController<CustomFieldRoleAssignmentControllerType>('admin--custom-field-role-assignment');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderAssignment();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('requests the preview dialog turbo stream', async () => {
    const controller = await renderAssignment();

    void controller.showPreviewModal();

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith(
        '/custom_fields/7/preview_role_assignment',
        { headers: { Accept: 'text/vnd.turbo-stream.html' } },
      );
    });
  });

  it('does not request when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderAssignment();
    const root = ctx.container.querySelector('[data-controller="admin--custom-field-role-assignment"]')!;

    void controller.showPreviewModal();
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { request },
        pathHelperService: { previewCustomFieldRoleAssignmentDialog },
      },
    });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });
});
