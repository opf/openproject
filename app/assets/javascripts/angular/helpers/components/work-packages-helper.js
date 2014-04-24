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

.factory('WorkPackagesHelper', ['dateFilter', 'CustomFieldHelper', function(dateFilter, CustomFieldHelper) {
  var WorkPackagesHelper = {
    getRowObjectContent: function(object, option) {
      if(CustomFieldHelper.isCustomFieldKey(option)){
        var content = WorkPackagesHelper.getRawCustomValue(object, CustomFieldHelper.getCustomFieldId(option));
      } else {
        var content = object[option];
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
          return dateFilter(WorkPackagesHelper.parseDateTime(value), 'medium');
        case 'date':
          return dateFilter(value, 'mediumDate');
        default:
          return value;
      }
    },

    parseDateTime: function(value) {
      return new Date(Date.parse(value.replace(/(A|P)M$/, '')));
    },

    projectRowsToColumn: function(rows, column) {
      return rows.map(function(row){
        return WorkPackagesHelper.getColumnValue(row.object, column);
      });
    },

    getSums: function(rows, column) {
      var values = WorkPackagesHelper.projectRowsToColumn(rows, column)
        .filter(function(value) {
          return typeof(value) === 'number';
        });

      if (values.length > 0) {
        sum = values.reduce(function(a, b) {
          return a + b;
        });
      } else {
        sum = null;
      }

      return sum;
    }

  };

  return WorkPackagesHelper;
}]);
