// -- copyright
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
// ++

import {opWorkPackagesModule} from "../../../angular-modules";

function wpSingleViewFieldService($filter,
                                  I18n,
                                  WorkPackagesHelper, 
                                  inplaceEditErrors) {

  function getSchema(workPackage) {
    return workPackage.schema;
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
      return schema['startDate'].writable && schema['dueDate'].writable;
      //return workPackage.schema.startDate.writable
      // && workPackage.schema.dueDate.writable;
    }
    if(schema[field].type === 'Date') {
      return true;
    }
    var isWritable = schema[field].writable;

    // not writable if no embedded allowed values
    if (isWritable && schema[field]._links && allowedValuesEmbedded(workPackage, field)) {
      isWritable = getEmbeddedAllowedValues(workPackage, field).length > 0;
    }

    return isWritable;
  }

  function isSpecified(workPackage, field) {
    var schema = getSchema(workPackage);
    if (field === 'date') {
      // kind of specified
      return true;
    }
    return !_.isUndefined(schema[field]);
  }

  // under special conditions fields will be shown
  // irregardless if they are empty or not
  // e.g. when an error should trigger the editing state
  // of an empty field after type change
  function isHideable(workPackage, field) {
    if (inplaceEditErrors.errors && inplaceEditErrors.errors[field]) {
      return false;
    }

    var attrVisibility = getVisibility(workPackage, field);

    var notRequired = !isRequired(workPackage, field);
    var empty = isEmpty(workPackage, field);
    var visible = attrVisibility == 'visible'; // always show
    var hidden = attrVisibility == 'hidden'; // never show
    // !hidden && !visible => show if not empty

    if (workPackage.isNew === true) {
      return notRequired && hidden;
    } else {
      return notRequired && !visible && (empty || hidden);
    }
  }

  function getVisibility(workPackage, field) {
    if (field == "date") {
      return getDateVisibility(workPackage);
    } else {
      var schema = workPackage.schema;
      var prop = schema && schema[field];

      return prop && prop.visibility;
    }
  }

  /**
   * There isn't actually a 'date' field for work packages.
   * There are two fields: 'start_date' and 'due_date'
   * Though they are displayed together in one row, as one 'field'.
   * Since the schema doesn't know any field named 'date' we
   * derive the visibility for the imaginary 'date' field from
   * the actual schema values of 'due_date' and 'start_date'.
   *
   * 'visible' > 'default' > 'hidden'
   * Meaning, for instance, that if at least one field is 'visible'
   * both will be shown. Even if the other is 'hidden'.
   *
   * Note: this is duplicated in app/views/types/_form.html.erb
   */
  function getDateVisibility(workPackage) {
    var a = getVisibility(workPackage, "startDate");
    var b = getVisibility(workPackage, "dueDate");
    var values = [a, b];

    if (_.contains(values, "visible")) {
      return "visible";
    } else if (_.contains(values, "default")) {
      return "default";
    } else if (_.contains(values, "hidden")) {
      return "hidden";
    } else {
      return undefined;
    }
  }

  function isMilestone(workPackage) {
    // TODO: this should be written as "only use the form when editing"
    // otherwise always use the simple way
    // currently we don't know the context in which this method is called
    var formAvailable = !_.isUndefined(workPackage.form);
    if (formAvailable) {
        var allowedValues = workPackage.schema.type.$embedded.allowedValues;
        var currentType = workPackage.$links.type.$link.href;

      return _.some(allowedValues, function(allowedValue) {
        return allowedValue.href === currentType &&
          allowedValue.isMilestone;
      });
    } else {
      return workPackage.type.isMilestone;
    }
  }

  function getValue(workPackage, field) {
    var payload = workPackage;

    if (field === 'date') {
      if(isMilestone(workPackage)) {
        return payload['dueDate'];
      }
      return {
        startDate: payload['startDate'],
        dueDate: payload['dueDate']
      };
    }
    if (!_.isUndefined(payload[field])) {
      return payload[field];
    }
    if (isEmbedded(payload, field)) {
      return payload.$embedded[field];
    }

    if (payload.$links[field] && payload.$links[field].$link.href !== null) {
      return payload.$links[field];
    }
    return null;
  }

  function allowedValuesEmbedded(workPackage, field) {
    var schema = getSchema(workPackage);
    return _.isArray(schema[field]._links.allowedValues);
  }

  function getEmbeddedAllowedValues(workPackage, field) {
    var options = [];
    var schema = getSchema(workPackage);
    return schema[field].$embedded.allowedValues;
  }

  function isRequired(workPackage, field) {
    var schema = getSchema(workPackage);
    if (_.isUndefined(schema[field])) {
      return false;
    }
    return schema[field].required;
  }

  function isEmbedded(workPackage, field) {
    return !_.isUndefined(workPackage.$embedded[field]);
  }

  function getLabel(workPackage, field) {
    var schema = getSchema(workPackage);
    if (field === 'date') {
      // special case
      return I18n.t('js.work_packages.properties.date');
    }
    return schema[field].name;
  }

  function isEmpty(workPackage, field) {
    if (field === 'date') {
      return (
        getValue(workPackage, 'startDate') === null &&
        getValue(workPackage, 'dueDate') === null
      );
    }
    var value = format(workPackage, field);
    if (value === null || value === '') {
      return true;
    }

    if (value.html === '') {
      return true;
    }

    if (field === 'spentTime' && workPackage[field] === 'PT0S') {
      return true;
    }

    if (value.$embedded && _.isArray(value.$embedded.elements)) {
      return value.$embedded.elements.length === 0;
    }

    return false;
  }

  function format(workPackage, field) {
    var schema = getSchema(workPackage);
    if (field === 'date') {
      if(isMilestone(workPackage)) {
        return workPackage['dueDate'];
      }
      return {
        startDate: workPackage.startDate,
        dueDate: workPackage.dueDate,
        noStartDate: I18n.t('js.label_no_start_date'),
        noEndDate: I18n.t('js.label_no_due_date')
      };
    }

    var value = workPackage[field];
    if (_.isUndefined(value)) {
      return getValue(workPackage, field, true);
    }

    if (value === null) {
      return null;
    }

    var fieldMapping = {
      dueDate: 'date',
      startDate: 'date',
      createdAt: 'datetime',
      updatedAt: 'datetime'
    }[field] || schema[field] && schema[field].type;

    switch(fieldMapping) {
      case('Duration'):
        var hours = moment.duration(value).asHours();
        var formattedHours = $filter('number')(hours, 2);
        return I18n.t('js.units.hour', { count: formattedHours });
      case('Boolean'):
        return value ? I18n.t('js.general_text_yes') : I18n.t('js.general_text_no');
      case('Date'):
        return value;
      case('Float'):
        return $filter('number')(value);
      default:
        return WorkPackagesHelper.formatValue(value, fieldMapping);
    }
  }

  return {
    isEditable: isEditable,
    isRequired: isRequired,
    isSpecified: isSpecified,
    isHideable: isHideable,
    isMilestone: isMilestone,
    isEmbedded: isEmbedded,
    getLabel: getLabel,
  };
}

opWorkPackagesModule.service('wpSingleViewField', wpSingleViewFieldService);
