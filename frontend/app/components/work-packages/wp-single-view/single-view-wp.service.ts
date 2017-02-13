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
import {Field} from '../../wp-field/wp-field.module';

var $filter:ng.IFilterService;
var I18n:op.I18n;
var wpDisplayField:WorkPackageDisplayFieldService;

export class SingleViewWorkPackage {

  private fields:{[attr:string]: Field} = {};

  constructor(protected workPackage:any) {
  }

  public isSingleField(field:string) {
    return angular.isString(field);
  };

  public canHideField(field:string) {
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

  public getVisibility(field:string) {
    var schema = this.workPackage.schema;
    var prop = schema && schema[field];

    return prop && prop.visibility;
  }

  public isRequired(field:string) {
    var schema = this.workPackage.schema;

    if (_.isUndefined(schema[field])) {
      return false;
    }

    return schema[field].required;
  }

  public hasDefault(field:string) {
    var schema = this.workPackage.schema;

    if (_.isUndefined(schema[field])) {
      return false;
    }

    return schema[field].hasDefault;
  }

  public isEmpty(fieldName:string) {
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

  public isEditable(field:string) {
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

  public getLinkedAllowedValues(field:string) {
    return _.isArray(this.workPackage.schema[field].$links.allowedValues);
  }

  public getEmbeddedAllowedValues(field:string) {
    return this.workPackage.schema[field].$embedded.allowedValues;
  }

  public getLabel(field:string) {
    if (field === 'date') {
      return I18n.t('js.work_packages.properties.date');
    }

    return this.workPackage.schema[field].name;
  }

  public isSpecified(field:string) {
    return !_.isUndefined(this.workPackage.schema[field]);
  }

  public hasNiceStar(field:string) {
    return this.isRequired(field) && this.workPackage.schema[field].writable;
  }

  public isGroupHideable(groupedFields:any, groupName:string) {
    var group:any = _.find(groupedFields, {groupName: groupName});

    return group.attributes.length === 0 || _.every(group.attributes, (field:string) => {
        return this.canHideField(field);
      });
  }

  public isGroupEmpty(groupedFields:any, groupName:string) {
    var group:any = _.find(groupedFields, {groupName: groupName});

    return group.attributes.length === 0;
  }

  public shouldHideGroup(hideEmptyActive:boolean, groupedFields:any, groupName:string) {
    return hideEmptyActive && this.isGroupHideable(groupedFields, groupName) ||
      !hideEmptyActive && this.isGroupEmpty(groupedFields, groupName);
  }

  public shouldHideField(field:string, hideEmptyFields:boolean) {
    var hidden = this.getVisibility(field) === 'hidden';

    return this.canHideField(field) && (hideEmptyFields || hidden);
  }
}

function singleViewWpService(...args:any[]) {
  [$filter, I18n, wpDisplayField] = args;
  return SingleViewWorkPackage;
}

singleViewWpService.$inject = [
  '$filter',
  'I18n',
  'wpDisplayField'
];

opServicesModule.factory('SingleViewWorkPackage', singleViewWpService);
