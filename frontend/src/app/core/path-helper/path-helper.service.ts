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

import { Injectable } from '@angular/core';
import { ApiV3Paths } from './apiv3-paths';

@Injectable({ providedIn: 'root' })
export class PathHelperService {
  public readonly appBasePath = window.appBasePath || '';

  public readonly api = {
    v3: new ApiV3Paths(this.appBasePath),
  };

  public get staticBase() {
    return this.appBasePath;
  }

  public attachmentDownloadPath(attachmentIdentifier:string, slug:string|undefined) {
    const path = `${this.staticBase}/attachments/${attachmentIdentifier}`;

    if (slug) {
      return `${path}/${slug}`;
    }
    return path;
  }

  public attachmentContentPath(attachmentIdentifier:number|string) {
    return `${this.staticBase}/attachments/${attachmentIdentifier}/content`;
  }

  public fileLinksPath():string {
    return `${this.api.v3.apiV3Base}/file_links`;
  }

  public ifcModelsPath(projectIdentifier:string) {
    return `${this.staticBase}/projects/${projectIdentifier}/ifc_models`;
  }

  public ifcModelsNewPath(projectIdentifier:string) {
    return `${this.ifcModelsPath(projectIdentifier)}/new`;
  }

  public ifcModelsEditPath(projectIdentifier:string, modelId:number|string) {
    return `${this.ifcModelsPath(projectIdentifier)}/${modelId}/edit`;
  }

  public ifcModelsDeletePath(projectIdentifier:string, modelId:number|string) {
    return `${this.ifcModelsPath(projectIdentifier)}/${modelId}`;
  }

  public bimDetailsPath(projectIdentifier:string, workPackageId:string, viewpoint:number|string|null = null) {
    let path = `${this.projectPath(projectIdentifier)}/bcf/details/${workPackageId}`;

    if (viewpoint !== null) {
      path += `?query_props=%7B"t"%3A"id%3Adesc"%2C"dr"%3A"splitCards"%7D&viewpoint=${viewpoint}`;
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

  public meetingPath(id:string):string {
    return `${this.staticBase}/meetings/${id}`;
  }

  public myPagePath() {
    return `${this.staticBase}/my/page`;
  }

  public myNotificationsSettingsPath() {
    return `${this.staticBase}/my/notifications`;
  }

  public newsPath(newsId:string) {
    return `${this.staticBase}/news/${newsId}`;
  }

  public notificationsPath():string {
    return `${this.staticBase}/notifications`;
  }

  public notificationsDetailsPath(workPackageId:string, tab?:string):string {
    return `${this.notificationsPath()}/details/${workPackageId}${tab ? `/${tab}` : ''}`;
  }

  public loginPath() {
    return `${this.staticBase}/login`;
  }

  public projectsPath() {
    return `${this.staticBase}/projects`;
  }

  public projectsNewPath():string {
    return `${this.staticBase}/projects/new`;
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
    return `${this.projectPath(projectId)}/calendar`;
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

  public boardsPath(projectIdentifier:string|null) {
    if (projectIdentifier) {
      return `${this.projectPath(projectIdentifier)}/boards`;
    }
    return `${this.staticBase}/boards`;
  }

  public newBoardsPath(projectIdentifier:string|null) {
    return `${this.boardsPath(projectIdentifier)}/new`;
  }

  public projectDashboardsPath(projectIdentifier:string) {
    return `${this.projectPath(projectIdentifier)}/dashboards`;
  }

  public timeEntriesPath(workPackageId:string|number) {
    const suffix = '/time_entries';

    if (workPackageId) {
      return this.workPackagePath(workPackageId) + suffix;
    }
    return this.staticBase + suffix; // time entries root path
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

  public workPackageShortPath(id:string|number) {
    return `${this.staticBase}/wp/${id}`;
  }

  public workPackageCopyPath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/copy`;
  }

  public workPackageDetailsPath(projectIdentifier:string, workPackageId:string|number, tab?:string) {
    if (tab) {
      return `${this.projectWorkPackagePath(projectIdentifier, workPackageId)}/details/${tab}`;
    }

    return `${this.projectWorkPackagesPath(projectIdentifier)}/details/${workPackageId}`;
  }

  public workPackageDetailsCopyPath(projectIdentifier:string, workPackageId:string|number) {
    return this.workPackageDetailsPath(projectIdentifier, workPackageId, 'copy');
  }

  public workPackageSharePath(workPackageId:string|number) {
    return `${this.workPackagePath(workPackageId)}/shares`;
  }

  public workPackageProgressModalPath(workPackageId:string|number) {
    if (workPackageId === 'new') {
      return `${this.workPackagePath(workPackageId)}/progress/new`;
    }

    return `${this.workPackagePath(workPackageId)}/progress/edit`;
  }

  public workPackageUpdateCounterPath(workPackageId:string|number, counter:string) {
    return `${this.workPackagePath(workPackageId)}/split_view/update_counter?counter=${counter}`;
  }

  // Work Package Bulk paths

  public workPackagesBulkEditPath() {
    return `${this.workPackagesPath()}/bulk/edit`;
  }

  public workPackagesBulkMovePath() {
    return `${this.workPackagesPath()}/move/new`;
  }

  public workPackagesBulkCopyPath() {
    return `${this.workPackagesBulkMovePath()}?copy=true`;
  }

  public workPackagesBulkDeletePath() {
    return `${this.workPackagesPath()}/bulk`;
  }

  public textFormattingHelp() {
    return `${this.staticBase}/help/text_formatting`;
  }

  public jobStatusModalPath(jobId:string) {
    return `${this.staticBase}/job_statuses/${jobId}/dialog`;
  }
}
