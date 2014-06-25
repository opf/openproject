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

// TODO move to UI components
angular.module('openproject.uiComponents')

.constant('LABEL_MAX_CHARS', 40)
.constant('KEY_CODES', {
  enter: 13,
  up: 38,
  down: 40
})
.directive('selectableTitle', ['$sce', 'LABEL_MAX_CHARS', 'KEY_CODES', function($sce, LABEL_MAX_CHARS, KEY_CODES) {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      selectedTitle: '=',
      groups: '=',
      transitionMethod: '='
    },
    templateUrl: '/templates/components/selectable_title.html',
    link: function(scope) {
      scope.$watch('groups', refreshFilteredGroups);
      scope.$watch('selectedId', selectTitle);

      function refreshFilteredGroups() {
        if(scope.groups){
          initFilteredModels();
        }
      }

      function selectTitle() {
        angular.forEach(scope.filteredGroups, function(group) {
          if(group.models.length) {
            angular.forEach(group.models, function(model){
              model.highlighted = model.id == scope.selectedId;
            });
          }
        });        
      }

      function initFilteredModels() {
        scope.filteredGroups = angular.copy(scope.groups);
        angular.forEach(scope.filteredGroups, function(group) {
          group.models = group.models.map(function(model){
            return {
              label: model[0],
              labelHtml: $sce.trustAsHtml(truncate(model[0], LABEL_MAX_CHARS)),
              id: model[1],
              highlighted: false
            }
          });
        });
      }

      function labelHtml(label, filterBy) {
        filterBy = filterBy.toLowerCase();
        label = truncate(label, LABEL_MAX_CHARS);
        if(label.toLowerCase().indexOf(filterBy) >= 0) {
          var labelHtml = label.substr(0, label.toLowerCase().indexOf(filterBy))
            + "<span class='filter-selection'>" + label.substr(label.toLowerCase().indexOf(filterBy), filterBy.length) + "</span>"
            + label.substr(label.toLowerCase().indexOf(filterBy) + filterBy.length);
        } else {
          var labelHtml = label;
        }
        return $sce.trustAsHtml(labelHtml);
      }

      function truncate(text, chars) {
        if (text.length > chars) {
          return text.substr(0, chars) + "...";
        }
        return text;
      }

      function performSelect() {
        scope.transitionMethod(scope.selectedId);

        event.preventDefault();
        event.stopPropagation();
      }

      function selectNext() {
        if(!scope.selectedId && scope.filteredGroups.length && scope.filteredGroups[0].models.length) {
          scope.selectedId = scope.filteredGroups[0].models[0].id;
        } else {
          for(var i = 0; i < scope.filteredGroups.length; i++) {
            var models = scope.filteredGroups[i].models;
            var index = models.map(function(model){
              return model.id;
            }).indexOf(scope.selectedId)

            if(index >= 0) {
              if(index == models.length - 1 && i < scope.filteredGroups.length - 1){
                while(i < scope.filteredGroups.length - 1) {
                  if(scope.filteredGroups[i + 1].models[0] ) {
                    scope.selectedId = scope.filteredGroups[i + 1].models[0].id;
                  }
                  i = i + 1;
                }
                break;
              }
              if(index < models.length - 1){
                scope.selectedId = models[index + 1].id;
                break;
              }
            }
          }
        }

        event.preventDefault();
        event.stopPropagation();
      }

      function selectPrevious() {
        if(scope.selectedId) {
          for(var i = 0; i < scope.filteredGroups.length; i++) {
            var models = scope.filteredGroups[i].models;
            var index = models.map(function(model){
              return model.id;
            }).indexOf(scope.selectedId)

            if(index >= 0) {
              // Bug: Needs to look through all the previous groups for one which has a model
              if(index == 0 && i != 0){
                while(i > 0) {
                  if(scope.filteredGroups[i - 1].models.length) {
                    scope.selectedId = scope.filteredGroups[i - 1].models[scope.filteredGroups[i - 1].models.length - 1].id;
                  }
                  i = i - 1;
                }
                break;
              }
              if(index > 0){
                scope.selectedId = models[index - 1].id;
                break;
              }
            }
          }
        }

        event.preventDefault();
        event.stopPropagation();
      }

      angular.element('#title-filter').bind('click', function(event) {
        event.preventDefault();
        event.stopPropagation();
      });
      
      scope.handleSelection = function(event) {
        switch(event.which) {
          case KEY_CODES.enter:
            performSelect();
            break;
          case KEY_CODES.down:
            selectNext();
            break;
          case KEY_CODES.up:
            selectPrevious();
            break;
          default:
            break;
        }
      };

      scope.reload = function(modelId, newTitle) {
        scope.selectedTitle = newTitle;
        scope.reloadMethod(modelId);
        scope.$emit('hideAllDropdowns');
      };

      scope.filterModels = function(filterBy) {
        initFilteredModels();

        scope.selectedId = 0;
        angular.forEach(scope.filteredGroups, function(group) {
          if(filterBy.length) {
            group.filterBy = filterBy;
            group.models = group.models.filter(function(model){
              return model.label.toLowerCase().indexOf(filterBy.toLowerCase()) >= 0;
            });

            if(group.models.length) {
              angular.forEach(group.models, function(model){
                model['labelHtml'] = labelHtml(model.label, filterBy);
              });
              if(!scope.selectedId) {
                group.models[0].highlighted = true;
                scope.selectedId = group.models[0].id;
              }
            }
          }
        });
      };
    }
  };
}]);
