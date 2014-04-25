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

angular.module('openproject.services')

.service('FilterService', ['OPERATORS_AND_LABELS_BY_FILTER_TYPE', 'I18n', function(OPERATORS_AND_LABELS_BY_FILTER_TYPE, I18n) {

  var FilterService = {
    /**
     * @name getOperatorsAndTranslatedLabelsByFilterType
     * @function
     *
     * @description
     * Transforms OPERATORS_AND_LABELS_BY_FILTER_TYPE by translating all operator labels;
     * Those are stored pairwise in Arrays, e.g. ['=', 'label_equals'],
     * where 'label_equals' is translated by this service method.
     *
     * @returns {Object} Operators and translated labels by filter type
     */
    getOperatorsAndTranslatedLabelsByFilterType: function() {
      var operatorsAndTranslatedLabelsByType = {};

      angular.forEach(OPERATORS_AND_LABELS_BY_FILTER_TYPE, function(operatorsAndLabels, filterType) {
        operatorsAndTranslatedLabelsByType[filterType] = [];

        angular.forEach(operatorsAndLabels, function(operatorAndLabel) {
          operatorsAndTranslatedLabelsByType[filterType].push([operatorAndLabel[0], I18n.t('js.' + operatorAndLabel[1])]);
        });
      });

      return operatorsAndTranslatedLabelsByType;
    }
  };

  return FilterService;
}]);
