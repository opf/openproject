// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {ApiV3FilterBuilder} from '../../api/api-v3/api-v3-filter-builder';

export class PathHelperService {
  public readonly appBasePath:string;

  constructor(public $window:ng.IWindowService) {
    this.appBasePath = $window.appBasePath ? $window.appBasePath : '';
  }

  public get staticBase() {
    return this.appBasePath;
  }

  public get apiV2() {
    return this.appBasePath + '/api/v2';
  }

  public get apiV3() {
    return this.appBasePath + '/api/v3';
  }

  public boardPath(projectIdentifier:string, boardIdentifier:string) {
    return this.projectBoardsPath(projectIdentifier) + '/' + boardIdentifier;
  }

  public keyboardShortcutsHelpPath() {
    return this.staticBase + '/help/keyboard_shortcuts';
  }

  public messagePath(messageIdentifier:string) {
    return this.staticBase + '/topics/' + messageIdentifier;
  }

  public myPagePath() {
    return this.staticBase + '/my/page';
  }

  public projectsPath() {
    return this.staticBase + '/projects';
  }

  public projectPath(projectIdentifier:string) {
    return this.projectsPath() + '/' + projectIdentifier;
  }

  public projectActivityPath(projectIdentifier:string) {
    return this.projectPath(projectIdentifier) + '/activity';
  }

  public projectBoardsPath(projectIdentifier:string) {
    return this.projectPath(projectIdentifier) + '/boards';
  }

  public projectCalendarPath(projectId:string) {
    return this.projectPath(projectId) + '/work_packages/calendar';
  }

  public projectNewsPath(projectId:string) {
    return this.projectPath(projectId) + '/news';
  }

  public projectTimelinesPath(projectId:string) {
    return this.projectPath(projectId) + '/timelines';
  }

  public projectTimeEntriesPath(projectIdentifier:string) {
    return this.projectPath(projectIdentifier) + '/time_entries';
  }

  public projectWikiPath(projectId:string) {
    return this.projectPath(projectId) + '/wiki';
  }

  public projectWorkPackagePath(projectId:string, wpId:string|number) {
    return this.projectWorkPackagesPath(projectId) + '/' + wpId;
  }

  public projectWorkPackagesPath(projectId:string) {
    return this.projectPath(projectId) + '/work_packages';
  }

  public projectWorkPackageNewPath(projectId:string) {
    return this.projectWorkPackagesPath(projectId) + '/new';
  }

  public timeEntriesPath(workPackageId:string|number) {
    var suffix = '/time_entries';

    if (workPackageId) {
      return this.workPackagePath(workPackageId) + suffix;
    } else {
      return this.staticBase + suffix; // time entries root path
    }
  }

  public timeEntryPath(timeEntryIdentifier:string) {
    return this.staticBase + '/time_entries/' + timeEntryIdentifier;
  }

  public timeEntryEditPath(timeEntryIdentifier:string) {
    return this.timeEntryPath(timeEntryIdentifier) + '/edit';
  }

  public usersPath() {
    return this.staticBase + '/users';
  }

  public userPath(id:string|number) {
    return this.usersPath() + '/' + id;
  }

  public versionsPath() {
    return this.staticBase + '/versions';
  }

  public workPackagesPath() {
    return this.staticBase + '/work_packages';
  }

  public workPackagePath(id:string|number) {
    return this.staticBase + '/work_packages/' + id;
  }

  public workPackageCopyPath(workPackageId:string|number) {
    return this.workPackagePath(workPackageId) + '/copy';
  }

  public workPackageDetailsCopyPath(projectIdentifier:string, workPackageId:string|number) {
    return this.projectWorkPackagesPath(projectIdentifier) + '/details/' + workPackageId + '/copy';
  }

  public workPackagesBulkDeletePath() {
    return this.workPackagesPath() + '/bulk';
  }

  public workPackageJsonAutoCompletePath(projectId?:string) {
    var path = this.workPackagesPath() + '/auto_complete.json';
    if (projectId) {
      path += '?project_id=' + projectId;
    }

    return path;
  }

  // API V2
  public apiV2ProjectsPath() {
    return this.apiV2 + '/projects';
  }

  // API V3
  public apiConfigurationPath() {
    return this.apiV3 + '/configuration';
  }

  public apiV3WorkPackagePath(workPackageId:string|number) {
    return this.apiV3 + '/work_packages/' + workPackageId;
  }

  public apiV3ProjectPath(projectIdentifier:string) {
    return this.apiV3 + '/projects/' + projectIdentifier;
  }

  public apiV3ProjectCategoriesPath(projectIdentifier:string) {
    return this.apiV3ProjectPath(projectIdentifier) + '/categories';
  }

  public apiV3UserPath(userId:string|number) {
    return this.apiV3 + '/users/' + userId;
  }

  public apiv3MentionablePrincipalsPath(projectId:string|number, term:string|null) {
    let filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    // Only real and activated users:
    filters.add('status', '!', ['0', '3']);
    // that are members of that project:
    filters.add('member', '=', [projectId.toString()]);
    // That are users:
    filters.add('type', '=', ['User']);
    // That are not the current user:
    filters.add('id', '!', ['me']);

    if (term && term.length > 0) {
      // Containing the that substring:
      filters.add('name', '~', [term]);
    }
    return this.apiV3 + '/principals' + '?' + filters.toParams() + encodeURI('&sortBy=[["name","asc"]]&offset=1&pageSize=10');
  }

  public apiV3UserMePath() {
    return this.apiV3UserPath('me');
  }

  public apiV3StatusesPath() {
    return this.apiV3 + '/statuses';
  }
}

angular
  .module('openproject.helpers')
  .service('PathHelper', PathHelperService);
