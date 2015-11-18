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

angular
  .module('openproject.inplace-edit')
  .factory('inplaceEditForm', inplaceEditForm);

function inplaceEditForm($rootScope, inplaceEdit) {
  var inplaceEditForm,
      forms = {};

  function Form(resource) {
    this.resource = resource;
    this.fields = {};

    this.field = function (name) {
      this.fields[name] = this.fields[name] || new inplaceEdit.Field(this.resource, name);

      return this.fields[name];
    };

    this.updateFieldValues = function () {
      _.forOwn(this.fields, function (field) {
        if (!field.isEmbedded()) {
          field.updateValue();
        }
      });
    }
  }

  Object.defineProperty(Form.prototype, 'length', {
    get: function () {
      return Object.keys(this.fields).length;
    }
  });

  $rootScope.$on('workPackageUpdatedInEditor', function (event, updatedWorkPackage) {
    var form = inplaceEditForm.getForm(updatedWorkPackage.props.id);
    form.resource = _.extend(form.resource, updatedWorkPackage);
  });

  return inplaceEditForm = {
    getForm: function (id, resource) {
      forms[id] = forms[id] || new Form(resource);

      if (!forms[id].resource) {
        forms[id].resource = resource;
      }

      return forms[id];
    },

    deleteNewForm: function () {
      delete forms['undefined'];
    }
  };
}
