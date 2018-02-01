//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {HalResource} from '../../components/api/api-v3/hal-resources/hal-resource.service';

module.exports = function(TimezoneService:any, currencyFilter:any, CustomFieldHelper:any) {

  var WorkPackagesHelper = {
    getRowObjectContent: function(object:any, option:any) {
      var content = object[option];
      var displayContent = function(content:any) {
        return content.name || content.subject || content.title || content.value || '';
      };

      switch(typeof(content)) {
        case 'object':
          if (content === null) {
            return '';
          } else if (content instanceof Array) {
            return content.map(displayContent).join(", ");
          } else {
            return displayContent(content);
          }
        case 'number':
          return content;
        default:
          return content || '';
      }
    },

    augmentWorkPackageWithData: function(workPackage:any, attributeName:any, isCustomValue:any, data:any) {
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

    getFormattedCustomValue: function(object:any, customField:any) {
      if (!object.custom_values) { return null; }

      var values = object.custom_values.filter(function(customValue:any){
        return customValue && customValue.custom_field_id === customField.id;
      });

      if(values && values.length) {
        return CustomFieldHelper.formatCustomFieldValue(values[0].value, customField.field_format);
      }
    },

    getColumnDataId: function(object:any, column:any) {
      var custom_field_id = column.name.match(/^cf_(\d+)$/);

      if (custom_field_id) {
        custom_field_id = parseInt(custom_field_id[1], 10);

        return WorkPackagesHelper.getCFColumnDataId(object, custom_field_id);
      }
      else {
        return WorkPackagesHelper.getStaticColumnDataId(object, column);
      }
    },

    getCFColumnDataId: function(object:any, custom_field_id:any) {

      var custom_value = _.find(object.custom_values, function(elem:any) {
        return elem && (elem.custom_field_id === custom_field_id);
      });

      if(custom_value && custom_value.value) {
        return custom_value.value.id;
      }
      else {
        return null;
      }
    },

    getStaticColumnDataId: function(object:any, column:any) {
      switch (column.name) {
        case 'parent':
          return object.parent_id;
        case 'project':
          return object.project.identifier;
        case 'id':
        case 'subject':
          return object.id;
        default:
          return (object[column.name]) ? object[column.name].id : null;
      }
    },

    getFormattedColumnData: function(object:any, column:any) {
      var value = WorkPackagesHelper.getRowObjectContent(object, column.name);

      return WorkPackagesHelper.formatValue(value, column.meta_data.data_type);
    },

    formatValue: function(value:any, dataType:any) {
      switch(dataType) {
        case 'datetime':
          var dateTime;
          if (value) {
            dateTime = TimezoneService.formattedDatetime(value);
          }
          return dateTime || '';
        case 'date':
          return value ? TimezoneService.formattedDate(value) : '';
        case 'currency':
          return currencyFilter(value, 'EUR ');
        case 'Duration':
          return TimezoneService.formattedDuration(value);
        case 'DateTime':
          return TimezoneService.formattedDatetime(value);
        case('Boolean'):
          return value ? I18n.t('js.general_text_yes') : I18n.t('js.general_text_no');
        case 'Date':
          return TimezoneService.formattedDate(value);
        default:
          if (value instanceof HalResource) {
            return value.name;
          }
          return value;
      }
    },

    parseDateTime: function(value:any) {
      return new Date(Date.parse(value.replace(/(A|P)M$/, '')));
    }
  };

  return WorkPackagesHelper;
};
