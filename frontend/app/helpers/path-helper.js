//-- copyright
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
//++

// TODO forward rails routes
module.exports = function() {
  var PathHelper = {
    apiV2: '/api/v2',
    apiExperimental: '/api/experimental',
    apiV3: '/api/v3',

    appBasePath:  window.appBasePath ? window.appBasePath : '',
    staticBase:   appBasePath,

    activityFromPath: function(projectIdentifier, from) {
      var link = '/activity';

      if (projectIdentifier) {
        link = PathHelper.staticBase + PathHelper.projectPath(projectIdentifier) + link;
      }

      if (from) {
        link += '?from=' + from;
      }

      return link;
    },
    boardsPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + '/boards';
    },
    boardPath: function(projectIdentifier, boardIdentifier) {
      return PathHelper.boardsPath(projectIdentifier) + '/' + boardIdentifier;
    },
    messagesPath: function(boardIdentifier) {
      return PathHelper.boardsPath() + '/' + boardIdentifier + '/topics';
    },
    messagePath: function(messageIdentifier) {
      return PathHelper.staticBase + '/topics/' + messageIdentifier;
    },
    projectsPath: function() {
      return '/projects';
    },
    projectPath: function(projectIdentifier) {
      return PathHelper.projectsPath() + '/' + projectIdentifier;
    },
    projectWorkPackagesPath: function(projectId) {
      return PathHelper.projectPath(projectId) + PathHelper.workPackagesPath();
    },
    queryPath: function(queryIdentifier) {
      return '/queries/' + queryIdentifier;
    },
    timeEntriesPath: function(projectIdentifier, workPackageIdentifier) {
      var path = '/time_entries';

      if (workPackageIdentifier) {
        return PathHelper.workPackagePath(workPackageIdentifier) + path;
      } else if (projectIdentifier) {
        return PathHelper.projectPath(projectIdentifier) + path;
      }

      return path;
    },
    timeEntryPath: function(timeEntryIdentifier) {
      return PathHelper.staticBase + '/time_entries/' + timeEntryIdentifier;
    },
    timeEntryNewPath: function(workPackageId) {
      return PathHelper.timeEntriesPath(null, workPackageId) + '/new';
    },
    timeEntryEditPath: function(timeEntryIdentifier) {
      return PathHelper.timeEntryPath(timeEntryIdentifier) + '/edit';
    },
    workPackagesPath: function() {
      return '/work_packages';
    },
    workPackagePath: function(id) {
      return PathHelper.staticBase + '/work_packages/' + id;
    },
    workPackageDuplicatePath: function(projectId, workPackageId) {
      return '/projects/' + projectId + '/work_packages/new?copy_from=' + workPackageId;
    },
    workPackageMovePath: function(id) {
      return PathHelper.workPackagePath(id) + '/move/new';
    },
    workPackageDeletePath: function(ids) {
      return PathHelper.workPackagesBulkDeletePath() + '?ids=' + (Array.isArray(ids) ? ids.join() : ids);
    },
    usersPath: function() {
      return PathHelper.staticBase + '/users';
    },
    userPath: function(id) {
      return PathHelper.usersPath() + '/' + id;
    },
    versionsPath: function() {
      return '/versions';
    },
    versionPath: function(versionId) {
      return PathHelper.versionsPath() + '/' + versionId;
    },
    subProjectsPath: function() {
      return '/sub_projects';
    },
    workPackagesBulkDeletePath: function() {
      return PathHelper.workPackagesPath() + '/bulk';
    },
    workPackageAutoCompletePath: function(projectId, workPackageId) {
      return '/work_packages/auto_complete?escape=false&id=' + workPackageId + '&project_id=' + projectId;
    },
    workPackageJsonAutoCompletePath: function() {
      return '/work_packages/auto_complete.json';
    },
    workPackageNewWithParameterPath: function(projectId, parameters) {
      var path = "/projects/" + projectId + '/work_packages/new?';

      for (var parameter in parameters) {
        path += 'work_package[' + parameter + ']=' + parameters[parameter] + ';';
      }

      return path;
    },

    // Experimental API
    apiAvailableColumnsPath: function() {
      return PathHelper.apiQueriesPath() + '/available_columns';
    },
    apiCustomFieldsPath: function() {
      return PathHelper.apiQueriesPath() + '/custom_field_filters';
    },
    apiGroupedQueriesPath: function() {
      return PathHelper.apiQueriesPath() + '/grouped';
    },
    apiGroupsPath: function() {
      return PathHelper.apiExperimental + '/groups';
    },
    apiProjectAvailableColumnsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/queries/available_columns';
    },
    apiProjectCustomFieldsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/queries/custom_field_filters';
    },
    apiProjectGroupedQueriesPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/queries/grouped';
    },
    apiProjectPath: function(projectIdentifier) {
      return PathHelper.apiExperimental + PathHelper.projectPath(projectIdentifier);
    },
    apiProjectQueriesPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/queries';
    },
    apiProjectQueryPath: function(projectIdentifier, queryIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.queryPath(queryIdentifier);
    },
    apiProjectsPath: function(){
      return PathHelper.apiExperimental + PathHelper.projectsPath();
    },
    apiProjectSubProjectsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.subProjectsPath();
    },
    apiProjectUsersPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/users';
    },
    apiVersionsPath: function(projectIdentifier) {
      return PathHelper.apiExperimental + PathHelper.versionsPath();
    },
    apiProjectVersionsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.versionsPath();
    },
    apiProjectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.workPackagesPath();
    },
    apiProjectWorkPackagesSumsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.workPackagesPath() + '/column_sums';
    },
    apiQueriesPath: function() {
      return PathHelper.apiExperimental + '/queries';
    },
    apiQueryPath: function(query_id) {
      return PathHelper.apiQueriesPath() + '/' + query_id;
    },
    apiRolesPath: function() {
      return PathHelper.apiExperimental + '/roles';
    },
    apiUsersPath: function() {
      // experimantal, TODO: Migrate to V3
      return PathHelper.apiExperimental + '/users';
    },
    apiWorkPackagesColumnDataPath: function() {
      return PathHelper.apiWorkPackagesPath() + '/column_data';
    },
    apiWorkPackagesPath: function() {
      return PathHelper.apiExperimental + '/work_packages';
    },
    apiWorkPackagesSumsPath: function() {
      return PathHelper.apiWorkPackagesPath() + '/column_sums';
    },

    // API V2
    apiPrioritiesPath: function() {
      return PathHelper.apiV2 + '/planning_element_priorities';
    },
    apiProjectStatusesPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + '/statuses';
    },
    apiProjectWorkPackageTypesPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + '/planning_element_types';
    },
    apiStatusesPath: function() {
      return PathHelper.apiV2 + '/statuses';
    },
    apiV2ProjectPath: function(projectIdentifier) {
      return PathHelper.apiV2 + PathHelper.projectPath(projectIdentifier);
    },
    apiWorkPackageTypesPath: function() {
      return PathHelper.apiV2 + '/planning_element_types';
    },

    // API V3
    apiQueryStarPath: function(queryId) {
      return PathHelper.apiV3QueryPath(queryId) + '/star';
    },
    apiQueryUnstarPath: function(queryId) {
      return PathHelper.apiV3QueryPath(queryId) + '/unstar';
    },
    apiV3QueryPath: function(queryId) {
      return PathHelper.apiV3 + PathHelper.queryPath(queryId);
    },
    apiV3WorkPackagePath: function(workPackageId) {
      return PathHelper.apiV3 + '/work_packages/' + workPackageId;
    },
    apiV3ProjectsPath: function(projectIdentifier) {
      return PathHelper.apiV3 + PathHelper.projectsPath() + '/' + projectIdentifier;
    },
    apiV3ProjectCategoriesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectsPath(projectIdentifier) + '/categories';
    },
    // Static
    staticUserPath: function(userId) {
      return PathHelper.userPath(userId);
    },
    staticWorkPackagePath: function(workPackageId) {
      return PathHelper.workPackagePath(workPackageId);
    },
    staticEditWorkPackagePath: function(workPackageId){
      return PathHelper.staticWorkPackagePath(workPackageId) + '/edit';
    },
    staticProjectPath: function(projectIdentifier) {
      return PathHelper.staticBase + PathHelper.projectPath(projectIdentifier);
    },
    staticVersionPath: function(versionId) {
      return PathHelper.staticBase + PathHelper.versionPath(versionId);
    },
    staticProjectWorkPackagesPath: function(projectId) {
      return PathHelper.staticBase + PathHelper.projectWorkPackagesPath(projectId);
    },
    staticWorkPackagesPath: function() {
      return PathHelper.staticBase + PathHelper.workPackagesPath();
    },
    staticWorkPackageNewWithParametersPath: function(projectId, parameters) {
      return PathHelper.staticBase + PathHelper.workPackageNewWithParameterPath(projectId, parameters);
    },
    staticWorkPackagesAutocompletePath: function(projectId) {
      return PathHelper.staticBase + '/work_packages/auto_complete.json?project_id=' + projectId;
    },
    staticWorkPackageAutoCompletePath: function(projectId, workPackageId) {
      return PathHelper.staticBase
        + PathHelper.workPackageAutoCompletePath(projectId, workPackageId);
    },
    staticProjectWikiPath: function(projectId) {
      return PathHelper.staticProjectPath(projectId) + '/wiki';
    },
    staticProjectCalendarPath: function(projectId) {
      return PathHelper.staticProjectPath(projectId) + '/calendar';
    },
    staticProjectNewsPath: function(projectId) {
      return PathHelper.staticProjectPath(projectId) + '/news';
    },
    staticProjectTimelinesPath: function(projectId) {
      return PathHelper.staticProjectPath(projectId) + '/timelines';
    },
    staticMyPagePath: function() {
      return PathHelper.staticBase + '/my/page';
    },
    staticKeyboardShortcutsHelpPath: function() {
      return PathHelper.staticBase + '/help/keyboard_shortcuts';
    }
  };

  return PathHelper;
};
