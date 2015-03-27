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

module.exports = function(I18n, WORK_PACKAGE_REGULAR_EDITABLE_FIELD, WorkPackagesHelper, $q, $http) {

  function isEditable(workPackage, field) {
    // no form - no editing
    if (!workPackage.form) {
      return false;
    }
    // TODO: extract to strategy if new cases arise
    if (field === 'date') {
      // nope
      return false;
      //return workPackage.schema.props.startDate.writable && workPackage.schema.props.dueDate.writable;
    }
    if (field === 'estimatedTime') {
      return false;
    }
    if(workPackage.schema.props[field].type === 'Date') {
      return false;
    }
    var isWritable = workPackage.schema.props[field].writable;

    // not writable if no embedded allowed values
    if (workPackage.form && workPackage.form.embedded.schema
        .props[field]._links && allowedValuesEmbedded(workPackage, field)) {
      if (getEmbeddedAllowedValues(workPackage, field).length === 0) {
        return false;
      }
    }
    return isWritable;
  }

  function isSpecified(workPackage, field) {
    if (field === 'date') {
      // kind of specified
      return true;
    }
    return !_.isUndefined(workPackage.schema
      .props[field]);
  }

  function getValue(workPackage, field) {
    if (!_.isUndefined(workPackage.props[field])) {
      return workPackage.props[field];
    }
    if (WorkPackageFieldService.isEmbedded(workPackage, field)) {
      return workPackage.embedded[field];
    }
    return null;
  }

  function allowedValuesEmbedded(workPackage, field) {
    return _.isArray(workPackage.form.embedded.schema
      .props[field]._links.allowedValues);
  }

  function getEmbeddedAllowedValues(workPackage, field) {
    var options = [];
    var allowedValues = workPackage.form.embedded.schema
      .props[field]._links.allowedValues;
    options = _.map(allowedValues, function(item) {
      return _.extend({}, item, { name: item.title });
    });

    if (!WorkPackageFieldService.isRequired(workPackage, field)) {
      var arrayWithEmptyOption = [{ href: null }];
      options = arrayWithEmptyOption.concat(options);
    }

    return options;
  }

  function getLinkedAllowedValues(workPackage, field) {
    var href = workPackage.form.embedded.schema
      .props[field]._links.allowedValues.href;
    return $http.get(href).then(function(r) {
      var options = [];
      options = _.map(r.data._embedded.elements, function(item) {
        return _.extend({}, item._links.self, { name: item.name });
      });
      if (!WorkPackageFieldService.isRequired(workPackage, field)) {
        var arrayWithEmptyOption = [{ href: null }];
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
    return workPackage.form.embedded.schema
      .props[field].required;
  }

  function isEmbedded(workPackage, field) {
    return !_.isUndefined(workPackage.embedded[field]);
  }

  function isSavedAsLink(workPackage, field) {
    return _.isUndefined(workPackage.form.embedded.payload.props[field]);
  }

  function getLabel(workPackage, field) {
    if (field === 'date') {
      // special case
      return I18n.t('js.work_packages.properties.date');
    }
    return workPackage.schema.props[field].name;
  }

  function isEmpty(workPackage, field) {
    if (field === 'date') {
      return getValue(workPackage, 'startDate') === null && getValue(workPackage, 'dueDate') === null;
    }
    var value = WorkPackageFieldService.getValue(workPackage, field);
    return  value === null || value === '';
  }

  function getInplaceEditStrategy(workPackage, field) {
    var fieldType = null,
        inplaceType = 'text';
    if (field === 'date') {
      fieldType = 'DateRange';
    } else if (field === 'description') {
      fieldType = 'Textile';
    } else {
      fieldType = workPackage.form.embedded.schema.props[field].type;
    }
    switch(fieldType) {
      case 'Float':
        inplaceType = 'float';
        break;
      case 'Textile':
        inplaceType = 'wiki_textarea';
        break;
      case 'Integer':
        inplaceType = 'integer';
        break;
      case 'Boolean':
        inplaceType = 'boolean';
        break;
      case 'Formattable':
        inplaceType = 'textarea';
        break;
      case 'StringObject':
      case 'Version':
      case 'User':
      case 'Status':
      case 'Priority':
      case 'Category':
        inplaceType = 'dropdown';
        break;
    }

    return inplaceType;
  }

  function getInplaceDisplayStrategy(workPackage, field) {
    var fieldType = null,
      displayStrategy = 'embedded';
    if (field === 'date') {
      fieldType = 'DateRange';
    } else if (field === 'spentTime') {
      fieldType = 'SpentTime';
    }  else {
      fieldType = workPackage.schema.props[field].type;
    }
    switch(fieldType) {
      case 'String':
      case 'Integer':
      case 'Float':
      case 'Duration':
      case 'DateRange':
      case 'Date':
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
    }

    return displayStrategy;
  }

  function format(workPackage, field) {
    if (field === 'date') {
      var displayedStartDate = WorkPackagesHelper.formatValue(workPackage.props.startDate, 'startDate') || I18n.t('js.label_no_start_date'),
        displayedEndDate   = WorkPackagesHelper.formatValue(workPackage.props.dueDate, 'dueDate') || I18n.t('js.label_no_due_date');
      return  displayedStartDate + ' - ' + displayedEndDate;
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

    if (workPackage.schema.props[field].type === 'Duration') {

      var hours = moment.duration(value).asHours();
      return I18n.t('js.units.hour', { count: hours.toFixed(2) });
    }

    if (workPackage.schema.props[field].type === 'Boolean') {
      return value ? I18n.t('js.general_text_yes') : I18n.t('js.general_text_no');
    }

    return WorkPackagesHelper.formatValue(value, mappings[field]);
  }

  var WorkPackageFieldService = {
    isEditable: isEditable,
    isRequired: isRequired,
    isSpecified: isSpecified,
    isEmpty: isEmpty,
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
