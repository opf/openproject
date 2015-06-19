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

module.exports = function(PathHelper, CommonRelationsHandler, WorkPackageService) {
  function ChildrenRelationsHandler(workPackage, children) {
      var handler = new CommonRelationsHandler(workPackage, children, undefined);

      handler.type = "child";
      handler.applyCustomExtensions = undefined;

      handler.canAddRelation = function() { return !!this.workPackage.links.addChild; };
      handler.canDeleteRelation = function() {
        return !!this.workPackage.links.update;
      };
      handler.addRelation = function() {
        window.location = this.workPackage.links.addChild.href;
      };
      handler.getRelatedWorkPackage = function(workPackage, relation) { return relation.fetch(); };
      handler.removeRelation = function(scope) {
          var index = this.relations.indexOf(scope.relation);
          var handler = this;
          var params = {
            lockVersion: scope.relation.props.lockVersion,
            parentId: null
          };

          WorkPackageService.updateWithPayload(scope.relation, params).then(function(response){
              handler.relations.splice(index, 1);
              scope.workPackage.props.lockVersion = response.props.lockVersion;
              scope.updateFocus(index);
              scope.$emit('workPackageRefreshRequired');
          }, function(error) {
              ApiHelper.handleError(scope, error);
          });
      };

      return handler;
  }

  return ChildrenRelationsHandler;
};
