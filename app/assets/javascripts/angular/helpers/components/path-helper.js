//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
angular.module('openproject.helpers')

.service('PathHelper', [function() {
  PathHelper = {
    apiV2: '/api/v2',
    apiExperimental: '/api/experimental',
    apiV3: '/api/v3',
    staticBase: window.appBasePath ? window.appBasePath : '',

    activityPath: function(projectIdentifier, from) {
      var link = '/activity';

      if (projectIdentifier) {
        link = PathHelper.projectPath(projectIdentifier) + link;
      }

      if (from) {
        link += '?from=' + from;
      }

      return link;
    },
    assetPath: function(assetIdentifier) {
      return '/assets/' + assetIdentifier;
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
      return '/topics/' + messageIdentifier;
    },
    projectsPath: function() {
      return '/projects';
    },
    projectPath: function(projectIdentifier) {
      return PathHelper.projectsPath() + '/' + projectIdentifier;
    },
    queryPath: function(queryIdentifier) {
      return '/queries/' + queryIdentifier;
    },
    timeEntriesPath: function(projectIdentifier, workPackageIdentifier) {
      var path = '/time_entries/';

      if (workPackageIdentifier) {
        return PathHelper.workPackagePath(workPackageIdentifier) + path;
      } else if (projectIdentifier) {
        return PathHelper.projectPath(projectIdentifier) + path;
      }

      return path;
    },
    timeEntryPath: function(timeEntryIdentifier) {
      return '/time_entries/' + timeEntryIdentifier;
    },
    timeEntryEditPath: function(timeEntryIdentifier) {
      return PathHelper.timeEntryPath(timeEntryIdentifier) + '/edit';
    },
    workPackagesPath: function() {
      return '/work_packages';
    },
    workPackagePath: function(id) {
      return '/work_packages/' + id;
    },
    usersPath: function() {
      return '/users';
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
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.usersPath();
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
      return PathHelper.apiExperimental + PathHelper.usersPath();
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

    // Static
    staticUserPath: function(userId) {
      return PathHelper.staticBase + PathHelper.userPath(userId);
    },
    staticWorkPackagePath: function(workPackageId) {
      return PathHelper.staticBase + PathHelper.workPackagePath(workPackageId);
    },
    staticProjectPath: function(projectId) {
      return PathHelper.staticBase + PathHelper.projectPath(projectId);
    },
    staticVersionPath: function(versionId) {
      return PathHelper.staticBase + PathHelper.versionPath(versionId);
    }
  };

  return PathHelper;
}]);
