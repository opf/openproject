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

module.exports = function($sce, AutoCompleteHelper, TextileService) {

  function enableAutoCompletion(element) {
    var textarea = element.find('.ined-input-wrapper input, .ined-input-wrapper textarea');
    AutoCompleteHelper.enableTextareaAutoCompletion(textarea);
  }

  function disablePreview($scope) {
    $scope.isPreview = false;
  }

  function setOptions($scope) {
    $scope.options = $scope
      .entity.form.embedded.schema
      .props[$scope.attribute]._links.allowedValues;
    if (!$scope.options.length) {
      $scope.isEditable = false;
    }
  }

  var hooks = {
    _fallback: {
      submit: function($scope, data) {
        data[$scope.attribute] = $scope.dataObject.value;
      },
      setWriteValue: function($scope) {
        $scope.dataObject = {
          value: $scope.entity.props[$scope.attribute]
        };
      },
      setReadValue: function($scope) {
        $scope.readValue = $scope.entity.props[$scope.attribute];
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
      onFail: disablePreview,
      setReadValue: function($scope) {
        if ($scope.attribute == 'rawDescription') {
          $scope.readValue = $sce.trustAsHtml($scope.entity.props.description);
        } else {
          $scope.readValue = $scope.entity.props[$scope.attribute];
        }
      }
    },

    select: {
      activate: setOptions,
      startEditing: setOptions,
      submit: function($scope, data) {
        data._links = { };
        data._links[$scope.attribute] = { href: $scope.dataObject.value };
      },
      setWriteValue: function($scope) {
        $scope.dataObject = {
          value: $scope.entity.form.embedded.payload.links[$scope.attribute].href
        };
      }
    }
  };

  this.dispatchHook = function($scope, action, data) {
    var actionFunction = hooks[$scope.type][action] || hooks._fallback[action] || angular.noop;
    return actionFunction($scope, data);
  };
};
