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

import {opServicesModule} from '../../angular-modules';

function projectService($http, apiPaths, halRequest) {
  var indentedName = function (name, level) {
    var indentation = '';

    for (var i = 0; i < level; i++) {
      indentation = indentation + '--';
    }

    return indentation + ' ' + name;
  };
  var assignAncestorLevels = function (projects) {
    var ancestors = [];

    angular.forEach(projects, function (project) {
      while (ancestors.length > 0 && project.parent_id !== _.last(ancestors).id) {
        // this helper method only reflects hierarchies if nested projects follow one another
        ancestors.pop();
      }

      project['level'] = ancestors.length;
      project['name'] = indentedName(project['name'], project['level']);

      if (!project['leaf?']) {
        ancestors.push(project);
      }
    });

    return projects;
  };

  var ProjectService = {
    getProject: function (projectIdentifier) {
      const url = apiPaths.ex.project({project: projectIdentifier});

      return $http.get(url).then(function (response) {
        return response.data.project;
      });
    },

    getProjects: function () {
      const url = apiPaths.ex.projects();

      return ProjectService.doQuery(url)
        .then(function (projects) {
          return assignAncestorLevels(projects);
        });
    },

    getSubProjects: function (projectIdentifier) {
      const url = apiPaths.ex.project.subProjects({project: projectIdentifier});
      return ProjectService.doQuery(url);
    },

    getWorkPackageProject: function (workPackage) {
      return ProjectService.doQuery(workPackage.project.$link.href);
    },

    doQuery: function (url, params?) {
      return $http.get(url, {params: params})
        .then(function (response) {
          return response.data.projects;
        });
    },

    fetchProjectResource: function (projectIdentifier) {
      var url = apiPaths.v3.project({project: projectIdentifier});
      return halRequest.get(url);
    }
  };

  return ProjectService;
}

opServicesModule.factory('ProjectService', projectService);
