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

module.exports = function(ProjectService, $state, PathHelper) {

  var WorkPackageAuthorization = function (workPackage) {
    this.workPackage = workPackage;

    if (angular.isDefined(this.workPackage.embedded.project)) {
      this.project = workPackage.embedded.project;
    }
    else {
      this.project = ProjectService.getWorkPackageProject(this.workPackage).then(function(project) {
        return project;
      });
    }

    this.allActions = {
                        workPackage: this.workPackage.links,
                        project: this.project.links
                      };
  };

  WorkPackageAuthorization.prototype = {
    copyLink: function() {
      if ($state.current.name.indexOf('work-packages.show') === 0){
        return PathHelper.workPackageCopyPath(this.workPackage.props.id);
      }
      else if ($state.current.name.indexOf('work-packages.list.details') === 0) {
        return PathHelper.workPackageDetailsCopyPath(this.project.props.identifier,
                                                     this.workPackage.props.id);
      }
    },
    linkForAction: function(action) {
      if (action.key === 'copy') {
        action.link = this.copyLink();
      }
      else {
        action.link = this.allActions[action.resource][action.link].href;
      }

      return action;
    },
    isPermitted: function(action) {
      return this.allActions[action.resource] !== undefined &&
        this.allActions[action.resource][action.link] !== undefined;
    },
    permittedActionKeys: function(allowedActions) {
      var validActions = _.filter(allowedActions, this.isPermitted, this);

      return _.map(validActions, function(action) {
        return action.key;
      });
    },
    permittedActionsWithLinks: function(allowedActions) {
      var validActions = _.filter(_.cloneDeep(allowedActions), this.isPermitted, this);

      var allowed = _.map(validActions, this.linkForAction, this);

      return allowed;
    }
  };

  return WorkPackageAuthorization;
};
