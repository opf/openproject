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

module.exports = function(
  I18n,
  WORK_PACKAGE_REGULAR_EDITABLE_FIELD,
  WorkPackagesHelper,
  $q,
  $http,
  HookService,
  EditableFieldsState
  ) {

  function getSchema(workPackage) {
    if (workPackage.form) {
      return workPackage.form.embedded.schema;
    } else {
      return workPackage.schema;
    }
  }

  function isEditable(workPackage, field) {
    // no form - no editing
    if (!workPackage.form) {
      return false;
    }
    var schema = getSchema(workPackage);
    // TODO: extract to strategy if new cases arise
    if (field === 'date') {
      // nope
      return schema.props['startDate'].writable && schema.props['dueDate'].writable;
      //return workPackage.schema.props.startDate.writable
      // && workPackage.schema.props.dueDate.writable;
    }
    if(schema.props[field].type === 'Date') {
      return true;
    }
    var isWritable = schema.props[field].writable;

    // not writable if no embedded allowed values
    if (schema.props[field]._links && allowedValuesEmbedded(workPackage, field)) {
      if (getEmbeddedAllowedValues(workPackage, field).length === 0) {
        return false;
      }
    }
    return isWritable;
  }

  function isSpecified(workPackage, field) {
    var schema = getSchema(workPackage);
    if (field === 'date') {
      // kind of specified
      return true;
    }
    return !_.isUndefined(schema.props[field]);
  }

  // under special conditions fields will be shown
  // irregardless if they are empty or not
  // e.g. when an error should trigger the editing state
  // of an empty field after type change
  function isHideable(workPackage, field) {
    if (EditableFieldsState.errors && EditableFieldsState.errors[field]) {
      return false;
    }
    return isEmpty(workPackage, field);
  }

  function isMilestone(workPackage) {
    // TODO: this should be written as "only use the form when editing"
    // otherwise always use the simple way
    // currently we don't know the context in which this method is called
    var formAvailable = !_.isUndefined(workPackage.form);
    if (formAvailable) {
      var embedded = workPackage.form.embedded,
        allowedValues = embedded.schema.props.type._embedded.allowedValues,
        currentType = embedded.payload.links.type.props.href;
      return _.some(allowedValues, function(allowedValue) {
        return allowedValue._links.self.href === currentType &&
          allowedValue.isMilestone;
      });
    } else {
      return workPackage.embedded.type.isMilestone;
    }
  }

  function getValue(workPackage, field) {
    if (field === 'date') {
      if(isMilestone(workPackage)) {
        return workPackage.props['dueDate'];
      }
      return {
        startDate: workPackage.props['startDate'],
        dueDate: workPackage.props['dueDate']
      };
    }
    if (!_.isUndefined(workPackage.props[field])) {
      return workPackage.props[field];
    }
    if (WorkPackageFieldService.isEmbedded(workPackage, field)) {
      return workPackage.embedded[field];
    }

    if (workPackage.links[field] && workPackage.links[field].props.href !== null) {
      return workPackage.links[field];
    }
    return null;
  }

  function allowedValuesEmbedded(workPackage, field) {
    var schema = getSchema(workPackage);
    return _.isArray(schema.props[field]._links.allowedValues);
  }

  function getEmbeddedAllowedValues(workPackage, field) {
    var options = [];
    var schema = getSchema(workPackage);
    var allowedValues = schema.props[field]._links.allowedValues;
    options = _.map(allowedValues, function(item) {
      return _.extend({}, item, { name: item.title });
    });

    if (!WorkPackageFieldService.isRequired(workPackage, field)) {
      var arrayWithEmptyOption = [{
        href: null,
        name: I18n.t('js.inplace.clear_value_label')
      }];
      options = arrayWithEmptyOption.concat(options);
    }

    return options;
  }

  function getLinkedAllowedValues(workPackage, field) {
    var schema = getSchema(workPackage);
    var href = schema.props[field]._links.allowedValues.href;
    return $http.get(href).then(function(r) {
      var options = [];
      options = _.map(r.data._embedded.elements, function(item) {
        return _.extend({}, item._links.self, { name: item.name });
      });
      if (!WorkPackageFieldService.isRequired(workPackage, field)) {
        var arrayWithEmptyOption = [{
          href: null,
          name: I18n.t('js.inplace.clear_value_label')
        }];
        options = arrayWithEmptyOption.concat(options);
      }
      return options;
    });
  }

  function getAllowedValues(workPackage, field) {
    if (allowedValuesEmbedded(workPackage, field)) {
      return $q(function(resolve) {
        resolve(getEmbeddedAllowedValues(workPackage, field));
      });
    } else {
      return getLinkedAllowedValues(workPackage, field);
    }
  }

  function isRequired(workPackage, field) {
    var schema = getSchema(workPackage);
    if (_.isUndefined(schema.props[field])) {
      return false;
    }
    return schema.props[field].required;
  }

  function isEmbedded(workPackage, field) {
    return !_.isUndefined(workPackage.embedded[field]);
  }

  function isSavedAsLink(workPackage, field) {
    return _.isUndefined(workPackage.form.embedded.payload.props[field]);
  }

  function getLabel(workPackage, field) {
    var schema = getSchema(workPackage);
    if (field === 'date') {
      // special case
      return I18n.t('js.work_packages.properties.date');
    }
    return schema.props[field].name;
  }

  function isEmpty(workPackage, field) {
    if (field === 'date') {
      return (
        getValue(workPackage, 'startDate') === null &&
        getValue(workPackage, 'dueDate') === null
      );
    }
    var value = WorkPackageFieldService.format(workPackage, field);
    if (value === null || value === '') {
      return true;
    }

    if (value.html === '') {
      return true;
    }

    // strategy pattern, guys
    if (field === 'spentTime' && WorkPackageFieldService.getValue(workPackage, field) === 'PT0S') {
      return true;
    }

    if (value.embedded && _.isArray(value.embedded.elements)) {
      return value.embedded.elements.length === 0;
    }

    return false;
  }

  function getInplaceEditStrategy(workPackage, field) {
    var schema = getSchema(workPackage);
    var fieldType = null,
        inplaceType = 'text';

    if (field === 'date') {
      if(isMilestone(workPackage)) {
        fieldType = 'Date';
      } else {
        fieldType = 'DateRange';
      }
    } else {
      fieldType = schema.props[field].type;
    }
    switch(fieldType) {
      case 'DateRange':
        inplaceType = 'daterange';
        break;
      case 'Date':
        inplaceType = 'date';
        break;
      case 'Float':
        inplaceType = 'float';
        break;
      case 'Integer':
        inplaceType = 'integer';
        break;
      case 'Boolean':
        inplaceType = 'boolean';
        break;
      case 'Formattable':
        if (workPackage.form.embedded.payload.props[field].format === 'textile') {
          inplaceType = 'wiki_textarea';
        } else {
          inplaceType = 'textarea';
        }
        break;
      case 'Duration':
        inplaceType = 'duration';
        break;
      case 'StringObject':
      case 'Version':
      case 'User':
      case 'Status':
      case 'Priority':
      case 'Category':
      case 'Type':
        inplaceType = 'dropdown';
        break;
    }

    var typeFromPluginHook = HookService.call('workPackageAttributeEditableType', {
      type: fieldType
    }).pop();

    if (typeFromPluginHook) {
      inplaceType = typeFromPluginHook;
    }
    return inplaceType;
  }

  function getInplaceDisplayStrategy(workPackage, field) {
    var schema = getSchema(workPackage);
    var fieldType = null,
      displayStrategy = 'embedded';

    if (field === 'date') {
      if(isMilestone(workPackage)) {
        fieldType = 'Date';
      } else {
        fieldType = 'DateRange';
      }
    } else if (field === 'spentTime') {
      fieldType = 'SpentTime';
    }  else {
      fieldType = schema.props[field].type;
    }
    switch(fieldType) {
      case 'String':
      case 'Integer':
      case 'Float':
      case 'Duration':
      case 'Boolean':
        displayStrategy = 'text';
        break;
      case 'SpentTime':
        displayStrategy = 'spent_time';
        break;
      case 'Formattable':
        displayStrategy = 'wiki_textarea';
        break;
      case 'Version':
        displayStrategy = 'version';
        break;
      case 'User':
        displayStrategy = 'user';
        break;
      case 'DateRange':
        displayStrategy = 'daterange';
        break;
      case 'Date':
        displayStrategy = 'date';
        break;
    }

    //workPackageOverviewAttributes
    var pluginDirectiveName = HookService.call('workPackageOverviewAttributes', {
      type: fieldType,
      field: field,
      workPackage: workPackage
    })[0];
    if (pluginDirectiveName) {
      displayStrategy = 'dynamic';
    }

    return displayStrategy;
  }

  function format(workPackage, field) {
    var schema = getSchema(workPackage);
    if (field === 'date') {
      if(isMilestone(workPackage)) {
        return workPackage.props['dueDate'];
      }
      return {
        startDate: workPackage.props.startDate,
        dueDate: workPackage.props.dueDate,
        noStartDate: I18n.t('js.label_no_start_date'),
        noEndDate: I18n.t('js.label_no_due_date')
      };
    }

    var value = workPackage.props[field];
    if (_.isUndefined(value)) {
      // might be embedded
      return WorkPackageFieldService.getValue(workPackage, field);
    }

    if (value === null) {
      return null;
    }

    var mappings = {
      dueDate: 'date',
      startDate: 'date',
      createdAt: 'datetime',
      updatedAt: 'datetime'
    };

    if (schema.props[field]) {
      if (schema.props[field].type === 'Duration') {
        var hours = moment.duration(value).asHours();
        return I18n.t('js.units.hour', { count: hours.toFixed(2) });
      }

      if (schema.props[field].type === 'Boolean') {
        return value ? I18n.t('js.general_text_yes') : I18n.t('js.general_text_no');
      }

      if (workPackage.schema.props[field].type === 'Date') {
        return value;
      }
    }

    return WorkPackagesHelper.formatValue(value, mappings[field]);
  }

  var WorkPackageFieldService = {
    getSchema: getSchema,
    isEditable: isEditable,
    isRequired: isRequired,
    isSpecified: isSpecified,
    isEmpty: isEmpty,
    isHideable: isHideable,
    isMilestone: isMilestone,
    isEmbedded: isEmbedded,
    isSavedAsLink: isSavedAsLink,
    getValue: getValue,
    getLabel: getLabel,
    getAllowedValues: getAllowedValues,
    format: format,
    getInplaceEditStrategy: getInplaceEditStrategy,
    getInplaceDisplayStrategy: getInplaceDisplayStrategy,
    defaultPlaceholder: '-'
  };

  return WorkPackageFieldService;
};
