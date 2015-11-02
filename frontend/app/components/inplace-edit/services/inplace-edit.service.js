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
  .factory('inplaceEdit', inplaceEdit);

function inplaceEdit(WorkPackageFieldService) {
  var forms = {};

  function Form(resource) {
    this.resource = resource;
    this.fields = {};

    this.field = function (name) {
      this.fields[name] = this.fields[name] || new Field(this.resource, name);

      return this.fields[name];
    };
  }

  Object.defineProperty(Form.prototype, 'length', {
    get: function () {
      return Object.keys(this.fields).length;
    }
  });

  function Field(resource, name) {
    this.resource = resource;
    this.name = name;
    this.value = !_.isUndefined(this.value) ? this.value : _.cloneDeep(this.getValue());
  }

  Object.defineProperty(Field.prototype, 'text', {
    get: function() {
      return this.format();
    }
  });

  // Looks up placeholders in the localization files (e.g. js-en.yml).
  // The path is
  //  js:
  //    [name of the resource in snake case and pluralized]:
  //      placeholders:
  //        [name of the field]:
  //
  // Falls back to default if no specific placeholder is defined.
  Object.defineProperty(Field.prototype, 'placeholder', {
    get: function() {

      if (this.resource.props._type === undefined) {
        return I18n.t('js.placeholders.default');
      }

      // lodash does snakeCase in version 3.10
      // This also pluralizes the easy way by appending 's' to the end
      // which is error prone
      var resourceName = this.resource.props._type
        .replace(/([A-Z])/g, function($1){return '_' + $1.toLowerCase();})
        .replace(/^_/, '') + 's';

      var scope = 'js.' + resourceName + '.placeholders.' + this.name;

      var translation = I18n.t(scope);
      if (I18n.missingTranslation(scope) === translation) {
        return I18n.t('js.' + resourceName + '.placeholders.default');
      }
      else {
        return translation;
      }
    }
  });

  _.forOwn(WorkPackageFieldService, function (property, name) {
    Field.prototype[name] = _.isFunction(property) && function () {
      return property(this.resource, this.name);
    } || property;
  });

  return {
    form: function (id, resource) {
      forms[id] = forms[id] || new Form(resource);

      return forms[id];
    }
  };
}
inplaceEdit.$inject = ['WorkPackageFieldService'];
