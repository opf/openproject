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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { IProject } from 'core-app/core/state/projects/project.model';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';

const UNDISCLOSED_ANCESTOR = 'urn:openproject-org:api:v3:undisclosed';

// Helper function that recursively inserts a project into the hierarchy at the right place
export const insertInList = (
  projects:IProject[],
  project:IProject,
  list:IProjectData[],
  ancestors:IHalResourceLink[],
):IProjectData[] => {
  // In a set of projects, some ancestors may be undisclosed. The client then knows of its existence
  // but knows nothing more than that. Those projects receive an 'undisclosed' urn for their href. For building
  // the project hierarchy, they can be ignored.
  // Additionally, if the list of projects is incomplete, an ancestor might also be effectively invisible and can also be ignored
  const visibleAncestors = ancestors.filter((ancestor) => {
    return ancestor.href !== UNDISCLOSED_ANCESTOR &&
      projects.find((projectInList) => projectInList._links.self.href === ancestor.href);
  });

  if (!visibleAncestors.length) {
    return [
      ...list,
      {
        id: project.id,
        name: project.name,
        href: project._links.self.href,
        identifier: project.identifier,
        _type: project._type,
        disabled: false,
        children: [],
        position: 0,
      },
    ];
  }

  const ancestorHref = visibleAncestors[0].href;
  const ancestor:IProjectData|undefined = list.find((projectInList) => projectInList.href === ancestorHref);

  if (ancestor) {
    ancestor.children = insertInList(projects, project, ancestor.children, visibleAncestors.slice(1));
    return [...list];
  }

  const ancestorProject = projects.find((projectInList) => projectInList._links.self.href === ancestorHref);
  if (!ancestorProject) {
    return [...list];
  }

  return [
    ...list,
    {
      id: ancestorProject.id,
      name: ancestorProject.name,
      href: ancestorProject._links.self.href,
      identifier: ancestorProject.identifier,
      _type: ancestorProject._type,
      disabled: true,
      children: insertInList(projects, project, [], visibleAncestors.slice(1)),
      position: 0,
    },
  ];
};
