//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injectable } from '@angular/core';
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";

class Apiv3Paths {
  readonly apiV3Base:string;

  constructor(basePath:string) {
    this.apiV3Base = basePath + '/api/v3';
  }

  /**
   * Preview markup path
   *
   * Primarily used from ckeditor
   * https://github.com/opf/commonmark-ckeditor-build/
   *
   * @param context
   */
  public previewMarkup(context:string) {
    const base = `${this.apiV3Base}/render/markdown`;

    if (context) {
      return `${base}?context=${context}`;
    } else {
      return base;
    }
  }

  /**
   * Principals autocompleter path
   *
   * Primarily used from ckeditor
   * https://github.com/opf/commonmark-ckeditor-build/
   *
   */
  public principals(projectId:string|number, term:string|null) {
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    // Only real and activated users:
    filters.add('status', '!', ['3']);
    // that are members of that project:
    filters.add('member', '=', [projectId.toString()]);
    // That are users:
    filters.add('type', '=', ['User', 'Group']);
    // That are not the current user:
    filters.add('id', '!', ['me']);

    if (term && term.length > 0) {
      // Containing the that substring:
      filters.add('name', '~', [term]);
    }

    return this.apiV3Base +
      '/principals?' +
      filters.toParams({ sortBy: '[["name","asc"]]', offset: '1', pageSize: '10' });
  }
}

@Injectable({ providedIn: 'root' })
export class PathHelperService {
  public readonly appBasePath = window.appBasePath || '';
  public readonly api = {
    v3: new Apiv3Paths(this.appBasePath)
  };

  public get staticBase() {
    return this.appBasePath;
  }

  public attachmentDownloadPath(attachmentIdentifier:string, slug:string|undefined) {
    const path = `${this.staticBase}/attachments/${attachmentIdentifier}`;

    if (slug) {
      return `${path}/${slug}`;
    } else {
      return path;
    }
  }

  public attachmentContentPath(attachmentIdentifier:number|string) {
    return `${this.staticBase}/attachments/${attachmentIdentifier}/content`;
  }

  public ifcModelsPath(projectIdentifier:string) {
    return `${this.staticBase}/projects/${projectIdentifier}/ifc_models`;
  }

  public bimDetailsPath(projectIdentifier:string, workPackageId:string, viewpoint:number|string|null = null) {
    let path = `${this.projectPath(projectIdentifier)}/bcf/split/details/${workPackageId}`;

    if (viewpoint !== null) {
      path += `?viewpoint=${viewpoint}`;
    }

    return path;
  }

  public highlightingCssPath() {
    return `${this.staticBase}/highlighting/styles`;
  }

  public forumPath(projectIdentifier:string, forumIdentifier:string) {
    return `${this.projectForumPath(projectIdentifier)}/${forumIdentifier}`;
  }

  public keyboardShortcutsHelpPath() {
    return `${this.staticBase}/help/keyboard_shortcuts`;
  }

  public messagePath(messageIdentifier:string) {
    return `${this.staticBase}/topics/${messageIdentifier}`;
  }

  public myPagePath() {
    return `${this.staticBase}/my/page`;
  }

  public newsPath(newsId:string) {
    return `${this.staticBase}/news/${newsId}`;
  }

  public loginPath() {
    return `${this.staticBase}/login`;
  }

  public projectsPath() {
    return `${this.staticBase}/projects`;
  }

  public projectPath(projectIdentifier:string) {
    return `${this.projectsPath()}/${projectIdentifier}`;
  }

  public projectActivityPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/activity`;
  }

  public projectForumPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/forums`;
  }

  public projectCalendarPath(projectId:string) {
    return `${this.projectPath(projectId)}/work_packages/calendar`;
  }

  public projectMembershipsPath(projectId:string) {
    return `${this.projectPath(projectId)}/members`;
  }

  public projectNewsPath(projectId:string) {
    return `${this.projectPath(projectId)}/news`;
  }

  public projectTimeEntriesPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/cost_reports`;
  }

  public projectWikiPath(projectId:string) {
    return `${this.projectPath(projectId)}/wiki`;
  }

  public projectWorkPackagePath(projectId:string, wpId:string|number) {
    return `${this.projectWorkPackagesPath(projectId)}/${wpId}`;
  }

  public projectWorkPackagesPath(projectId:string) {
    return `${this.projectPath(projectId)}/work_packages`;
  }

  public projectWorkPackageNewPath(projectId:string) {
    return `${this.projectWorkPackagesPath(projectId)}/new`;
  }

  public projectBoardsPath(projectIdentifier:string|null) {
    if (projectIdentifier) {
      return `${this.projectPath(projectIdentifier)}/boards`;
    } else {
      return `${this.staticBase}/boards`;
    }
  }

  public projectDashboardsPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/dashboards`;
  }

  public timeEntriesPath(workPackageId:string|number) {
    const suffix = '/time_entries';

    if (workPackageId) {
      return this.workPackagePath(workPackageId) + suffix;
    } else {
      return this.staticBase + suffix; // time entries root path
    }
  }

  public usersPath() {
    return `${this.staticBase}/users`;
  }

  public groupsPath() {
    return `${this.staticBase}/groups`;
  }

  public placeholderUsersPath() {
    return `${this.staticBase}/placeholder_users`;
  }

  public userPath(id:string|number) {
    return `${this.usersPath()}/${id}`;
  }

  public placeholderUserPath(id:string|number) {
    return `${this.placeholderUsersPath()}/${id}`;
  }

  public groupPath(id:string|number) {
    return `${this.groupsPath()}/${id}`;
  }

  public rolesPath() {
    return `${this.staticBase}/roles`;
  }

  public rolePath(id:string|number) {
    return `${this.rolesPath()}/${id}`;
  }

  public versionsPath() {
    return `${this.staticBase}/versions`;
  }

  public versionEditPath(id:string|number) {
    return `${this.staticBase}/versions/${id}/edit`;
  }

  public versionShowPath(id:string|number) {
    return `${this.staticBase}/versions/${id}`;
  }

  public workPackagesPath() {
    return `${this.staticBase}/work_packages`;
  }

  public workPackagePath(id:string|number) {
    return `${this.staticBase}/work_packages/${id}`;
  }

  public workPackageCopyPath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/copy`;
  }

  public workPackageDetailsCopyPath(projectIdentifier:string, workPackageId:string|number) {
    return `${this.projectWorkPackagesPath(projectIdentifier)}/details/${workPackageId}/copy`;
  }

  public workPackagesBulkDeletePath() {
    return `${this.workPackagesPath()}/bulk`;
  }

  public projectLevelListPath() {
    return `${this.projectsPath()}/level_list.json`;
  }

  public textFormattingHelp() {
    return `${this.staticBase}/help/text_formatting`;
  }
}
