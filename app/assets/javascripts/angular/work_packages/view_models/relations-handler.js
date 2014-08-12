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

angular.module('openproject.viewModels')

.factory('CommonRelationsHandler', [
    '$timeout',
    'WorkPackageService',
    'ApiHelper',
    function($timeout, WorkPackageService, ApiHelper) {
  function CommonRelationsHandler(workPackage,
                                  relations,
                                  relationsId) {
    this.workPackage = workPackage;
    this.relations = relations;
    this.relationsId = relationsId;

    this.type = "relation";
    this.isSingletonRelation = false;
  }

  CommonRelationsHandler.prototype = {
    isEmpty: function() {
      return !this.relations || this.relations.length === 0;
    },

    getCount: function() {
      return (this.relations) ? this.relations.length : 0;
    },

    canAddRelation: function() {
      return !!this.workPackage.links.addRelation;
    },

    addRelation: function(scope) {
      var inputElement = angular.element('#relation_to_id-' + this.relationsId);
      var toId = inputElement.val();
      WorkPackageService.addWorkPackageRelation(this.workPackage, toId, this.relationsId).then(function(relation) {
          inputElement.val('');
          scope.$emit('workPackageRefreshRequired', '');
      }, function(error) {
        ApiHelper.handleError(scope, error);
      });
    },

    applyCustomExtensions: function() {
      // Massive hack alert - Using old prototype autocomplete ///////////
      if(this.canAddRelation) {
        var workPackage = this.workPackage;
        var relationsId = this.relationsId;

        $timeout(function() {
          var url = PathHelper.workPackageAutoCompletePath(workPackage.props.projectId, workPackage.props.id);
          new Ajax.Autocompleter('relation_to_id-' + relationsId,
                                 'related_issue_candidates-' + relationsId,
                                 url,
                                 { minChars: 1,
                                   frequency: 0.5,
                                   paramName: 'q',
                                   updateElement: function(value) {
                                     document.getElementById('relation_to_id-' + relationsId).value = value.id;
                                   },
                                   parameters: 'scope=all'
                                   });
        });
      }
      ////////////////////////////////////////////////////////////////////
    },

    getRelatedWorkPackage: function(workPackage, relation) {
      var self = workPackage.links.self.href;

      if (relation.links.relatedTo.href == self) {
        return relation.links.relatedFrom.fetch();
      } else {
        return relation.links.relatedTo.fetch();
      }
    }
  };

  return CommonRelationsHandler;
}])

.factory('ChildrenRelationsHandler', ['PathHelper',
                                      'CommonRelationsHandler',
                                      function(PathHelper,
                                               CommonRelationsHandler) {
  function ChildrenRelationsHandler(workPackage, children) {
    var handler = new CommonRelationsHandler(workPackage, children, undefined);

    handler.type = "child";
    handler.canAddRelation = function() { return true };
    handler.addRelation = function() {
      window.location = PathHelper.staticWorkPackageNewWithParentPath(this.workPackage.props.projectId, this.workPackage.props.id);
    };
    handler.applyCustomExtensions = undefined;
    handler.getRelatedWorkPackage = function(workPackage, relation) { return relation.fetch() };

    return handler;
  }

  return ChildrenRelationsHandler;
}])

.factory('ParentRelationsHandler', ['CommonRelationsHandler', 'WorkPackageService', function(CommonRelationsHandler, WorkPackageService) {
    function ParentRelationsHandler(workPackage, parents, relationsId) {
        var handler = new CommonRelationsHandler(workPackage, parents, relationsId);

        handler.type = "parent";
        handler.addRelation = undefined;
        handler.isSingletonRelation = true;
        handler.relationsId = relationsId;

        handler.canAddRelation = function() { return false };
        handler.getRelatedWorkPackage = function(workPackage, relation) { return relation.fetch() };
        handler.canChangeParent = function() { return true };
        handler.changeParent = function(scope) {
            var inputElement = angular.element('#relation_to_id-' + this.relationsId);
            var parentId = inputElement.val();
            WorkPackageService.updateWorkPackage(this.workPackage, {parentId: parentId}).then(function(workPackage) {
                inputElement.val('');
                scope.$emit('workPackageRefreshRequired', '');
            }, function(error) {
                ApiHelper.handleError(scope, error);
            });
        };

        return handler;
    }
    return ParentRelationsHandler;
}])
