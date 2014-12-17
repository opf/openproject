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

module.exports = function($sce, $http, $timeout, AutoCompleteHelper, TextileService) {

  function enableAutoCompletion(element) {
    var textarea = element.find('.ined-input-wrapper input, .ined-input-wrapper textarea');
    AutoCompleteHelper.enableTextareaAutoCompletion(textarea);
  }

  function disablePreview($scope) {
    $scope.isPreview = false;
  }

  function getAttribute($scope) {
    if ($scope.embedded) {
      return $scope.attribute.split('.')[0];
    } else {
      return $scope.attribute;
    }
  }

  function getReadAttributeValue($scope) {
    return getAttributeValue($scope, $scope.entity, true);
  }

  function getWriteAttributeValue($scope) {
    return getAttributeValue($scope, $scope.entity.form.embedded.payload, false);
  }

  function getAttributeValue($scope, entity, isReadValue) {
    if ($scope.embedded) {
      var path = $scope.attribute.split('.');

      return entity.embedded[path[0]].props[path[1]];
    } else {
      var attribute = entity.props[getAttribute($scope)];

      if (isAttributeFormattable(attribute)) {
        return isReadValue ? $sce.trustAsHtml(attribute.html) : attribute.raw;
      } else {
        return attribute;
      }
    }
  }

  function isAttributeFormattable(attribute) {
    return _.intersection(_.keys(attribute), ['format', 'raw', 'html']).length === 3;
  }

  function setEmbeddedOptions($scope) {
    $scope.options = [];
    var options = $scope
      .entity.form.embedded.schema
      .props[getAttribute($scope)]._links.allowedValues;
    if (options.length) {
      $scope.options = options;
    } else {
      $scope.isEditable = false;
    }
  }

  function setLinkedOptions($scope) {
    $scope.options = [];
    var href = $scope
      .entity.form.embedded.schema
      .props[getAttribute($scope)]._links.allowedValues.href;
    $scope.isBusy = true;
    $http.get(href).then(function(r) {
      var arrayWithEmptyOption = [{href: null}];
      var linkedOptions = _.map(r.data._embedded.elements, function(item) {
          return angular.extend({}, item._links.self, { name: item.name });
      });
      $scope.options = arrayWithEmptyOption.concat(linkedOptions);
      $scope.isBusy = false;
      $scope.$broadcast('focusSelect2');
    });
  }

  var hooks = {
    _fallback: {
      submit: function($scope, data) {
        if (isAttributeFormattable(data[getAttribute($scope)])) {
          data[getAttribute($scope)].raw = $scope.dataObject.value;
        } else {
          data[getAttribute($scope)] = $scope.dataObject.value;
        }
      },
      setWriteValue: function($scope) {
        $scope.dataObject = {
          value: getWriteAttributeValue($scope)
        };
      },
      setReadValue: function($scope) {
        $scope.readValue = getReadAttributeValue($scope);
      }
    },

    text: {
      link: function(scope, element) {
        enableAutoCompletion(element);
      }
    },

    'wiki_textarea': {
      link: function(scope, element) {
        enableAutoCompletion(element);
        var textarea = element.find('.ined-input-wrapper textarea'),
            lines = textarea.val().split('\n');
        textarea.attr('rows', lines.length + 1);
      },
      startEditing: disablePreview,
      activate: function($scope) {
        disablePreview($scope);
        $scope.togglePreview = function() {
          $scope.isPreview = !$scope.isPreview;
          $scope.error = null;
          if (!$scope.isPreview) {
            return;
          }
          $scope.isBusy = true;
          TextileService
            .renderWithWorkPackageContext($scope.entity.props.id, $scope.dataObject.value)
            .then(function(r) {
              $scope.onFinally();
              $scope.previewHtml = $sce.trustAsHtml(r.data);
          }, function(e) {
            $scope.onFinally();
            $scope.onFail(e);
          });
        };
      },
      onFail: disablePreview
    },

    select: {
      activate: setEmbeddedOptions,
      startEditing: setEmbeddedOptions,
      submit: function($scope, data) {
        data._links = { };
        data._links[getAttribute($scope)] = { href: $scope.dataObject.value };
      },
      setWriteValue: function($scope) {
        $scope.dataObject = {
          value: $scope.entity.form.embedded.payload.links[getAttribute($scope)].href
        };
      }
    },
    select2: {
      link: function(scope, element) {
      scope.$on('focusSelect2', function() {
        $timeout(function() {
          element.find('.select2-choice').trigger('click');
        });
      });
      },
      startEditing: setLinkedOptions,
      submit: function($scope, data) {
        data._links = { };
        data._links[getAttribute($scope)] = { href: $scope.dataObject.value || null };
      },
      setReadValue: function($scope) {
        if ($scope.entity.embedded[$scope.attribute]) {
          $scope.isUserLink = true;
          $scope.readValue = $scope.entity.embedded[$scope.attribute];
        } else {
          $scope.isUserLink = false;
          $scope.readValue = '';
        }
      },
      setWriteValue: function($scope) {
        $scope.dataObject = {
          value: $scope.entity.form.embedded.payload.links[getAttribute($scope)].href
        };
      }
    }
  };


  this.dispatchHook = function($scope, action, data) {
    var actionFunction = hooks[$scope.type][action] || hooks._fallback[action] || angular.noop;
    return actionFunction($scope, data);
  };
};
