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

/* jshint camelcase: false */

module.exports =function(TimezoneService, currencyFilter, CustomFieldHelper) {
  var WorkPackagesHelper = {
    getRowObjectContent: function(object, option) {
      var content;

      if(CustomFieldHelper.isCustomFieldKey(option)){
        var custom_field_id = CustomFieldHelper.getCustomFieldId(option);
        content = WorkPackagesHelper.getRawCustomValue(object, custom_field_id);
      } else {
        content = object[option];
      }

      switch(typeof(content)) {
        case 'object':
          if (content === null) { return ''; }
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
      if (!object.custom_values) { return null; }

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
        default:
          return value;
      }
    },

    parseDateTime: function(value) {
      return new Date(Date.parse(value.replace(/(A|P)M$/, '')));
    },

    getParent: function(workPackage) {
      var wpParent = workPackage.links.parent;

      return (wpParent) ? [wpParent.fetch()] : [];
    },

    getChildren: function(workPackage) {
      var children = workPackage.links.children;
      var result = [];

      if (children) {
        for (var x = 0; x < children.length; x++) {
          var child = children[x];

          result.push(child);
        }
      }

      return result;
    },

    getRelationsOfType: function(workPackage, type) {
      var relations = workPackage.embedded.relations;
      var result = [];

      if (relations) {
        for (var x = 0; x < relations.length; x++) {
          var relation = relations[x];

          if (relation.props._type == type) {
            result.push(relation);
          }
        }
      }

      return result;
    },

    //Note: The following methods are display helpers and so don't really
    //belong here but are shared between directives so it's probably the best
    //place for them just now.
    getState: function(workPackage) {
      return (workPackage.embedded.status.props.isClosed) ? 'closed' : '';
    },

    getFullIdentifier: function(workPackage) {
      var id = '#' + workPackage.props.id;
      if (workPackage.props.type) {
        id += ' ' + workPackage.props.type + ':';
      }
      id += ' ' + workPackage.props.subject;

      return id;
    },

    collapseStateIcon: function(collapsed) {
      var iconClass = 'icon-arrow-right5-';
      if (collapsed) {
        iconClass += '3';
      } else {
        iconClass += '2';
      }

      return iconClass;
    }
  };

  return WorkPackagesHelper;
};
