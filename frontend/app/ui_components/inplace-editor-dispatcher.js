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

module.exports = function($sce, $http, $timeout, AutoCompleteHelper, TextileService, VersionService, I18n) {

  function enableAutoCompletion(element) {
    var textarea = element.find('.inplace-edit--write-value input, .inplace-edit--write-value textarea');
    AutoCompleteHelper.enableTextareaAutoCompletion(textarea);
  }

  var id = 0;
  function generateId() {
    return id++;
  }

  function disablePreview($scope) {
    $scope.isPreview = false;
  }

  function getAttribute($scope) {
    return $scope.attribute;
  }

  function getReadAttributeValue($scope) {
    return getAttributeValue($scope, $scope.entity);
  }

  function getWriteAttributeValue($scope) {
    return getAttributeValue($scope, $scope.entity.form.embedded.payload);
  }

  function getAttributeValue($scope, entity) {
    if ($scope.embedded) {
      return entity.embedded[$scope.attribute] ? entity.embedded[$scope.attribute].props.name : null;
    } else {
      return entity.props[getAttribute($scope)];
    }
  }

  function isAttributeFormattable(attribute) {
    return attribute && (attribute.format === 'textile');
  }

  function isOptionListEmbedded($scope) {
    return _.isArray($scope
      .entity.form.embedded.schema
      .props[getAttribute($scope)]._links.allowedValues);
  }

  function setOptions($scope) {
    if (isOptionListEmbedded($scope)) {
      $scope.$broadcast('focusSelect2');
    } else {
      setLinkedOptions($scope);
    }
  }

  function setEmbeddedOptions($scope) {
    $scope.options = [];
    var allowedValues = $scope
      .entity.form.embedded.schema
      .props[getAttribute($scope)]._links.allowedValues;
    if (allowedValues.length) {
      var options = _.map(allowedValues, function(item) {
        return angular.extend({}, item, { name: item.title });
      });

      if ($scope.hasEmptyOption) {
        var arrayWithEmptyOption = [{ href: null }];
        $scope.options = arrayWithEmptyOption.concat(options);
      } else {
        $scope.options = options;
      }
    } else {
      $scope.isEditing = false;
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
      var options = _.map(r.data._embedded.elements, function(item) {
        return angular.extend({}, item._links.self, { name: item.name });
      });
      if ($scope.hasEmptyOption) {
        var arrayWithEmptyOption = [{ href: null }];
        $scope.options = arrayWithEmptyOption.concat(options);
      } else {
        $scope.options = options;
      }
      $scope.isBusy = false;
      $scope.$broadcast('focusSelect2');
    });
  }

  var hooks = {
    _fallback: {
      submit: function($scope, data) {
        data[getAttribute($scope)] = $scope.dataObject.value;
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
        scope.$on('startEditing', function() {
          $timeout(function() {
            enableAutoCompletion(element);
            var textarea = element.find('.inplace-edit--write-value textarea'),
                lines = textarea.val().split('\n');
            textarea.attr('rows', lines.length + 1);
          }, 0, false);
        });
      },
      startEditing: function($scope) {
        disablePreview($scope);
      },
      setReadValue: function($scope) {
        var attribute = getReadAttributeValue($scope);
        $scope.readValue = $sce.trustAsHtml(attribute.html);
      },
      setWriteValue: function($scope) {
        var attribute = getWriteAttributeValue($scope);
        $scope.dataObject = {
          value: attribute.raw
        };
        $scope.isFormattable = isAttributeFormattable(attribute);

      },
      submit: function($scope, data) {
        data[getAttribute($scope)].raw = $scope.dataObject.value;
      },
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
            .renderWithWorkPackageContext($scope.entity.form, $scope.dataObject.value)
            .then(function(r) {
              $scope.onFinally();
              $scope.previewHtml = $sce.trustAsHtml(r.data);
          }, function(e) {
            disablePreview($scope);
            $scope.onFinally();
            $scope.onFail(e);
          });
        };
      },
      onFail: disablePreview
    },

    boolean: {
      activate: function($scope) {
        $scope.checkboxId = 'checkbox_' + generateId();
      },
      setReadValue: function($scope) {
        var attribute = getReadAttributeValue($scope);
        if (attribute === true) {
          $scope.readValue = I18n.t('js.general_text_yes');
        }
        if (attribute === false) {
          $scope.readValue = I18n.t('js.general_text_no');
        }
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
      startEditing: setOptions,
      submit: function($scope, data) {
        data._links = data._links || { };
        data._links[getAttribute($scope)] = { href: $scope.dataObject.value || null };
      },
      setReadValue: function($scope) {
        if ($scope
            .entity.form.embedded.schema
            .props[getAttribute($scope)].required === false) {
          $scope.hasEmptyOption = true;
        }
        if ($scope.isEditable && isOptionListEmbedded($scope)) {
          this._setEmbeddedOptions($scope);
        }
        if ($scope.displayStrategy === 'user' || $scope.displayStrategy === 'version') {
          $scope.readValue = $scope.entity.embedded[$scope.attribute];
          if ($scope.displayStrategy === 'version') {
            VersionService.isVersionFieldViewable($scope.entity, getAttribute($scope)).then(function(isViewable) {
              $scope.isVersionFieldViewable = isViewable;
            });
          }
        } else {
          $scope.readValue = this._getReadAttributeValue($scope);
        }

      },
      setWriteValue: function($scope) {
        var link = $scope.entity.form.embedded.payload.links[getAttribute($scope)];
        $scope.dataObject = {
          value: link ? link.href : null
        };
      }
    }
  };

  // when you need to expose inner functions like that for test
  // it's a sign that it should be in a service
  this._setEmbeddedOptions = setEmbeddedOptions;
  this._getReadAttributeValue = getReadAttributeValue;

  this.dispatchHook = function($scope, action, data) {
    var actionFunction = hooks[$scope.type][action] || hooks._fallback[action] || angular.noop;
    return actionFunction.call(this, $scope, data);
  };
};
