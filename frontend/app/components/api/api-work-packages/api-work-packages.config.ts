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

function apiWorkPackagesConfig(RestangularProvider) {
  RestangularProvider.addElementTransformer('work_packages', workPackage => {
    const workPackage = workPackage;
    var schema:ng.IPromise;

    /**
     * Define some convenience methods for workPackage elements.
     * As the work package is halTransformed, we can use the HAL methods here, too.
     *
     * We want the added properties to not be enumerable, so Restangular's plain() method
     * returns the values of the resource only.
     */
    Object.defineProperties(workPackage, {

      /**
       * Get the update form for the current work package
       * @see {@link http://opf.github.io/apiv3-doc/#work-packages-work-package-edit-form-post}
       * @method
       * @return {ng.IPromise}
       */
      getForm: {value: () => workPackage.links.update(workPackage)},

      /**
       * Get the schema of the current work package.
       * Load the schema only once per work package.
       * @method
       * @return {ng.IPromise}
       */
      getSchema: {
        value: () => {
          schema = schema || workPackage.getForm().then(form => form.embedded.schema);
          return schema;
        }
      },

      /**
       * Save the work package
       * @method
       * @return {ng.IPromise}
       */
      save: {
        value: () => {
          var data = workPackage.data();

          //TODO: Remove non-writable properties automatically
          delete data.createdAt;
          delete data.updatedAt;

          return workPackage.patch(data);
        }
      }
    });

    return workPackage;
  });
}

angular
  .module('openproject.api')
  .config(apiWorkPackagesConfig);
