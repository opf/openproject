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

module.exports = function(
    CommonRelationsHandler,
    WorkPackageService,
    ApiNotificationsService,
    PathHelper) {
  function ParentRelationsHandler(workPackage, parents, relationsId) {
    function params(lockVersion, id) {
      var parentPath = null;

      if (id) {
        parentPath = PathHelper.apiV3WorkPackagePath(id);
      }

      return {
        lockVersion: lockVersion,
        _links: {
          parent: {
            href: parentPath
          }
        }
      };
    }

      var relations = parents.filter(function(parent) {
            return parent.props.id !== workPackage.props.id;
          }),
          handler = new CommonRelationsHandler(workPackage, relations, relationsId);

      handler.type = 'parent';
      handler.addRelation = undefined;
      handler.isSingletonRelation = true;
      handler.relationsId = relationsId;

      handler.canAddRelation = function() { return !!this.workPackage.links.changeParent; };
      handler.canDeleteRelation = function() { return !!this.workPackage.links.changeParent; };
      handler.getRelatedWorkPackage = function(workPackage, relation) { return relation.fetch(); };
      handler.addRelation = function(scope) {
        var payload = params(scope.workPackage.props.lockVersion,
                             scope.relationToAddId);

        WorkPackageService.updateWithPayload(this.workPackage, payload).then(function() {
            scope.relationToAddId = '';
            scope.updateFocus(-1);
            scope.$emit('workPackageRefreshRequired');
        }, function(error) {
            ApiNotificationsService.addError(error);
        });
      };
      handler.removeRelation = function(scope) {
          var index = this.relations.indexOf(scope.relation);
          var handler = this;
          var payload = params(scope.workPackage.props.lockVersion);

          WorkPackageService.updateWithPayload(scope.workPackage, payload).then(function(response){
              handler.relations.splice(index, 1);
              scope.workPackage.props.lockVersion = response.props.lockVersion;
              scope.updateFocus(index);
              scope.$emit('workPackageRefreshRequired');
          }, function(error) {
              ApiNotificationsService.addError(error);
          });
      };

      return handler;
  }

  return ParentRelationsHandler;
};
