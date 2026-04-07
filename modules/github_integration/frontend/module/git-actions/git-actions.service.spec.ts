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

import { GitActionsService } from './git-actions.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

describe('GitActionsService', function () {
  let service:GitActionsService;

  const createWorkPackage = (overrides = {}) => {
    const defaults = {
      id: '42',
      displayId: '42',
      formattedId: '#42',
      subject: "Find the question, or don't",
      description: {
        raw: "I recently found\nthe answer is 42.\n\nWe'd need to compute\nthe correct question."
      },
      type: { name: 'User Story' },
      pathHelper: new PathHelperService()
    };
    const workPackage = { ...defaults, ...overrides };
    return (workPackage as WorkPackageResource);
  };

  beforeEach(() => {
    service = new GitActionsService();
  });


  it('produces a branch name, commit message, and a git command', () => {
    const wp = createWorkPackage();
    const origin = window.location.origin;

    expect(service.branchName(wp)).toEqual('user-story/42-find-the-question-or-don-t');
    expect(service.commitMessage(wp)).toEqual(`[#42] Find the question, or don't

I recently found
the answer is 42.

We'd need to compute
the correct question.

${origin}/wp/42`);

    expect(service.gitCommand(wp)).toEqual(`git checkout -b 'user-story/42-find-the-question-or-don-t' && git commit --allow-empty -m '[#42] Find the question, or don'\\''t' -m 'I recently found\nthe answer is 42.' -m 'We'\\''d need to compute\nthe correct question.' -m '${origin}/wp/42'`);
  });

  it('shell-escapes output for the git-command', () => {
    const wp = createWorkPackage({ subject: "' && rm -rf / #" });
    const origin = window.location.origin;

    expect(service.gitCommand(wp)).toEqual(`git checkout -b 'user-story/42-and-and-rm-rf' && git commit --allow-empty -m '[#42] '\\'' && rm -rf / #' -m 'I recently found\nthe answer is 42.' -m 'We'\\''d need to compute\nthe correct question.' -m '${origin}/wp/42'`);
  });

  it('uses semantic identifiers when in semantic mode', () => {
    const wp = createWorkPackage({ displayId: 'PROJ-42', formattedId: 'PROJ-42' });
    const origin = window.location.origin;

    expect(service.branchName(wp)).toEqual('user-story/proj-42-find-the-question-or-don-t');
    expect(service.commitMessage(wp)).toEqual(`[PROJ-42] Find the question, or don't

I recently found
the answer is 42.

We'd need to compute
the correct question.

${origin}/wp/PROJ-42`);
    expect(service.gitCommand(wp)).toEqual(`git checkout -b 'user-story/proj-42-find-the-question-or-don-t' && git commit --allow-empty -m '[PROJ-42] Find the question, or don'\\''t' -m 'I recently found\nthe answer is 42.' -m 'We'\\''d need to compute\nthe correct question.' -m '${origin}/wp/PROJ-42'`);
  });

  it('skips empty description', () => {
    const wp = createWorkPackage({ description: {raw: ''} });
    const origin = window.location.origin;

    expect(service.gitCommand(wp)).toEqual(`git checkout -b 'user-story/42-find-the-question-or-don-t' && git commit --allow-empty -m '[#42] Find the question, or don'\\''t' -m '${origin}/wp/42'`);
  });
});
