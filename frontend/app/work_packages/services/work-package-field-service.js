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

module.exports = function(I18n, WORK_PACKAGE_REGULAR_EDITABLE_FIELD) {

  function isEditable(workPackage, field) {
    // TODO: extract to strategy if new cases arise
    if (field === 'date') {
      return workPackage.schema.props.startDate.writable && workPackage.schema.props.dueDate.writable;
    }
    return workPackage.schema.props[field].writable;
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

  function isEmbedded(workPackage, field) {
    return !_.isUndefined(workPackage.embedded[field]);
  }

  function getLabel(workPackage, field) {
    if (field === 'date') {
      // special case
      return I18n.t('js.work_packages.properties.date');
    }
    return workPackage.schema.props[field].name;
  }

  function isEmpty(workPackage, field) {
    return WorkPackageFieldService.getValue(workPackage, field) === null;
  }

  function getInplaceType(workPackage, field) {
    var fieldType = null,
        inplaceType = 'text';
    if (field === 'date') {
      fieldType = 'DateRange';
    } else {
      fieldType = workPackage.form.embedded.schema.props[field].type;
    }
    console.log(fieldType, 'fieldType');
    switch(fieldType) {
      case 'Formattable':
        inplaceType = 'wiki_textarea';
        break;
      case 'StringObject':
      case 'Version':
      case 'User':
      case 'Status':
      case 'Priority':
      case 'Category':
        inplaceType = 'select2';
        break;
    }

    return inplaceType;
  }

  function getInplaceDisplayStrategy(workPackage, field) {

  }

  var WorkPackageFieldService = {
    isEditable: isEditable,
    isEmpty: isEmpty,
    isEmbedded: isEmbedded,
    getValue: getValue,
    getLabel: getLabel,
    getInplaceType: getInplaceType,
    getInplaceDisplayStrategy: getInplaceDisplayStrategy

  };

  return WorkPackageFieldService;
}
