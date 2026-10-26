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

import { describe, expect, it } from 'vitest';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PERMITTED_CONTEXT_MENU_ACTIONS } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-static-context-menu-actions';
import { WorkPackageAuthorization } from './work-package-authorization.service';

describe('WorkPackageAuthorization', () => {
  const pathHelper = {
    workPackageShortPath: (id:string, { format }:{ format?:string } = {}) => (format ? `/wp/${id}.${format}` : `/wp/${id}`),
  } as unknown as PathHelperService;

  const buildWorkPackage = (extra:Record<string, unknown> = {}) => ({
    displayId: 'SP-1',
    id: 14,
    project: {},
    ...extra,
  }) as unknown as WorkPackageResource;

  const markdownWorkPackage = () => buildWorkPackage({ markdown: { href: '/work_packages/14.md' } });

  it('resolves view_markdown to the short path with the md format', () => {
    const authorization = new WorkPackageAuthorization(markdownWorkPackage(), pathHelper);

    expect(authorization.linkForAction({ key: 'view_markdown', link: 'markdown' }).link).toBe('/wp/SP-1.md');
  });

  it('lists view_markdown among the permitted actions only when the work package links markdown', () => {
    const permitted = new WorkPackageAuthorization(markdownWorkPackage(), pathHelper)
      .permittedActionsWithLinks(PERMITTED_CONTEXT_MENU_ACTIONS);
    const unavailable = new WorkPackageAuthorization(buildWorkPackage(), pathHelper)
      .permittedActionsWithLinks(PERMITTED_CONTEXT_MENU_ACTIONS);

    expect(permitted.find((action) => action.key === 'view_markdown')?.link).toBe('/wp/SP-1.md');
    expect(unavailable.map((action) => action.key)).not.toContain('view_markdown');
  });

  it('resolves copy_link_to_clipboard to the short path without a format', () => {
    const authorization = new WorkPackageAuthorization(markdownWorkPackage(), pathHelper);

    expect(authorization.linkForAction({ key: 'copy_link_to_clipboard', link: 'self' }).link).toBe('/wp/SP-1');
  });
});
