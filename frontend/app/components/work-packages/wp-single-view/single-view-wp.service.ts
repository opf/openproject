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


import {opServicesModule} from '../../../angular-modules';
import {WorkPackageDisplayFieldService} from '../../wp-display/wp-display-field/wp-display-field.service';

var $filter:ng.IFilterService;
var I18n:op.I18n;
var wpDisplayField:WorkPackageDisplayFieldService;

export class SingleViewWorkPackage {

  private fields:Object = {};

  constructor(protected workPackage:any) {
  }

  public isSingleField(field) {
    return angular.isString(field);
  };

  public canHideField(field) {
    var attrVisibility = this.getVisibility(field);
    var notRequired = !this.isRequired(field) || this.hasDefault(field);
    var empty = this.isEmpty(field);
    var visible = attrVisibility === 'visible';
    var hidden = attrVisibility === 'hidden';

    if (this.workPackage.isNew) {
      return !visible && (field === 'author' || notRequired || hidden);
    }

    return notRequired && !visible && (empty || hidden);
  }

  public getVisibility(field) {
    var schema = this.workPackage.schema;
    var prop = schema && schema[field];

    return prop && prop.visibility;
  }

  public isRequired(field) {
    var schema = this.workPackage.schema;

    if (_.isUndefined(schema[field])) {
      return false;
    }

    return schema[field].required;
  }

  public hasDefault(field) {
    var schema = this.workPackage.schema;

    if (_.isUndefined(schema[field])) {
      return false;
    }

    return schema[field].hasDefault;
  }

  public isEmpty(fieldName) {
    if (this.workPackage.schema[fieldName]) {
      this.fields[fieldName] = this.fields[fieldName] ||
                               wpDisplayField.getField(this.workPackage,
                                                       fieldName,
                                                       this.workPackage.schema[fieldName]);

      return this.fields[fieldName].isEmpty();
    }
    else {
      return true;
    }
  }

  public isEditable(field) {
    // no form - no _editing
    if (!this.workPackage.form) {
      return false;
    }
    var schema = this.workPackage.schema;
    var isWritable = schema[field].writable;

    if (isWritable && schema[field].$links && this.getLinkedAllowedValues(field)) {
      isWritable = this.getEmbeddedAllowedValues(field).length > 0;
    }

    return isWritable;
  }

  public getLinkedAllowedValues(field) {
    return _.isArray(this.workPackage.schema[field].$links.allowedValues);
  }

  public getEmbeddedAllowedValues(field) {
    return this.workPackage.schema[field].$embedded.allowedValues;
  }

  public getLabel(field) {
    if (field === 'date') {
      return I18n.t('js.work_packages.properties.date');
    }

    return this.workPackage.schema[field].name;
  }

  public isSpecified(field) {
    return !_.isUndefined(this.workPackage.schema[field]);
  }

  public hasNiceStar(field) {
    return this.isRequired(field) && this.workPackage.schema[field].writable;
  }

  public isGroupHideable(groupedFields, groupName) {
    var group:any = _.find(groupedFields, {groupName: groupName});

    return group.attributes.length === 0 || _.every(group.attributes, (field) => {
        return this.canHideField(field);
      });
  }

  public isGroupEmpty(groupedFields, groupName) {
    var group:any = _.find(groupedFields, {groupName: groupName});

    return group.attributes.length === 0;
  }

  public shouldHideGroup(hideEmptyActive, groupedFields, groupName) {
    return hideEmptyActive && this.isGroupHideable(groupedFields, groupName) ||
      !hideEmptyActive && this.isGroupEmpty(groupedFields, groupName);
  }

  public shouldHideField(field, hideEmptyFields) {
    var hidden = this.getVisibility(field) === 'hidden';

    return this.canHideField(field) && (hideEmptyFields || hidden);
  }
}

function singleViewWpService(...args) {
  [$filter, I18n, wpDisplayField] = args;
  return SingleViewWorkPackage;
}

singleViewWpService.$inject = [
  '$filter',
  'I18n',
  'wpDisplayField'
];

opServicesModule.factory('SingleViewWorkPackage', singleViewWpService);
