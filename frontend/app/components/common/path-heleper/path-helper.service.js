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

angular
  .module('openproject.helpers')
  .factory('PathHelper', PathHelper);

function PathHelper() {
  var PathHelper,
      appBasePath = window.appBasePath ? window.appBasePath : '';

  return PathHelper = {
    staticBase:   appBasePath,

    apiV2: appBasePath + '/api/v2',
    apiV3: appBasePath + '/api/v3',

    activityPath: function() {
      return PathHelper.staticBase + '/activity';
    },
    boardPath: function(projectIdentifier, boardIdentifier) {
      return PathHelper.projectBoardsPath(projectIdentifier) + '/' + boardIdentifier;
    },
    keyboardShortcutsHelpPath: function() {
      return PathHelper.staticBase + '/help/keyboard_shortcuts';
    },
    messagePath: function(messageIdentifier) {
      return PathHelper.staticBase + '/topics/' + messageIdentifier;
    },
    myPagePath: function() {
      return PathHelper.staticBase + '/my/page';
    },
    projectsPath: function() {
      return PathHelper.staticBase + '/projects';
    },
    projectPath: function(projectIdentifier) {
      return PathHelper.projectsPath() + '/' + projectIdentifier;
    },
    projectActivityPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + '/activity';
    },
    projectBoardsPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + '/boards';
    },
    projectCalendarPath: function(projectId) {
      return PathHelper.projectPath(projectId) + '/work_packages/calendar';
    },
    projectNewsPath: function(projectId) {
      return PathHelper.projectPath(projectId) + '/news';
    },
    projectTimelinesPath: function(projectId) {
      return PathHelper.projectPath(projectId) + '/timelines';
    },
    projectTimeEntriesPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + '/time_entries';
    },
    projectWikiPath: function(projectId) {
      return PathHelper.projectPath(projectId) + '/wiki';
    },
    projectWorkPackagesPath: function(projectId) {
      return PathHelper.projectPath(projectId) + '/work_packages';
    },
    projectWorkPackageNewPath: function(projectId) {
      return PathHelper.projectWorkPackagesPath(projectId) + '/new';
    },
    queryPath: function(queryIdentifier) {
      return PathHelper.staticBase + '/queries/' + queryIdentifier;
    },
    timeEntriesPath: function(workPackageId) {
      var suffix = '/time_entries';

      if (workPackageId) {
        return PathHelper.workPackagePath(workPackageId) + suffix;
      } else {
        return PathHelper.staticBase + suffix; // time entries root path
      }
    },
    timeEntryPath: function(timeEntryIdentifier) {
      return PathHelper.staticBase + '/time_entries/' + timeEntryIdentifier;
    },
    timeEntryEditPath: function(timeEntryIdentifier) {
      return PathHelper.timeEntryPath(timeEntryIdentifier) + '/edit';
    },
    usersPath: function() {
      return PathHelper.staticBase + '/users';
    },
    userPath: function(id) {
      return PathHelper.usersPath() + '/' + id;
    },
    versionsPath: function() {
      return PathHelper.staticBase + '/versions';
    },
    versionPath: function(versionId) {
      return PathHelper.versionsPath() + '/' + versionId;
    },
    workPackagesPath: function() {
      return PathHelper.staticBase + '/work_packages';
    },
    workPackagePath: function(id) {
      return PathHelper.staticBase + '/work_packages/' + id;
    },
    workPackageCopyPath: function(workPackageId) {
      return PathHelper.workPackagePath(workPackageId) + '/copy';
    },
    workPackageDetailsCopyPath: function(projectIdentifier, workPackageId) {
      return PathHelper.projectWorkPackagesPath(projectIdentifier) + '/details/' + workPackageId + '/copy';
    },
    workPackagesBulkDeletePath: function() {
      return PathHelper.workPackagesPath() + '/bulk';
    },
    workPackagesBulkEditPath: function(workPackageIds) {
      var query = _.reduce(workPackageIds, function(idsString, id) {
        idsString += 'id[]=' + id + '&';
        return idsString;
      }, '').slice(0, -1);

      return PathHelper.workPackagesBulkDeletePath + '/edit?' + query;
    },
    workPackageJsonAutoCompletePath: function(projectId) {
      var path = PathHelper.workPackagesPath() + '/auto_complete.json';
      if (projectId) {
        path += '?project_id=' + projectId
      }

      return path;
    },

    // API V2
    apiV2ProjectsPath: function() {
      return PathHelper.apiV2 + '/projects';
    },

    // API V3
    apiConfigurationPath: function() {
      return PathHelper.apiV3 + '/configuration';
    },
    apiQueryStarPath: function(queryId) {
      return PathHelper.apiV3QueryPath(queryId) + '/star';
    },
    apiQueryUnstarPath: function(queryId) {
      return PathHelper.apiV3QueryPath(queryId) + '/unstar';
    },
    apiV3QueryPath: function(queryId) {
      return PathHelper.apiV3 + '/queries/' + queryId;
    },
    apiV3WorkPackagePath: function(workPackageId) {
      return PathHelper.apiV3 + '/work_packages/' + workPackageId;
    },
    apiV3WorkPackagesPath: function(workPackageId) {
      return PathHelper.apiV3 + '/work_packages';
    },
    apiV3WorkPackageFormPath: function(projectIdentifier) {
      return PathHelper.apiV3WorkPackagesPath() + '/form';
    },
    apiV3ProjectPath: function(projectIdentifier) {
      return PathHelper.apiV3 + '/projects/' + projectIdentifier;
    },
    apiV3AvailableProjectsPath: function() {
      return PathHelper.apiV3WorkPackagesPath() + '/available_projects';
    },
    apiv3ProjectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/work_packages';
    },
    apiV3ProjectCategoriesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/categories';
    },
    apiV3TypePath: function(typeId) {
      return PathHelper.apiV3 + '/types/' + typeId;
    },
    apiV3UserPath: function(userId) {
      return PathHelper.apiV3 + '/users/' + userId;
    },
    apiStatusesPath: function() {
      return PathHelper.apiV3 + '/statuses';
    },
    apiProjectWorkPackageTypesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/types';
    },
    apiWorkPackageTypesPath: function() {
      return PathHelper.apiV3 + '/types';
    },

  };
}
