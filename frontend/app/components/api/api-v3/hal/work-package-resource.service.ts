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

function wpResource(HalResource: typeof op.HalResource) {
  class WorkPackageResource extends HalResource {
    private form;

    getForm() {
      if (!this.form) {
        this.form = this.$links.update(this);
      }
      return this.form;
    }

    getSchema() {
      return this.getForm().then(form => {
        const schema = form.$embedded.schema;

        angular.forEach(schema, (field, name) => {
          if (this[name] && field && field.writable && field.$isHal
            && Array.isArray(field.allowedValues)) {

            this[name] = _.where(field.allowedValues, {name: this[name].name})[0];
          }
        });

        return schema;
      });
    }

    save() {
      // TODO: Do something if the lock version does not match
      // TODO: iterate only over the changed attributes
      // TODO: invalidate form after saving
      const plain = this.$plain();

      delete plain.createdAt;
      delete plain.updatedAt;

      return this.getForm().then(form => {
        var plain_payload = form.embedded.payload.data();
        var schema = form.embedded.schema;

        for (property in data) {
          if (data[property] && schema[property] && schema[property]['writable'] === true) {
            plain_payload[property] = data[property];
          }
        }
        for (property in data._links) {
          if (data._links[property] && schema[property] && schema[property]['writable'] === true) {
            plain_payload._links[property] = data._links[property];
          }
        }

        return this.$links.updateImmediately(plain).then(workPackage => {
          angular.extend(this, workPackage);
          this.form = null;
          return this;
        });
      });
    }
  }

  return WorkPackageResource;
}

angular
  .module('openproject.api')
  .factory('WorkPackageResource', wpResource);
