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

module.exports = function($timeout, WorkPackageService, ApiHelper, MAX_AUTOCOMPLETER_ADDITION_ITERATIONS) {
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

    canDeleteRelation: function(relation) {
      return !!relation.links.remove;
    },

    addRelation: function(scope) {
      WorkPackageService.addWorkPackageRelation(this.workPackage, scope.relationToAddId, this.relationsId).then(function(relation) {
          scope.relationToAddId = '';
          scope.updateFocus(-1);
          scope.$emit('workPackageRefreshRequired', '');
      }, function(error) {
        ApiHelper.handleError(scope, error);
      });
    },

    removeRelation: function(scope) {
      var index = this.relations.indexOf(scope.relation);
      var handler = this;

      WorkPackageService.removeWorkPackageRelation(scope.relation).then(function(response){
          handler.relations.splice(index, 1);
          scope.updateFocus(index);
        }, function(error) {
          ApiHelper.handleError(scope, error);
        });
    },

    applyCustomExtensions: function() {
      if(this.canAddRelation) {
        var workPackage = this.workPackage;
        var relationsId = this.relationsId;
        var handler = this;

        $timeout(function() { handler.addAutocompleter(MAX_AUTOCOMPLETER_ADDITION_ITERATIONS, workPackage, relationsId); });
      }
    },

    addAutocompleter: function(retries, workPackage, relationsId) {
      if (angular.element('#relation_to_id-' + relationsId).size() === 1) {
        // Massive hack alert - Using old prototype autocomplete ///////////
        var url = PathHelper.workPackageAutoCompletePath(workPackage.props.projectId, workPackage.props.id);
        new Ajax.Autocompleter('relation_to_id-' + relationsId,
                               'related_issue_candidates-' + relationsId,
                               url,
                               { minChars: 1,
                                 frequency: 0.5,
                                 paramName: 'q',
                                 updateElement: function(value) {
                                   // Have to use the duplicate assignment here to update the field
                                   // * to the user
                                   // * to the angular scope
                                   // Doing just one will not suffice.
                                   angular.element('#relation_to_id-' + relationsId).val(value.id)
                                                                                    .scope().relationToAddId = value.id;
                                 },
                                 parameters: 'scope=all'
                                 });
          ////////////////////////////////////////////////////////////////////
      } else if (retries > 0) {
        var handler = this;

        $timeout(function() { handler.addAutocompleter(--retries, workPackage, relationsId); });
      }
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
};
