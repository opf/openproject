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

import {wpDirectivesModule} from '../../../../angular-modules';
import {WorkPackageRelationsController} from "../../wp-relations.directive";
import {WorkPackageRelationsHierarchyController} from "../../wp-relations-hierarchy/wp-relations-hierarchy.directive";
import {WorkPackageResourceInterface} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {CollectionResource} from '../../../api/api-v3/hal-resources/collection-resource.service';
import {LoadingIndicatorService} from '../../../common/loading-indicator/loading-indicator.service';

function wpRelationsAutocompleteDirective(
  $q:ng.IQService,
  PathHelper:any,
  $http:ng.IHttpService,
  loadingIndicator:LoadingIndicatorService,
  I18n:op.I18n) {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/wp-relations-create/wp-relations-autocomplete/wp-relations-autocomplete.template.html',
    require: ['^wpRelations', '?^wpRelationsHierarchy'],
    scope: {
      selectedWpId: '=',
      loadingPromiseName: '@',
      selectedRelationType: '=',
      filterCandidatesFor: '@',
      workPackage: '='
    },
    link: function (scope:any, element:ng.IAugmentedJQuery, attrs:ng.IAttributes) {
      scope.text = {
        placeholder: I18n.t('js.relations_autocomplete.placeholder')
      };
      scope.options = [];
      scope.relatedWps = [];

      let input = jQuery('.wp-relations--autocomplete')
      let selected = false;

      input.autocomplete({
        delay: 250,
        autoFocus: false, // Accessibility!
        appendTo: '.detail-panel--autocomplete-target',
        source: (request:{ term:string }, response:Function) => {
          autocompleteWorkPackages(request.term).then((values) => {
            selected = false;
            response(values.map(wp => {
              return { workPackage: wp, value: getIdentifier(wp) };
            }));
          });
        },
        select: (evt, ui:any) => {
          scope.$evalAsync(() => {
            selected = true;
            scope.selectedWpId = ui.item.workPackage.id;
          });
        },
        minLength: 0
      }).focus(() => !selected && input.autocomplete('search', input.val()));

      function getIdentifier(workPackage:WorkPackageResourceInterface):string {
        if (workPackage) {
          return `#${workPackage.id} - ${workPackage.subject}`;
        } else {
          return '';
        }
      };

      function autocompleteWorkPackages(query:string):Promise<WorkPackageResourceInterface[]> {
        const deferred = $q.defer();
        loadingIndicator.indicator(scope.loadingPromiseName).promise = deferred.promise;

        scope.workPackage.available_relation_candidates.$link.$fetch({
            query: query,
            type: scope.filterCandidatesFor
          }, {
            'caching': {
              enabled: false
            }
          }).then((collection:CollectionResource) => {
            scope.noResults = collection.count === 0;
            deferred.resolve(collection.elements);
          }).catch(() => deferred.reject());

        return deferred.promise;
      };

      scope.$watch('noResults', (noResults:boolean) => {
        if (noResults) {
          scope.selectedWpId = null;
        }
      });
    }
  };
}

wpDirectivesModule.directive('wpRelationsAutocomplete', wpRelationsAutocompleteDirective);
