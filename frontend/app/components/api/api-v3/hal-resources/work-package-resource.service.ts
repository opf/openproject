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

function wpResource(HalResource:typeof op.HalResource, NotificationsService:any, $q:ng.IQService) {
  class WorkPackageResource extends HalResource {
    private form;

    getForm() {
      if (!this.form) {
        this.form = this.$links.update(this);
        this.form.catch(error => {
          NotificationsService.addError(error.data.message);
        });
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
      const plain = this.$plain();

      delete plain.createdAt;
      delete plain.updatedAt;

      var deferred = $q.defer();
      this.getForm()
        .catch(deferred.reject)
        .then(form => {
          var plainPayload = form.payload.$plain();
          var schema = form.$embedded.schema;

          angular.forEach(plain, (value, key) => {
            if (typeof(schema[key]) === 'object' && schema[key]['writable'] === true) {
              plainPayload[key] = value;
            }
          });

          angular.forEach(plainPayload._links, (_value, key) => {
            if (this[key] && typeof(schema[key]) === 'object' && schema[key]['writable'] === true) {
              var value = this[key].href === 'null' ? null : this[key].href;
              plainPayload._links[key] = {href: value};
            }
          });

          return this.$links.updateImmediately(plainPayload)
            .then(workPackage => {
              angular.extend(this, workPackage);

              deferred.resolve(this);
            }).catch((error) => {
              deferred.reject(error);
            }).finally(() => {
              this.form = null;
            });
        });

      return deferred.promise;
    }

    public get isLeaf():boolean {
      return !(this as any).children;
    }

    isParentOf(otherWorkPackage) {
      return otherWorkPackage.parent.$links.self.$link.href ===
        this.$links.self.$link.href;
    }

    public get isEditable():boolean {
      return !!this.$links.update;
    }
  }

  return WorkPackageResource;
}

angular
  .module('openproject.api')
  .factory('WorkPackageResource', wpResource);
