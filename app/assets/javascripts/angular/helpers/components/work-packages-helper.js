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

angular.module('openproject.workPackages.helpers')

.factory('WorkPackagesHelper', ['$filter', 'dateFilter', 'currencyFilter', 'CustomFieldHelper', function($filter, dateFilter, currencyFilter, CustomFieldHelper) {
  var WorkPackagesHelper = {
    getRowObjectContent: function(object, option) {
      var content;

      if(CustomFieldHelper.isCustomFieldKey(option)){
        content = WorkPackagesHelper.getRawCustomValue(object, CustomFieldHelper.getCustomFieldId(option));
      } else {
        content = object[option];
      }

      switch(typeof(content)) {
        case 'object':
          if (content === null) return '';
          return content.name || content.subject || '';
        case 'number':
          return content;
        default:
          return content || '';
      }
    },

    augmentWorkPackageWithData: function(workPackage, attributeName, isCustomValue, data) {
      if (isCustomValue && data) {
        if (workPackage.custom_values) {
          workPackage.custom_values.push(data);
        } else {
          workPackage.custom_values = [data];
        }
      } else {
        workPackage[attributeName] = data;
      }
    },

    getRawCustomValue: function(object, customFieldId) {
      if (!object.custom_values) return null;

      var values = object.custom_values.filter(function(customValue){
        return customValue && customValue.custom_field_id === customFieldId;
      });

      if (values && values.length) {
        return values[0].value;
      } else {
        return '';
      }
    },

    getFormattedCustomValue: function(object, customField) {
      if (!object.custom_values) return null;

      var values = object.custom_values.filter(function(customValue){
        return customValue && customValue.custom_field_id === customField.id;
      });

      if(values && values.length) {
        return CustomFieldHelper.formatCustomFieldValue(values[0].value, customField.field_format);
      }
    },

    getFormattedColumnData: function(object, column) {
      var value = WorkPackagesHelper.getRowObjectContent(object, column.name);

      return WorkPackagesHelper.formatValue(value, column.meta_data.data_type);
    },

    formatValue: function(value, dataType) {
      switch(dataType) {
        case 'datetime':
          return value ? dateFilter(WorkPackagesHelper.parseDateTime(value), 'medium') : '';
        case 'date':
          return value ? dateFilter(WorkPackagesHelper.parseDateTime(value), 'mediumDate') : '';
        case 'currency':
          return currencyFilter(value, 'EUR ');
        default:
          return $filter('characters')(value, 20);
      }
    },
    formatWorkPackageProperty: function(value, propertyName) {
      var mappings = {
        dueDate: 'date',
        startDate: 'date',
        createdAt: 'datetime',
        updatedAt: 'datetime'
      };

      if (propertyName === 'estimatedTime') {
        return value && value.value ? value.value + ' ' + value.units : null;
      } else {
        return this.formatValue(value, mappings[propertyName]);
      }
    },

    parseDateTime: function(value) {
      return new Date(Date.parse(value.replace(/(A|P)M$/, '')));
    }

  };

  return WorkPackagesHelper;
}]);
