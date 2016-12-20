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

module.exports = function(TimezoneService, currencyFilter, CustomFieldHelper) {

  var WorkPackagesHelper = {
    getRowObjectContent: function(object, option) {
      var content = object[option];

      switch(typeof(content)) {
        case 'object':
          if (content === null) { return ''; }
          return content.name || content.subject || content.title || content.value || '';
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

    getFormattedCustomValue: function(object, customField) {
      if (!object.custom_values) { return null; }

      var values = object.custom_values.filter(function(customValue){
        return customValue && customValue.custom_field_id === customField.id;
      });

      if(values && values.length) {
        return CustomFieldHelper.formatCustomFieldValue(values[0].value, customField.field_format);
      }
    },

    getColumnDataId: function(object, column) {
      var custom_field_id = column.name.match(/^cf_(\d+)$/);

      if (custom_field_id) {
        custom_field_id = parseInt(custom_field_id[1], 10);

        return WorkPackagesHelper.getCFColumnDataId(object, custom_field_id);
      }
      else {
        return WorkPackagesHelper.getStaticColumnDataId(object, column);
      }
    },

    getCFColumnDataId: function(object, custom_field_id) {

      var custom_value = _.find(object.custom_values, function(elem) {
        return elem && (elem.custom_field_id === custom_field_id);
      });

      if(custom_value && custom_value.value) {
        return custom_value.value.id;
      }
      else {
        return null;
      }
    },

    getStaticColumnDataId: function(object, column) {
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

    getFormattedColumnData: function(object, column) {
      var value = WorkPackagesHelper.getRowObjectContent(object, column.name);

      return WorkPackagesHelper.formatValue(value, column.meta_data.data_type);
    },

    formatValue: function(value, dataType) {
      switch(dataType ? dataType.toLowerCase() : null) {
        case 'datetime':
          return value ? TimezoneService.formattedDatetime(TimezoneService.parseDatetime(value)) : '';
        case 'currency':
          return currencyFilter(value, 'EUR ');
        case 'duration':
          return TimezoneService.formattedDuration(value);
        case('boolean'):
          return value ? I18n.t('js.general_text_yes') : I18n.t('js.general_text_no');
        case 'date':
          return value ? TimezoneService.formattedDate(TimezoneService.parseDate(value)) : '';
        default:
          return value;
      }
    }
  };

  return WorkPackagesHelper;
};
