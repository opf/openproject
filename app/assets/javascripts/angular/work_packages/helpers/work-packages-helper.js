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

module.exports =function(TimezoneService, currencyFilter, CustomFieldHelper) {
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

    getColumnDataId: function(object, column) {
      var id;

      switch (column.name) {
        case 'parent':
          id = object.parent_id;
          break;
        case 'project':
          id = object.project.identifier;
          break;
        case 'subject':
          id = object.id;
          break;
        default:
          id = (object[column.name]) ? object[column.name].id : null;
      }

      return id;
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
            dateTime = TimezoneService.formattedDate(value) + " " + TimezoneService.formattedTime(value);
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

    formatWorkPackageProperty: function(value, propertyName) {
      var mappings = {
        dueDate: 'date',
        startDate: 'date',
        createdAt: 'datetime',
        updatedAt: 'datetime'
      };

      if (propertyName === 'estimatedTime') {
        return value && value.value !== null ? value.value + ' ' + value.units : null;
      } else {
        return this.formatValue(value, mappings[propertyName]);
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

    //Note: The following methods are display helpers and so don't really belong here but are shared between
    // directives so it's probably the best place for them just now.
    getState: function(workPackage) {
      return (workPackage.props.isClosed) ? 'closed' : '';
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
