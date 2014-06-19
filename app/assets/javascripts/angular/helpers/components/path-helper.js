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
    apiPrefixV2: '/api/v2',
    apiPrefixV3Experimental: '/api/experimental',
    apiPrefixV3Real: '/api/v3',

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

    apiV2ProjectPath: function(projectIdentifier) {
      return PathHelper.apiPrefixV2 + PathHelper.projectPath(projectIdentifier);
    },
    apiV3ProjectsPath: function(){
      return PathHelper.apiPrefixV3Experimental + PathHelper.projectsPath();
    },
    apiV3ProjectPath: function(projectIdentifier) {
      return PathHelper.apiPrefixV3Experimental + PathHelper.projectPath(projectIdentifier);
    },
    apiV3QueryPath: function(queryId) {
      return PathHelper.apiPrefixV3Real + PathHelper.queryPath(queryId);
    },
    apiWorkPackagesPath: function() {
      return PathHelper.apiPrefixV3Experimental + '/work_packages';
    },
    apiProjectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.workPackagesPath();
    },
    apiProjectSubProjectsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.subProjectsPath();
    },
    apiProjectQueriesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/queries';
    },
    apiProjectQueryPath: function(projectIdentifier, queryIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.queryPath(queryIdentifier);
    },
    apiGroupedQueriesPath: function() {
      return PathHelper.apiPrefixV3Experimental + '/queries/grouped';
    },
    apiAvailableColumnsPath: function() {
      return PathHelper.apiPrefixV3Experimental + '/queries/available_columns';
    },
    apiCustomFieldsPath: function() {
      return PathHelper.apiPrefixV3Experimental + '/queries/custom_field_filters';
    },
    apiProjectCustomFieldsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/queries/custom_field_filters';
    },
    apiProjectAvailableColumnsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/queries/available_columns';
    },
    apiProjectGroupedQueriesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/queries/grouped';
    },
    apiQueryStarPath: function(queryId) {
      return PathHelper.apiV3QueryPath(queryId) + '/star';
    },
    apiQueryUnstarPath: function(queryId) {
      return PathHelper.apiV3QueryPath(queryId) + '/unstar';
    },
    apiWorkPackagesColumnDataPath: function() {
      return PathHelper.apiWorkPackagesPath() + '/column_data';
    },
    apiPrioritiesPath: function() {
      return PathHelper.apiPrefixV2 + '/planning_element_priorities';
    },
    apiStatusesPath: function() {
      return PathHelper.apiPrefixV2 + '/statuses';
    },
    apiProjectStatusesPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + '/statuses';
    },
    apiGroupsPath: function() {
      return PathHelper.apiPrefixV3Experimental + '/groups';
    },
    apiRolesPath: function() {
      return PathHelper.apiPrefixV3Experimental + '/roles';
    },
    apiWorkPackageTypesPath: function() {
      return PathHelper.apiPrefixV2 + '/planning_element_types';
    },
    apiProjectWorkPackageTypesPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + '/planning_element_types';
    },
    apiUsersPath: function() {
      return PathHelper.apiPrefixV3Experimental + PathHelper.usersPath();
    },
    apiProjectVersionsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.versionsPath();
    },
    apiProjectUsersPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.usersPath();
    },
    apiProjectWorkPackagesSumsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.workPackagesPath() + '/column_sums';
    },
    apiWorkPackagesSumsPath: function() {
      return PathHelper.apiWorkPackagesPath() + '/column_sums';
    }
  };

  return PathHelper;
}]);
